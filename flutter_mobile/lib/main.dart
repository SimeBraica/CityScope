import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobile/config/theme/app_themes.dart';
import 'package:flutter_mobile/features/auth/presentation/bloc/loggedInUser/remote/remote_logged_user_bloc.dart';
import 'package:flutter_mobile/features/auth/presentation/bloc/loggedInUser/remote/remote_logged_user_event.dart';
import 'package:flutter_mobile/features/auth/presentation/pages/login/login.dart';
import 'package:flutter_mobile/injection_container.dart';

Future<void> main() async {
  await initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RemoteLoggedUserBloc>(
      create:
          (context) =>
              sl()..add(
                const LoginUser(email: "test@test.com", password: "test"),
              ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme(),
        home: const Login(),
      ),
    );
  }
}
