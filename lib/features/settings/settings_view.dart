// lib/features/settings/settings_view.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_providers.dart';
import 'notification_service.dart';
import 'delete_account_service.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _notifLoading = true;
  bool _notifEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotif();
  }

  Future<void> _loadNotif() async {
    final enabled = await NotificationService.instance.isEnabled();
    if (!mounted) return;
    setState(() {
      _notifEnabled = enabled;
      _notifLoading = false;
    });
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1) Edit display name
    final currentName = user.displayName ?? '';
    final controller = TextEditingController(text: currentName);

    final resultName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final newName = resultName?.trim();
    if (newName != null && newName.isNotEmpty) {
      await user.updateDisplayName(newName);
    }

    // 2) Pick profile picture (optional)
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 75,
    );

    if (picked != null) {
      final file = File(picked.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();
      await user.updatePhotoURL(url);
    }

    await user.reload();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // --------- Profile-related actions ----------
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit profile'),
            subtitle: const Text('Change your name and profile picture'),
            onTap: _editProfile,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            onTap: () async {
              const url = 'https://your-privacy-policy-url-here';
              final uri = Uri.parse(url);

              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open privacy policy'),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of service'),
            onTap: () async {
              const url = 'https://your-terms-of-service-url-here';
              final uri = Uri.parse(url);

              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open terms of service'),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'GCSE Study App',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Your Name',
                children: const [
                  SizedBox(height: 8),
                  Text(
                    'A GCSE revision app using spaced-repetition flashcards, '
                    'XP and streaks to keep you consistent.',
                  ),
                ],
              );
            },
          ),

          const Divider(),

          // --------- Daily reminders ----------
          SwitchListTile(
            title: const Text('Daily reminder notifications'),
            value: _notifEnabled,
            onChanged: _notifLoading
                ? null
                : (value) async {
                    setState(() => _notifEnabled = value);
                    if (value) {
                      await NotificationService.instance
                          .scheduleDailyReminder(hour: 19, minute: 0);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Daily reminders enabled')),
                      );
                    } else {
                      await NotificationService.instance.cancelDailyReminder();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Daily reminders disabled')),
                      );
                    }
                  },
          ),

          const Divider(),

          // --------- Sign out ----------
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await auth.signOut();
            },
          ),

          // --------- Delete account ----------
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete account'),
            subtitle: const Text('Removes your profile and study data'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete account?'),
                  content: const Text(
                    'This will permanently remove your profile and all study data.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              try {
                await DeleteAccountService().deleteUserData(user.uid);
                await user.delete();
                await auth.signOut();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted')),
                );
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: ${e.message}')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
