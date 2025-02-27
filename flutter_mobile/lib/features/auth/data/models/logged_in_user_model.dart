import 'package:flutter_mobile/features/auth/domain/entities/logged_in_user_entity.dart';
import 'package:floor/floor.dart';

@Entity(primaryKeys: ['id'])
class LoggedInUserModel extends LoggedInUserEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id; // ovako je jer ne očekujem da ćemo slat Id s backenda, ako budemo onda samo ubacit dole required super.id

  const LoggedInUserModel({
    this.id,
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
      id: json['id'],
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
      'id': id,
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
