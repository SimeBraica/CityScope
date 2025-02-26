import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobile/features/auth/presentation/bloc/loggedInUser/remote/remote_logged_user_bloc.dart';
import 'package:flutter_mobile/features/auth/presentation/bloc/loggedInUser/remote/remote_logged_user_state.dart';

class Login extends StatelessWidget {
  const Login({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppbar(), body: _buildBody());
  }

  _buildAppbar() {
    return AppBar(
      title: const Text('Login', style: TextStyle(color: Colors.black)),
    );
  }

  _buildBody() {
    return BlocBuilder<RemoteLoggedUserBloc, RemoteLoggedUserState>(
      builder: (_, state) {
        if (state is RemoteLoggedUserLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state is RemoteLoggedUserError) {
          return const Center(child: Icon(Icons.refresh));
        }
        if (state is RemoteLoggedUserDone) {
          return const Center(child: Text('Logged in'));
        }

        return const SizedBox();
      },
    );
  }
}
