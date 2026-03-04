import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'remote_session_controller.dart';
import 'dto.dart';

final remoteUsersProvider = FutureProvider.autoDispose<List<UserDto>>((
  ref,
) async {
  final sess = ref.watch(remoteSessionProvider).valueOrNull;
  if (sess == null) return [];
  return sess.api.getUsers();
});

class RemoteHomePage extends ConsumerWidget {
  const RemoteHomePage({super.key});

  Future<void> _addUserDialog(BuildContext context, WidgetRef ref) async {
    final u = TextEditingController();
    final p = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create user (remote)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: u,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: p,
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

    final sess = ref.read(remoteSessionProvider).valueOrNull;
    if (sess == null) return;

    await sess.api.createUser(u.text.trim(), p.text);

    // refresh
    ref.invalidate(remoteUsersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(remoteUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote DB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link_off),
            onPressed: () {
              ref.read(remoteSessionProvider.notifier).disconnect();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addUserDialog(context, ref),
        child: const Icon(Icons.person_add),
      ),
      body: users.when(
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
    );
  }
}
