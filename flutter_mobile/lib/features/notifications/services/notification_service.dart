import 'dart:io';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_mobile/main.dart'; 

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final StreamController<Map<String, dynamic>> onNotificationSubject = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get onNotification => onNotificationSubject.stream;

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Kliknuta notifikacija: ${response.payload}');
        
        if (response.payload != null) {
          onNotificationSubject.add({
            'type': 'click',
            'payload': response.payload,
          });
        }
      },
    );

    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    
    if (Platform.isAndroid) {
      try {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (e) {
        print('Greška pri traženju dozvole: $e');
      }
    }
    
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'geo_notifications',
            'Geo Notifications',
            description: 'Location-based notifications',
            importance: Importance.max,
          ));
    }
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Primljena poruka u prednjem planu: ${message.notification?.title}');
      
      if (message.notification != null) {
        showNotification(
          title: message.notification?.title ?? 'CityScope',
          body: message.notification?.body ?? '',
          payload: message.data['placeId'],
        );
      }
    });
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    showInAppNotification(title: title, body: body, payload: payload);
    
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'geo_notifications',
      'Geo Notifications',
      channelDescription: 'Location-based notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      print('Notifikacija uspješno poslana: $title - $body');
    } catch (e) {
      print('Greška pri slanju notifikacije: $e');
    }
  }
  
  void showInAppNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    onNotificationSubject.add({
      'type': 'notification',
      'title': title,
      'body': body,
      'payload': payload,
    });
    print('In-app notifikacija dodana u stream: $title - $body');
  }
  
  void dispose() {
    onNotificationSubject.close();
  }
} 