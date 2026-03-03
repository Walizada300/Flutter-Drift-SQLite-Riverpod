import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../db/db_paths.dart';
import 'db_item.dart';
import 'db_meta_store.dart';
import 'db_meta.dart';

final dbListControllerProvider =
    StateNotifierProvider<DbListController, AsyncValue<List<DbItem>>>(
      (ref) => DbListController()..load(),
    );

class DbListController extends StateNotifier<AsyncValue<List<DbItem>>> {
  DbListController() : super(const AsyncValue.loading());

  final _store = DbMetaStore();

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final files = await DbPaths.listDbFiles();

      final items = <DbItem>[];
      for (final f in files) {
        final path = f.path;
        final fileName = DbPaths.fileNameFromPath(path);

        final meta = await _store.read(path, fallbackName: fileName);

        items.add(
          DbItem(
            path: path,
            fileName: fileName,
            displayName: meta?.displayName ?? fileName,
            pinned: meta?.pinned ?? false,
          ),
        );
      }

      // pinned بالا، بعدش بر اساس displayName
      items.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });

      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> togglePin(DbItem item) async {
    final meta = DbMeta(displayName: item.displayName, pinned: !item.pinned);
    await _store.write(item.path, meta);
    await load();
  }

  Future<void> rename(DbItem item, String newName) async {
    final meta = DbMeta(displayName: newName.trim(), pinned: item.pinned);
    await _store.write(item.path, meta);
    await load();
  }

  Future<void> deleteMeta(String path) async {
    await _store.delete(path);
  }
}
