import 'package:floor/floor.dart';
import 'package:flutter_mobile/features/auth/data/data_sources/local/DAO/logged_in_user_dao.dart';
import 'package:flutter_mobile/features/auth/data/models/logged_in_user_model.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'dart:async';

part 'app_database.g.dart';

@Database(version: 1, entities: [LoggedInUserModel])
abstract class AppDatabase extends FloorDatabase {
  LoggedInUserDao get loggedInUserDao;
}
