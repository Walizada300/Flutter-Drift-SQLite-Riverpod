import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/db_factory.dart';
import '../../db/db_paths.dart';
import '../auth/auth_controller.dart';
import '../db_session/db_session_controller.dart';
import '../home/home_page.dart';
import 'db_list_controller.dart';
import 'package:file_picker/file_picker.dart';

class DbListPage extends ConsumerWidget {
  const DbListPage({super.key});

  Future<void> _createDbDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create new database'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Database name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Initial username'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Initial password'),
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

    final name = nameCtrl.text.trim();
    final u = userCtrl.text.trim();
    final p = passCtrl.text;

    if (name.isEmpty || u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    try {
      final path = await DbPaths.dbPathForName(name);
      await DbFactory.createNewDatabase(
        path: path,
        initialUsername: u,
        initialPassword: p,
      );
      await ref.read(dbListControllerProvider.notifier).load();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<bool> _loginDialog(BuildContext context) async {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Login'),
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
            child: const Text('Login'),
          ),
        ],
      ),
    );

    if (ok != true) return false;

    final username = userCtrl.text.trim();
    final password = passCtrl.text;

    return await context
        .readProviderContainer()
        .read(authControllerProvider.notifier)
        .login(username, password);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbs = ref.watch(dbListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Databases')),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _createDbDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create database'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAndOpenDatabase(context, ref),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open database'),
                  ),
                ),
              ],
            ),
          ),
          dbs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              print('Error: $e');
              return Center(child: Text('Error: $e'));
            },
            data: (list) {
              if (list.isEmpty) {
                return const Center(
                  child: Text('No databases yet. Tap + to create one.'),
                );
              }

              return Expanded(
                child: ListView.separated(
                  itemCount: list.length,
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final item = list[i];
                    return Card(
                      elevation: 0,
                      color: item.pinned
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: item.pinned
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.25)
                              : Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.35),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        title: Text(
                          item.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: Icon(
                          item.pinned ? Icons.push_pin : Icons.storage,
                        ),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Options',
                          onSelected: (value) async {
                            if (value == 'pin') {
                              await ref
                                  .read(dbListControllerProvider.notifier)
                                  .togglePin(item);
                              return;
                            }

                            if (value == 'rename') {
                              final newName = await _renameDialog(
                                context,
                                item.displayName,
                              );
                              if (newName != null) {
                                await ref
                                    .read(dbListControllerProvider.notifier)
                                    .rename(item, newName);
                              }
                              return;
                            }

                            if (value == "open") {
                              try {
                                await DbPaths.openContainingFolder(item.path);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }

                            if (value == 'delete') {
                              final sure = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete database'),
                                  content: Text(
                                    'Delete "${item.displayName}"?\nThis will remove the .db file permanently.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (sure == true) {
                                final sess = ref
                                    .read(dbSessionControllerProvider)
                                    .valueOrNull;
                                if (sess?.dbPath == item.path) {
                                  await ref
                                      .read(
                                        dbSessionControllerProvider.notifier,
                                      )
                                      .disconnect();
                                }

                                await DbPaths.deleteDbFile(item.path);
                                await ref
                                    .read(dbListControllerProvider.notifier)
                                    .deleteMeta(item.path);
                                await ref
                                    .read(dbListControllerProvider.notifier)
                                    .load();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Database deleted'),
                                    ),
                                  );
                                }
                              }
                              return;
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'pin',
                              child: Row(
                                children: [
                                  Icon(
                                    item.pinned
                                        ? Icons.push_pin_outlined
                                        : Icons.push_pin,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(item.pinned ? 'Unpin' : 'Pin'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'open',
                              child: Row(
                                children: [
                                  Icon(Icons.folder_open),
                                  const SizedBox(width: 10),
                                  Text('Open folder'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined),
                                  SizedBox(width: 10),
                                  Text('Rename'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline),
                                  SizedBox(width: 10),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await ref
                              .read(dbSessionControllerProvider.notifier)
                              .connect(item.path);

                          final loggedIn = await _loginDialog(context);
                          if (!loggedIn) {
                            await ref
                                .read(dbSessionControllerProvider.notifier)
                                .disconnect();
                            return;
                          }

                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _renameDialog(BuildContext context, String current) async {
    final ctrl = TextEditingController(text: current);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename database'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return null;
    final v = ctrl.text.trim();
    if (v.isEmpty) return null;
    return v;
  }

  Future<void> _pickAndOpenDatabase(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select a database (.db)',
        type: FileType.custom,
        allowedExtensions: ['db'],
        withData: false,
      );

      final picked = result?.files.single.path;
      if (picked == null) return;

      // کپی داخل پوشه اپ
      final importedPath = await DbPaths.importDbFile(picked);

      // رفرش لیست تا بیاید
      await ref.read(dbListControllerProvider.notifier).load();

      // اتصال + لاگین
      await ref
          .read(dbSessionControllerProvider.notifier)
          .connect(importedPath);

      final loggedIn = await _loginDialog(context);
      if (!loggedIn) {
        await ref.read(dbSessionControllerProvider.notifier).disconnect();
        return;
      }

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (context.mounted) {
        print('Error: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

extension _CtxRead on BuildContext {
  ProviderContainer readProviderContainer() {
    return ProviderScope.containerOf(this);
  }
}
