import 'package:floor/floor.dart';
import 'package:flutter_mobile/features/auth/data/models/logged_in_user_model.dart';

@dao
abstract class LoggedInUserDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLoggedInUser(LoggedInUserModel user);

  @delete
  Future<void> deleteLoggedInUser(LoggedInUserModel user);

  @Query('SELECT * FROM LoggedInUserModel')
  Future<LoggedInUserModel?> getLoggedInUser();
}
