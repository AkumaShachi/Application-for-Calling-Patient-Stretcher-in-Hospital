import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? get id => _prefs?.getString('id');
  static String? get fname => _prefs?.getString('fname_U');
  static String? get lname => _prefs?.getString('lname_U');
  static String? get phone => _prefs?.getString('phone_U');
  static String? get email => _prefs?.getString('email_U');
  static String? get profileImageUrl =>
      _prefs?.getString('profile_image'); // เพิ่มตรงนี้

  static Future<void> setUser(
    String id,
    String fname,
    String lname,
    String phone,
    String email,
    String profileImageUrl, // เพิ่มตรงนี้
  ) async {
    await _prefs?.setString('id', id);
    await _prefs?.setString('fname_U', fname);
    await _prefs?.setString('lname_U', lname);
    await _prefs?.setString('phone_U', phone);
    await _prefs?.setString('email_U', email);
    await _prefs?.setString('profile_image', profileImageUrl); // เพิ่มตรงนี้
  }
}
