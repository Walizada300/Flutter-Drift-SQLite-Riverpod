import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DbPaths {
  static const folderName = 'multi_dbs';
  static const ext = '.db';

  static Future<Directory> _rootDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(dir.path, folderName));
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  static Future<List<FileSystemEntity>> listDbFiles() async {
    final root = await _rootDir();
    final items = root
        .listSync()
        .where((e) => e is File && p.extension(e.path) == ext)
        .toList();
    items.sort((a, b) => a.path.compareTo(b.path));
    return items;
  }

  static Future<String> dbPathForName(String name) async {
    final root = await _rootDir();
    final safe = name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return p.join(root.path, '$safe$ext');
  }

  static String fileNameFromPath(String path) =>
      p.basenameWithoutExtension(path);

  static Future<void> deleteDbFile(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }

  /// باز کردن فولدر حاوی فایل دیتابیس در Finder (macOS)
  static Future<void> openContainingFolder(String dbFilePath) async {
    final dir = Directory(p.dirname(dbFilePath));

    if (!await dir.exists()) return;

    if (Platform.isMacOS) {
      await Process.run('open', [dir.path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [dir.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [dir.path]);
    } else {
      // موبایل: معمولاً امکان باز کردن فولدر سیستم‌فایل به شکل Finder-like نداریم
      throw UnsupportedError('Open folder is not supported on this platform');
    }
  }

  /// Import: فایل انتخاب‌شده را داخل پوشه اپ کپی می‌کند و مسیر جدید را برمی‌گرداند
  static Future<String> importDbFile(String pickedPath) async {
    final src = File(pickedPath);
    if (!await src.exists()) {
      throw Exception('Selected file not found');
    }

    if (p.extension(src.path).toLowerCase() != ext) {
      throw Exception('Please select a .db file');
    }

    final root = await _rootDir();
    final baseName = p
        .basenameWithoutExtension(src.path)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

    // اگر اسم تکراری بود _1 _2 ...
    var destPath = p.join(root.path, '$baseName$ext');
    var i = 1;
    while (await File(destPath).exists()) {
      destPath = p.join(root.path, '${baseName}_$i$ext');
      i++;
    }

    await src.copy(destPath);
    return destPath;
  }
}
