import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../db/app_database.dart';
import '../../db/db_factory.dart';

class DbSessionState {
  final String? dbPath;
  final AppDatabase? db;

  const DbSessionState({required this.dbPath, required this.db});

  static const empty = DbSessionState(dbPath: null, db: null);
}

final dbSessionControllerProvider =
    StateNotifierProvider<DbSessionController, AsyncValue<DbSessionState>>(
      (ref) => DbSessionController(),
    );

class DbSessionController extends StateNotifier<AsyncValue<DbSessionState>> {
  DbSessionController() : super(const AsyncValue.data(DbSessionState.empty));

  Future<void> connect(String path) async {
    state = const AsyncValue.loading();
    try {
      final db = await DbFactory.open(path);
      state = AsyncValue.data(DbSessionState(dbPath: path, db: db));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> disconnect() async {
    final current = state.valueOrNull;
    final db = current?.db;
    if (db != null) {
      await db.close();
    }
    state = const AsyncValue.data(DbSessionState.empty);
  }
}
