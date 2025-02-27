import 'package:equatable/equatable.dart';
import 'package:flutter_mobile/features/auth/domain/entities/logged_in_user_entity.dart';

abstract class LocalLoggedUserState extends Equatable {
  final LoggedInUserEntity? loggedInUser;
  const LocalLoggedUserState({this.loggedInUser});

  @override
  List<Object?> get props => [loggedInUser!];
}

class LocalLoggedUserLoading extends LocalLoggedUserState {
  const LocalLoggedUserLoading();
}

class LocalLoggedUserDone extends LocalLoggedUserState {
  const LocalLoggedUserDone({required LoggedInUserEntity loggedInUser})
    : super(loggedInUser: loggedInUser);
}
