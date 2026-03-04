import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import '../db/app_database.dart';
import '../security/hash.dart';

class LocalServer {
  HttpServer? _server;

  bool get isRunning => _server != null;

  int? get port => _server?.port;

  Future<void> start({
    required AppDatabase db,
    String host = '0.0.0.0',
    int port = 8080,
  }) async {
    if (_server != null) return;

    final router = Router();

    // یک token خیلی ساده برای MVP
    // (برای محصول واقعی بهتره JWT/expiry/refresh داشته باشی)
    final tokens = <String, String>{}; // token -> username

    router.get('/ping', (Request req) {
      return Response.ok(jsonEncode({'ok': true}), headers: _jsonHeaders());
    });

    router.post('/login', (Request req) async {
      final body = await req.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final username = (data['username'] ?? '').toString().trim();
      final password = (data['password'] ?? '').toString();

      if (username.isEmpty || password.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'error': 'username/password required'}),
          headers: _jsonHeaders(),
        );
      }

      final u = await db.findUserByUsername(username);
      if (u == null) {
        return Response(
          401,
          body: jsonEncode({'error': 'invalid credentials'}),
          headers: _jsonHeaders(),
        );
      }

      if (u.passwordHash != hashPassword(password)) {
        return Response(
          401,
          body: jsonEncode({'error': 'invalid credentials'}),
          headers: _jsonHeaders(),
        );
      }

      final token = _randomToken();
      tokens[token] = username;

      return Response.ok(
        jsonEncode({'token': token, 'username': username}),
        headers: _jsonHeaders(),
      );
    });

    // auth middleware خیلی ساده
    Future<Response?> _auth(Request req) async {
      final auth = req.headers['authorization'] ?? '';
      if (!auth.startsWith('Bearer ')) {
        return Response(
          401,
          body: jsonEncode({'error': 'missing token'}),
          headers: _jsonHeaders(),
        );
      }
      final token = auth.substring('Bearer '.length).trim();
      if (!tokens.containsKey(token)) {
        return Response(
          401,
          body: jsonEncode({'error': 'invalid token'}),
          headers: _jsonHeaders(),
        );
      }
      return null;
    }

    router.get('/users', (Request req) async {
      final deny = await _auth(req);
      if (deny != null) return deny;

      final list = await db.select(db.users).get();
      final out = list
          .map(
            (u) => {
              'id': u.id,
              'username': u.username,
              'createdAt': u.createdAt.toIso8601String(),
            },
          )
          .toList();

      return Response.ok(jsonEncode(out), headers: _jsonHeaders());
    });

    router.post('/users', (Request req) async {
      final deny = await _auth(req);
      if (deny != null) return deny;

      final body = await req.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final username = (data['username'] ?? '').toString().trim();
      final password = (data['password'] ?? '').toString();

      if (username.isEmpty || password.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'error': 'username/password required'}),
          headers: _jsonHeaders(),
        );
      }

      try {
        await db.createUser(
          username: username,
          passwordHash: hashPassword(password),
        );
        return Response.ok(jsonEncode({'ok': true}), headers: _jsonHeaders());
      } catch (e) {
        return Response(
          409,
          body: jsonEncode({'error': e.toString()}),
          headers: _jsonHeaders(),
        );
      }
    });

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsHeaders())
        .addHandler(router);

    _server = await serve(handler, host, port);
    stdout.writeln('LocalServer running on http://$host:${_server!.port}');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Map<String, String> _jsonHeaders() => {
    'content-type': 'application/json; charset=utf-8',
  };

  String _randomToken() {
    // MVP token (برای واقعی بهتره crypto secure)
    final now = DateTime.now().microsecondsSinceEpoch;
    final pid = pidHash;
    return base64Url.encode(utf8.encode('$now:$pid:${now * 17}'));
  }

  int get pidHash => pid ^ 0x5A5A;
}
