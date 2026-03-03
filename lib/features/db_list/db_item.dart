class DbItem {
  final String path;
  final String fileName; // اسم فایل
  final String displayName; // اسم قابل نمایش (rename)
  final bool pinned;

  DbItem({
    required this.path,
    required this.fileName,
    required this.displayName,
    required this.pinned,
  });

  DbItem copyWith({String? displayName, bool? pinned}) => DbItem(
    path: path,
    fileName: fileName,
    displayName: displayName ?? this.displayName,
    pinned: pinned ?? this.pinned,
  );
}
