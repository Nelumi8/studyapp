import 'package:shared_preferences/shared_preferences.dart';

class ProfilePrefs {
  static const _keyDisplayName = 'display_name';

  static Future<String?> loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDisplayName);
  }

  static Future<void> saveDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, name);
  }
}
