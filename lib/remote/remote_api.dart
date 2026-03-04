import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dto.dart';

class RemoteApi {
  final String baseUrl; // مثل: http://192.168.1.10:8080
  String? token;

  RemoteApi(this.baseUrl);

  Future<void> ping() async {
    final r = await http.get(Uri.parse('$baseUrl/ping'));
    if (r.statusCode != 200) throw Exception('Ping failed: ${r.body}');
  }

  Future<bool> login(String username, String password) async {
    final r = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (r.statusCode != 200) return false;

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    token = data['token'] as String?;
    return token != null;
  }

  Future<List<UserDto>> getUsers() async {
    final t = token;
    if (t == null) throw Exception('Not logged in');

    final r = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {'authorization': 'Bearer $t'},
    );

    if (r.statusCode != 200) throw Exception('Users failed: ${r.body}');
    final list = (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
    return list.map(UserDto.fromJson).toList();
  }

  Future<void> createUser(String username, String password) async {
    final t = token;
    if (t == null) throw Exception('Not logged in');

    final r = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {
        'authorization': 'Bearer $t',
        'content-type': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (r.statusCode != 200) throw Exception('Create failed: ${r.body}');
  }
}
