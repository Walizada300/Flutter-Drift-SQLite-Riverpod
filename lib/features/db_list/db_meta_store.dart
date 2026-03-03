import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_meta.dart';

class DbMetaStore {
  static const _prefix = 'db_meta:';

  String _key(String path) => '$_prefix$path';

  Future<DbMeta?> read(String path, {required String fallbackName}) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key(path));
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return DbMeta.fromJson(json, fallback: fallbackName);
  }

  Future<void> write(String path, DbMeta meta) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key(path), jsonEncode(meta.toJson()));
  }

  Future<void> delete(String path) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key(path));
  }
}
