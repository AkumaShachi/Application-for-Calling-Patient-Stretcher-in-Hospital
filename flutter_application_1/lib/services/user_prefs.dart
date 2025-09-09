import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? get id => _prefs?.getString('id');
  static String? get fname => _prefs?.getString('fname_U');
  static String? get lname => _prefs?.getString('lname_U');

  static Future<void> setUser(String id, String fname, String lname) async {
    await _prefs?.setString('id', id);
    await _prefs?.setString('fname_U', fname);
    await _prefs?.setString('lname_U', lname);
  }
}
