import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobile/core/resources/data_state.dart';
import 'package:flutter_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_mobile/features/auth/presentation/bloc/loggedInUser/remote/remote_logged_user_event.dart';
import 'package:flutter_mobile/features/auth/presentation/bloc/loggedInUser/remote/remote_logged_user_state.dart';

class RemoteLoggedUserBloc
    extends Bloc<RemoteLoggedUserEvent, RemoteLoggedUserState> {
  final LoginUserUseCase _loginUserUseCase;

  RemoteLoggedUserBloc(this._loginUserUseCase)
    : super(const RemoteLoggedUserLoading()) {
    on<LoginUser>(onLogin);
  }

  void onLogin(LoginUser event, Emitter<RemoteLoggedUserState> emit) async {
    final dataState = await _loginUserUseCase(
      params: LoginUserParams(email: event.email, password: event.password),
    );

    if (dataState is DataSuccess && dataState.data != null) {
      emit(RemoteLoggedUserDone(loggedUser: dataState.data!));
    }

    if (dataState is DataFailed) {
      emit(RemoteLoggedUserError(error: dataState.error!));
    }
  }
}
