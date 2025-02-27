import 'package:flutter_mobile/core/resources/data_state.dart';
import 'package:flutter_mobile/features/auth/domain/entities/logged_in_user_entity.dart';

abstract class IAuthRepository {
  // API metode
  Future<DataState<LoggedInUserEntity>> login(String email, String password);
  Future<DataState<String>> register(String email, String password);
  Future<DataState<String>> logout();

  // Local db metode
  // ovo je samo primjer, logično za prijavu mora biti online
  Future<LoggedInUserEntity?> getLoggedInUser();
}
