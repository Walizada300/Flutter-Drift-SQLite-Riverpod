import 'dart:io';
import 'package:drift/native.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app_database.dart';
import '../security/hash.dart';

class DbFactory {
  static Future<AppDatabase> open(String path) async {
    // روی موبایل بهتر است sqlite3_flutter_libs فعال باشد
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();

    final file = File(path);
    final executor = NativeDatabase.createInBackground(file);
    return AppDatabase(executor);
  }

  /// ساخت دیتابیس جدید + ساخت جدول‌ها + درج یوزر اولیه
  static Future<void> createNewDatabase({
    required String path,
    required String initialUsername,
    required String initialPassword,
  }) async {
    final file = File(path);
    if (await file.exists()) {
      throw Exception('Database already exists');
    }

    // Drift با اولین اتصال، schema را ایجاد می‌کند
    final db = await open(path);

    try {
      final ph = hashPassword(initialPassword);
      await db.createUser(username: initialUsername, passwordHash: ph);
    } finally {
      await db.close();
    }
  }

  static Future<bool> authenticate({
    required AppDatabase db,
    required String username,
    required String password,
  }) async {
    final u = await db.findUserByUsername(username);
    if (u == null) return false;
    return u.passwordHash == hashPassword(password);
  }
}
