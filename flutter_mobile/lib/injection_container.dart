import 'package:dio/dio.dart';
import 'package:flutter_mobile/features/auth/data/data_sources/remote/auth_api_service.dart';
import 'package:flutter_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_mobile/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:flutter_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_mobile/features/auth/presentation/bloc/loggedInUser/remote/remote_logged_user_bloc.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

// ovdje idu sve zavisnosti koje se koriste u aplikaciji
// factory -> nova instanca svaki put (koliko kužim kao transient)
// singleton -> jedna instanca za cijeli život aplikacije

Future<void> initializeDependencies() async {
  // Dio
  sl.registerSingleton<Dio>(Dio());

  // Services
  sl.registerSingleton<AuthApiService>(AuthApiService(sl()));

  // Repositories
  sl.registerSingleton<IAuthRepository>(AuthRepository(sl()));

  // UseCases
  sl.registerSingleton<LoginUserUseCase>(LoginUserUseCase(sl()));

  // Blocs
  sl.registerFactory<RemoteLoggedUserBloc>(() => RemoteLoggedUserBloc(sl()));
}
