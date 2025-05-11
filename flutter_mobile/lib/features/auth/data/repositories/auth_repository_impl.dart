import 'package:flutter_mobile/features/location/services/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
import 'package:flutter_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_mobile/core/error/failures.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final LocationService _locationService = LocationService();
  
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;
  
  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) {
        return Left(ServerFailure('Login failed, please try again.'));
      }
      
      _locationService.startLocationTracking(
        languageCode: Intl.getCurrentLocale(),
      );
      
      return Right(user);
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please check your credentials and try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      }
      return Left(ServerFailure(message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred. Please try again later.'));
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      _locationService.stopLocationTracking();
      
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error logging out: $e');
    }
  }
} 