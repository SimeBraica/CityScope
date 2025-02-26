import 'package:dio/dio.dart';
import 'package:flutter_mobile/features/auth/data/models/logged_in_user_model.dart';
import 'package:retrofit/retrofit.dart';
import 'package:flutter_mobile/core/constants/constants.dart';

part 'auth_api_service.g.dart';

@RestApi(baseUrl: baseApiUrl)
abstract class AuthApiService {
  factory AuthApiService(Dio dio) = _AuthApiService;

  @POST('$authApiEndpoint/login')
  Future<HttpResponse<LoggedInUserModel>> login({
    @Field('email') required String email,
    @Field('password') required String password,
  });

  @POST('$authApiEndpoint/register')
  Future<HttpResponse<String>> register({
    @Field('email') required String email,
    @Field('password') required String password,
  });

  @POST('$authApiEndpoint/logout')
  Future<HttpResponse<String>> logout();
}
