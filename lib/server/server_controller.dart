import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/db_session/db_session_controller.dart';
import 'local_server.dart';

final localServerProvider = Provider<LocalServer>((ref) => LocalServer());

final serverControllerProvider =
    StateNotifierProvider<ServerController, AsyncValue<bool>>(
      (ref) => ServerController(ref),
    );

class ServerController extends StateNotifier<AsyncValue<bool>> {
  final Ref ref;
  ServerController(this.ref) : super(const AsyncValue.data(false));

  Future<void> startServer({int port = 8080}) async {
    state = const AsyncValue.loading();
    try {
      final sess = ref.read(dbSessionControllerProvider).valueOrNull;
      final db = sess?.db;
      if (db == null) throw Exception('No local DB connected');

      final server = ref.read(localServerProvider);
      await server.start(db: db, port: port);

      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> stopServer() async {
    state = const AsyncValue.loading();
    try {
      final server = ref.read(localServerProvider);
      await server.stop();
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
