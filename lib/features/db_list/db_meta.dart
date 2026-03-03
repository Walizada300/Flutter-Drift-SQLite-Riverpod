class DbMeta {
  final String displayName;
  final bool pinned;

  const DbMeta({required this.displayName, required this.pinned});

  DbMeta copyWith({String? displayName, bool? pinned}) => DbMeta(
    displayName: displayName ?? this.displayName,
    pinned: pinned ?? this.pinned,
  );

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'pinned': pinned,
  };

  static DbMeta fromJson(
    Map<String, dynamic> json, {
    required String fallback,
  }) {
    return DbMeta(
      displayName: (json['displayName'] as String?)?.trim().isNotEmpty == true
          ? (json['displayName'] as String)
          : fallback,
      pinned: json['pinned'] == true,
    );
  }
}
