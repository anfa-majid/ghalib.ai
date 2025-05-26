import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Cache {
  static Future<void> savePoems(String key, List<Map<String, dynamic>> poems) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(poems);
    await prefs.setString(key, encoded);
  }

  static Future<List<Map<String, dynamic>>> loadPoems(String key) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString(key);
  if (jsonString == null) return [];

  final List<dynamic> decoded = jsonDecode(jsonString);
  return decoded.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
}

}
