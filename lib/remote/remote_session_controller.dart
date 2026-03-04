import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'remote_api.dart';

class RemoteSession {
  final String baseUrl;
  final RemoteApi api;

  RemoteSession(this.baseUrl) : api = RemoteApi(baseUrl);
}

final remoteSessionProvider =
    StateNotifierProvider<RemoteSessionController, AsyncValue<RemoteSession?>>(
      (ref) => RemoteSessionController(),
    );

class RemoteSessionController
    extends StateNotifier<AsyncValue<RemoteSession?>> {
  RemoteSessionController() : super(const AsyncValue.data(null));

  Future<void> connect(String ip, {int port = 8080}) async {
    state = const AsyncValue.loading();
    try {
      final baseUrl = 'http://$ip:$port';
      final sess = RemoteSession(baseUrl);
      await sess.api.ping();
      state = AsyncValue.data(sess);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void disconnect() {
    state = const AsyncValue.data(null);
  }
}
