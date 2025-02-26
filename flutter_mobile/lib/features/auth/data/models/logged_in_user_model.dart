import 'package:flutter_mobile/features/auth/domain/entities/logged_in_user_entity.dart';

class LoggedInUserModel extends LoggedInUserEntity {
  LoggedInUserModel({
    required super.email,
    required super.username,
    required super.latitude,
    required super.longitude,
    required super.userRoleId,
    required super.cityId,
    required super.token,
  });

  factory LoggedInUserModel.fromJson(Map<String, dynamic> json) {
    return LoggedInUserModel(
      email: json['email'],
      username: json['username'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      userRoleId: json['userRoleId'],
      cityId: json['cityId'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'latitude': latitude,
      'longitude': longitude,
      'userRoleId': userRoleId,
      'cityId': cityId,
      'token': token,
    };
  }
}
