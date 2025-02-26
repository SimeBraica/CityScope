import 'package:equatable/equatable.dart';

class LoggedInUserEntity extends Equatable {
  final String email;
  final String username;
  final double latitude;
  final double longitude;
  final int userRoleId;
  final int cityId;
  final String token;

  const LoggedInUserEntity({
    required this.email,
    required this.username,
    required this.latitude,
    required this.longitude,
    required this.userRoleId,
    required this.cityId,
    required this.token,
  });

  @override
  List<Object?> get props => [
    email,
    username,
    latitude,
    longitude,
    userRoleId,
    cityId,
    token,
  ];
}
