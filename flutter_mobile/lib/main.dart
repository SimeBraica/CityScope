import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_mobile/features/auth/presentation/pages/login/login.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show File, Platform;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_mobile/core/env_config.dart';
import 'package:flutter_mobile/features/notifications/services/notification_service.dart';
import 'package:flutter_mobile/features/notifications/widgets/in_app_notification.dart';
import 'package:flutter_mobile/features/location/services/location_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'l10n/l10n.dart';
import 'core/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  print('Pozadinska poruka primljena: ${message.notification?.title}');
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Održava splash screen dok se sve ne inicijalizira
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await EnvConfig.init();
  await Firebase.initializeApp();
  
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  
  await NotificationService().init();
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Uklanja splash screen nakon inicijalizacije
  FlutterNativeSplash.remove();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  Locale? _locale = const Locale('hr');
  final LocationService _locationService = LocationService();

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }
  
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }
  
  Future<void> _setupNotifications() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Poruka u prednjem planu primljena: ${message.notification?.title}');
      
      if (message.notification != null) {
        NotificationService().showNotification(
          title: message.notification!.title ?? 'CityScope',
          body: message.notification!.body ?? '',
        );
      }
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Aplikacija otvorena kroz notifikaciju: ${message.notification?.title}');
    });
    
    _locationService.startLocationTracking(
      languageCode: _locale?.languageCode ?? 'hr',
    );
  }

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      setLocale: setLocale,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: "CityScope",
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          if (_locale != null) return _locale!;
          if (locale == null) return const Locale('hr');
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
          return const Locale('hr');
        },
        home: InAppNotificationWrapper(
          child: Login(),
        ),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: _analytics),
        ],
        builder: (context, child) {
          return InAppNotificationWrapper(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
