// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  LoggedInUserDao? _loggedInUserDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `LoggedInUserModel` (`id` INTEGER, `email` TEXT NOT NULL, `username` TEXT NOT NULL, `latitude` REAL NOT NULL, `longitude` REAL NOT NULL, `userRoleId` INTEGER NOT NULL, `cityId` INTEGER NOT NULL, `token` TEXT NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  LoggedInUserDao get loggedInUserDao {
    return _loggedInUserDaoInstance ??=
        _$LoggedInUserDao(database, changeListener);
  }
}

class _$LoggedInUserDao extends LoggedInUserDao {
  _$LoggedInUserDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _loggedInUserModelInsertionAdapter = InsertionAdapter(
            database,
            'LoggedInUserModel',
            (LoggedInUserModel item) => <String, Object?>{
                  'id': item.id,
                  'email': item.email,
                  'username': item.username,
                  'latitude': item.latitude,
                  'longitude': item.longitude,
                  'userRoleId': item.userRoleId,
                  'cityId': item.cityId,
                  'token': item.token
                }),
        _loggedInUserModelDeletionAdapter = DeletionAdapter(
            database,
            'LoggedInUserModel',
            ['id'],
            (LoggedInUserModel item) => <String, Object?>{
                  'id': item.id,
                  'email': item.email,
                  'username': item.username,
                  'latitude': item.latitude,
                  'longitude': item.longitude,
                  'userRoleId': item.userRoleId,
                  'cityId': item.cityId,
                  'token': item.token
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<LoggedInUserModel> _loggedInUserModelInsertionAdapter;

  final DeletionAdapter<LoggedInUserModel> _loggedInUserModelDeletionAdapter;

  @override
  Future<LoggedInUserModel?> getLoggedInUser() async {
    return _queryAdapter.query('SELECT * FROM LoggedInUserModel',
        mapper: (Map<String, Object?> row) => LoggedInUserModel(
            id: row['id'] as int?,
            email: row['email'] as String,
            username: row['username'] as String,
            latitude: row['latitude'] as double,
            longitude: row['longitude'] as double,
            userRoleId: row['userRoleId'] as int,
            cityId: row['cityId'] as int,
            token: row['token'] as String));
  }

  @override
  Future<void> insertLoggedInUser(LoggedInUserModel user) async {
    await _loggedInUserModelInsertionAdapter.insert(
        user, OnConflictStrategy.replace);
  }

  @override
  Future<void> deleteLoggedInUser(LoggedInUserModel user) async {
    await _loggedInUserModelDeletionAdapter.delete(user);
  }
}
