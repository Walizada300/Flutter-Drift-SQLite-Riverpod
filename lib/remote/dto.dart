class UserDto {
  final int id;
  final String username;
  final String createdAt;

  UserDto({required this.id, required this.username, required this.createdAt});

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: json['id'] as int,
    username: json['username'] as String,
    createdAt: json['createdAt'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'createdAt': createdAt,
  };
}
