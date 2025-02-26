abstract class RemoteLoggedUserEvent {
  const RemoteLoggedUserEvent();
}

class LoginUser extends RemoteLoggedUserEvent {
  final String email;
  final String password;

  const LoginUser({required this.email, required this.password});
}
