import 'package:flutter_mobile/core/resources/data_state.dart';
import 'package:flutter_mobile/core/usecase/usecase.dart';
import 'package:flutter_mobile/features/auth/domain/entities/logged_in_user_entity.dart';
import 'package:flutter_mobile/features/auth/domain/repositories/i_auth_repository.dart';

class LoginUserParams {
  final String email;
  final String password;

  const LoginUserParams({required this.email, required this.password});
}

class LoginUserUseCase
    implements UseCase<DataState<LoggedInUserEntity>, LoginUserParams> {
  final IAuthRepository _authRepository;
  LoginUserUseCase(this._authRepository);

  @override
  Future<DataState<LoggedInUserEntity>> call({LoginUserParams? params}) {
    if (params == null) {
      throw ArgumentError('LoginUserParams cannot be null');
    }
    return _authRepository.login(params.email, params.password);
  }
}
