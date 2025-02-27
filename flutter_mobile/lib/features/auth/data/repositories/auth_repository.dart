import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_mobile/core/resources/data_state.dart';
import 'package:flutter_mobile/features/auth/data/data_sources/local/app_database.dart';
import 'package:flutter_mobile/features/auth/data/data_sources/remote/auth_api_service.dart';
import 'package:flutter_mobile/features/auth/data/models/logged_in_user_model.dart';
import 'package:flutter_mobile/features/auth/domain/repositories/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final AuthApiService _authApiService;
  final AppDatabase _appDatabase;
  AuthRepository(this._authApiService, this._appDatabase);

  @override
  Future<DataState<LoggedInUserModel>> login(
    String email,
    String password,
  ) async {
    try {
      final httpResponse = await _authApiService.login(
        email: email,
        password: password,
      );

      if (httpResponse.response.statusCode == HttpStatus.ok) {
        return DataSuccess(httpResponse.data);
      }

      return DataFailed(
        DioException(
          error: httpResponse.response.statusMessage,
          response: httpResponse.response,
          type: DioExceptionType.badResponse,
          requestOptions: httpResponse.response.requestOptions,
        ),
      );
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<String>> logout() async {
    try {
      final httpResponse = await _authApiService.logout();

      if (httpResponse.response.statusCode == HttpStatus.ok) {
        return DataSuccess(httpResponse.data);
      }

      return DataFailed(
        DioException(
          error: httpResponse.response.statusMessage,
          response: httpResponse.response,
          type: DioExceptionType.badResponse,
          requestOptions: httpResponse.response.requestOptions,
        ),
      );
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<String>> register(String email, String password) async {
    try {
      final httpResponse = await _authApiService.register(
        email: email,
        password: password,
      );

      if (httpResponse.response.statusCode == HttpStatus.ok) {
        return DataSuccess(httpResponse.data);
      }

      return DataFailed(
        DioException(
          error: httpResponse.response.statusMessage,
          response: httpResponse.response,
          type: DioExceptionType.badResponse,
          requestOptions: httpResponse.response.requestOptions,
        ),
      );
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  // samo za primjer
  @override
  Future<LoggedInUserModel?> getLoggedInUser() async {
    return _appDatabase.loggedInUserDao.getLoggedInUser();
  }
}
