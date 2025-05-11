import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool notificationsEnabled = true;
  bool geoEnabled = false;
  TimeOfDay from = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay to = const TimeOfDay(hour: 20, minute: 0);
  bool isLoading = true;
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          
          setState(() {
            notificationsEnabled = data['notificationsEnabled'] ?? true;
            geoEnabled = data['geoEnabled'] ?? false;
            
            if (data['notificationTime'] != null) {
              final timeData = data['notificationTime'];
              if (timeData['from'] != null) {
                final fromParts = timeData['from'].toString().split(':');
                if (fromParts.length == 2) {
                  from = TimeOfDay(
                    hour: int.parse(fromParts[0]),
                    minute: int.parse(fromParts[1]),
                  );
                }
              }
              
              if (timeData['to'] != null) {
                final toParts = timeData['to'].toString().split(':');
                if (toParts.length == 2) {
                  to = TimeOfDay(
                    hour: int.parse(toParts[0]),
                    minute: int.parse(toParts[1]),
                  );
                }
              }
            }
          });
        }
      }
      
      if (!kIsWeb) {
        await _initFCM();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        isLoading = false; 
      });
    }
  }

  Future<void> _initFCM() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken;
        try {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          print('APNS Token: $apnsToken');
        } catch (apnsError) {
          print('Error getting APNS token: $apnsError');
        }
      }
      
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        setState(() {
          notificationsEnabled = true;
        });
        
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
          print('FCM Token: $fcmToken');
          
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null && fcmToken != null) {
            await FirebaseFirestore.instance.collection('users').doc(userId).set({
              'fcmToken': fcmToken,
              'platform': Platform.isIOS ? 'ios' : 'android',
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
          
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId != null) {
              FirebaseFirestore.instance.collection('users').doc(userId).set({
                'fcmToken': newToken,
                'lastTokenUpdate': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          });
        } catch (tokenError) {
          print('Error getting FCM token: $tokenError');
        }
      } else {
        setState(() {
          notificationsEnabled = false;
          geoEnabled = false; 
        });
      }
    } catch (e) {
      print('Error initializing FCM: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickTimeRange() async {
    final pickedFrom = await showTimePicker(
      context: context,
      initialTime: from,
      helpText: AppLocalizations.of(context)!.selectFromTime,
    );
    
    if (pickedFrom != null) {
      setState(() {
        from = pickedFrom;
      });
      
      final pickedTo = await showTimePicker(
        context: context,
        initialTime: to,
        helpText: AppLocalizations.of(context)!.selectToTime,
      );
      
      if (pickedTo != null) {
        setState(() {
          to = pickedTo;
        });
        
        _saveSettings();
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'notificationsEnabled': notificationsEnabled,
        'geoEnabled': geoEnabled,
        'notificationTime': {
          'from': '${from.hour}:${from.minute}',
          'to': '${to.hour}:${to.minute}',
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        setState(() {
          notificationsEnabled = true;
        });
      } else {
        setState(() {
          notificationsEnabled = false;
          geoEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission denied')),
        );
        return;
      }
    } else {
      setState(() {
        notificationsEnabled = false;
        geoEnabled = false;
      });
    }
    
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.notifications ?? 'Notifications', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF368564),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notifications ?? 'Notifications', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF368564),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _settingRow(
              loc.enableNotifications ?? 'Enable notifications',
              notificationsEnabled,
              (v) => _toggleNotifications(v),
              activeColor: Colors.orange,
            ),
            const SizedBox(height: 16),
            _settingRow(
              loc.notificationTime ?? 'Notification time period',
              true,
              null,
              child: GestureDetector(
                onTap: notificationsEnabled ? _pickTimeRange : null,
                child: _timeBox('${from.format(context)} - ${to.format(context)}'),
              ),
              enabled: notificationsEnabled,
            ),
            const SizedBox(height: 16),
            _settingRow(
              loc.geoNotifications ?? 'Location-based notifications',
              geoEnabled,
              notificationsEnabled
                  ? (v) {
                      setState(() {
                        geoEnabled = v;
                      });
                      _saveSettings();
                    }
                  : null,
              activeColor: Colors.orange,
              enabled: notificationsEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingRow(
    String label,
    bool value,
    ValueChanged<bool>? onChanged, {
    Widget? child,
    Color activeColor = Colors.grey,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54))),
          if (child != null) child,
          if (onChanged != null)
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: activeColor,
            ),
        ],
      ),
    );
  }

  Widget _timeBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: notificationsEnabled ? Colors.grey.shade300 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: notificationsEnabled ? Colors.black54 : Colors.black38,
        ),
      ),
    );
  }
}