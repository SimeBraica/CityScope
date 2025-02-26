import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_mobile/features/auth/domain/entities/logged_in_user_entity.dart';

abstract class RemoteLoggedUserState extends Equatable {
  final LoggedInUserEntity? loggedUser;
  final DioException? error;

  const RemoteLoggedUserState({this.loggedUser, this.error});

  @override
  List<Object?> get props => [loggedUser!, error!];
}

class RemoteLoggedUserLoading extends RemoteLoggedUserState {
  const RemoteLoggedUserLoading();
}

class RemoteLoggedUserDone extends RemoteLoggedUserState {
  const RemoteLoggedUserDone({required LoggedInUserEntity loggedUser})
    : super(loggedUser: loggedUser);
}

class RemoteLoggedUserError extends RemoteLoggedUserState {
  const RemoteLoggedUserError({required DioException error})
    : super(error: error);
}
