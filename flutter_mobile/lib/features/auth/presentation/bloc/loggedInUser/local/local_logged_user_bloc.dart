import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobile/features/auth/domain/usecases/get_saved_logged_in_user.dart';
import 'package:flutter_mobile/features/auth/presentation/bloc/loggedInUser/local/local_logged_user_event.dart';
import 'package:flutter_mobile/features/auth/presentation/bloc/loggedInUser/local/local_logged_user_state.dart';

class LocalLoggedUserBloc
    extends Bloc<LocalLoggedUserEvent, LocalLoggedUserState> {
  final GetSavedLoggedInUserUseCase _getSavedLoggedInUserUseCase;

  LocalLoggedUserBloc(this._getSavedLoggedInUserUseCase)
    : super(const LocalLoggedUserLoading()) {
    on<GetSavedLoggedUser>(onGetSavedLoggedInUser);
  }

  void onGetSavedLoggedInUser(
    GetSavedLoggedUser event,
    Emitter<LocalLoggedUserState> emit,
  ) async {
    final user = await _getSavedLoggedInUserUseCase();
    emit(LocalLoggedUserDone(loggedInUser: user!));
  }
}
