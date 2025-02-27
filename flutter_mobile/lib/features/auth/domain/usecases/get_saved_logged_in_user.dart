import 'package:flutter_mobile/core/usecase/usecase.dart';
import 'package:flutter_mobile/features/auth/domain/entities/logged_in_user_entity.dart';
import 'package:flutter_mobile/features/auth/domain/repositories/i_auth_repository.dart';

class GetSavedLoggedInUserUseCase
    implements UseCase<LoggedInUserEntity?, void> {
  final IAuthRepository _authRepository;
  GetSavedLoggedInUserUseCase(this._authRepository);

  @override
  Future<LoggedInUserEntity?> call({void params}) async {
    return await _authRepository.getLoggedInUser();
  }
}
