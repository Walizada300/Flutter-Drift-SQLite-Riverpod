import 'package:drift/drift.dart';

part 'app_database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get username => text().withLength(min: 3, max: 40)();
  TextColumn get passwordHash => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  List<Set<Column>> get uniqueKeys => [
    {username},
  ];
}

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  Future<int> createUser({
    required String username,
    required String passwordHash,
  }) {
    return into(users).insert(
      UsersCompanion.insert(username: username, passwordHash: passwordHash),
    );
  }

  Future<User?> findUserByUsername(String username) {
    return (select(
      users,
    )..where((t) => t.username.equals(username))).getSingleOrNull();
  }

  Stream<List<User>> watchUsers() => select(users).watch();
}
