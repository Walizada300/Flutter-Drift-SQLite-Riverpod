import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/app_database.dart';
import '../../security/hash.dart';
import '../auth/auth_controller.dart';
import '../db_session/db_session_controller.dart';

final usersStreamProvider = StreamProvider.autoDispose<List<User>>((ref) {
  final sess = ref.watch(dbSessionControllerProvider).valueOrNull;
  final db = sess?.db;
  if (db == null) return const Stream.empty();
  return db.watchUsers();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _addUserDialog(BuildContext context, WidgetRef ref) async {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create user'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final username = userCtrl.text.trim();
    final password = passCtrl.text;
    if (username.isEmpty || password.isEmpty) return;

    final sess = ref.read(dbSessionControllerProvider).valueOrNull;
    final db = sess?.db;
    if (db == null) return;

    try {
      await db.createUser(
        username: username,
        passwordHash: hashPassword(password),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final users = ref.watch(usersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
              ref.read(authControllerProvider.notifier).logout();
              await ref.read(dbSessionControllerProvider.notifier).disconnect();
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addUserDialog(context, ref),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: auth.when(
              loading: () => const Text('Auth: loading...'),
              error: (e, _) => Text('Auth error: $e'),
              data: (a) => Text('Logged in as: ${a.username ?? '-'}'),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: users.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                if (list.isEmpty) return const Center(child: Text('No users.'));
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final u = list[i];
                    return ListTile(
                      title: Text(u.username),
                      subtitle: Text('id=${u.id}  createdAt=${u.createdAt}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
