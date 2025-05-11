import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_mobile/features/search/services/search_service.dart';
import 'package:flutter_mobile/features/notifications/services/notification_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SearchService _searchService = SearchService();
  final NotificationService _notificationService = NotificationService();
  
  Timer? _locationTimer;
  final Map<String, DateTime> _notifiedLocations = {};
  
  final _notificationCooldown = const Duration(minutes: 10);
  final _searchRadius = 0.1;
  
  Future<bool> isNotificationEnabled() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return false;
      
      final data = doc.data()!;
      final notificationsEnabled = data['notificationsEnabled'] ?? true;
      final geoEnabled = data['geoEnabled'] ?? true;
      
      if (!notificationsEnabled || !geoEnabled) return false;
      
      final timeData = data['notificationTime'];
      if (timeData == null) return true;
      
      final now = DateTime.now();
      final currentHour = now.hour;
      final currentMinute = now.minute;
      
      int fromHour = 8;
      int fromMinute = 0;
      int toHour = 20;
      int toMinute = 0;
      
      if (timeData['from'] != null) {
        final fromParts = timeData['from'].toString().split(':');
        if (fromParts.length == 2) {
          fromHour = int.parse(fromParts[0]);
          fromMinute = int.parse(fromParts[1]);
        }
      }
      
      if (timeData['to'] != null) {
        final toParts = timeData['to'].toString().split(':');
        if (toParts.length == 2) {
          toHour = int.parse(toParts[0]);
          toMinute = int.parse(toParts[1]);
        }
      }
      
      final fromTime = fromHour * 60 + fromMinute;
      final toTime = toHour * 60 + toMinute;
      final currentTime = currentHour * 60 + currentMinute;
      
      return currentTime >= fromTime && currentTime <= toTime;
    } catch (e) {
      print('Greška pri provjeri statusa notifikacija: $e');
      return true;
    }
  }
  
  Future<void> startLocationTracking({required String languageCode}) async {
    stopLocationTracking();
    
    final locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        return;
      }
    }
    
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        _checkCurrentLocation(languageCode: languageCode);
      } catch (e) {
        print('Greška u periodičkoj provjeri lokacije: $e');
      }
    });
    
    _checkCurrentLocation(languageCode: languageCode);
  }
  
  void stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }
  
  Future<void> _checkCurrentLocation({required String languageCode}) async {
    try {
      print('Provjera trenutne lokacije...');
      
      final notificationsEnabled = await isNotificationEnabled();
      if (!notificationsEnabled) {
        print('Notifikacije su onemogućene u postavkama');
        return;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      print('Dobivena stvarna lokacija: ${position.latitude}, ${position.longitude}');
      final userLocation = LatLng(position.latitude, position.longitude);
      
      final nearby = await _searchService.searchPlaces(
        userLocation: userLocation,
        maxDistance: _searchRadius,
        maxPrice: 1000,
        categories: {'attractions', 'culture'},
        userInterests: {},
        subcategories: null,
      );
      
      if (nearby.isEmpty) {
        print('Nema lokacija u blizini');
        return;
      }
      
      print('Pronađeno ${nearby.length} lokacija u blizini');
      
      nearby.sort((a, b) => 
        (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity)
      );
      
      final nearestPlace = nearby.first;
      
      print('Najbliža lokacija: ${nearestPlace.name} (${nearestPlace.distance} km)');
      
      final now = DateTime.now();
      if (_notifiedLocations.containsKey(nearestPlace.id)) {
        final lastNotified = _notifiedLocations[nearestPlace.id]!;
        if (now.difference(lastNotified) < _notificationCooldown) {
          print('Prerano za novu notifikaciju za ovu lokaciju');
          return;
        }
      }
      
      if (_notifiedLocations.isNotEmpty) {
        final lastNotified = _notifiedLocations.values.reduce(
          (a, b) => a.isAfter(b) ? a : b
        );
        if (now.difference(lastNotified) < _notificationCooldown) {
          print('Prerano za novu notifikaciju općenito');
          return;
        }
      }
      
      await _sendNotification(nearestPlace.name, nearestPlace.id, languageCode);
      
      _notifiedLocations[nearestPlace.id] = now;
      
      print('Poslana notifikacija za lokaciju: ${nearestPlace.name}');
    } catch (e) {
      print('Greška pri provjeri lokacije: $e');
    }
  }
  
  Future<void> _sendNotification(String placeName, String placeId, String languageCode) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'placeId': placeId,
        'placeName': placeName,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
        'type': 'geo',
      });
      
      final title = 'CityScope';
      final body = languageCode == 'hr' 
        ? 'Nalazite se u blizini lokacije: $placeName' 
        : 'You are near the location: $placeName';
      
      await _notificationService.showNotification(
        title: title, 
        body: body,
        payload: placeId,
      );
      
      print('Lokalna notifikacija poslana za: $placeName');
    } catch (e) {
      print('Greška pri slanju notifikacije: $e');
    }
  }
} 