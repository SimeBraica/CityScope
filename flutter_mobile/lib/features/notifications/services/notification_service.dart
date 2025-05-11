import 'dart:io';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_mobile/main.dart'; // Import za navigatorKey

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Kontroler za stream notifikacija u aplikaciji
  final StreamController<Map<String, dynamic>> onNotificationSubject = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream koji klijenti mogu slušati za notifikacije
  Stream<Map<String, dynamic>> get onNotification => onNotificationSubject.stream;

  NotificationService._internal();

  Future<void> init() async {
    // Za Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Za iOS - bez deprecated onDidReceiveLocalNotification parametra
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Inicijaliziraj postavke
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Postavi callback za notifikaciju odabira
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Ovdje možete obraditi kad korisnik klikne na notifikaciju
        print('Kliknuta notifikacija: ${response.payload}');
        
        if (response.payload != null) {
          onNotificationSubject.add({
            'type': 'click',
            'payload': response.payload,
          });
        }
      },
    );

    // Zatražimo dozvole za notifikacije na iOS-u
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
    
    // Za Android 13 i novije potrebno je zatražiti dozvolu (koristimo ispravan API)
    if (Platform.isAndroid) {
      try {
        // requestPermission je zamijenjen s requestNotificationsPermission u novijim verzijama
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (e) {
        print('Greška pri traženju dozvole: $e');
      }
    }
    
    // Kreiraj kanale za notifikacije na Androidu
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
    
    // Postavi handler za Firebase poruke u prednjem planu
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
    // Prvo pokušaj prikazati kao in-app notifikaciju
    showInAppNotification(title: title, body: body, payload: payload);
    
    // Generiraj jedinstveni ID za notifikaciju
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    // Pošalji i kao standardnu notifikaciju (za slučaj da je aplikacija u pozadini)
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
  
  // Metoda koja prikazuje notifikaciju unutar aplikacije kao SnackBar ili drugi UI element
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