import 'package:equatable/equatable.dart';
import 'package:flutter_mobile/features/auth/domain/entities/logged_in_user_entity.dart';

abstract class LocalLoggedUserEvent extends Equatable {
  final LoggedInUserEntity? loggedInUser;
  const LocalLoggedUserEvent({this.loggedInUser});

  @override
  List<Object?> get props => [loggedInUser!];
}

class GetSavedLoggedUser extends LocalLoggedUserEvent {
  const GetSavedLoggedUser();
}
