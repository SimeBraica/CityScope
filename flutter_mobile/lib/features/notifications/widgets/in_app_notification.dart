import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobile/features/notifications/services/notification_service.dart';
import 'package:flutter_mobile/main.dart';

class InAppNotificationWrapper extends StatefulWidget {
  final Widget child;

  const InAppNotificationWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<InAppNotificationWrapper> createState() => _InAppNotificationWrapperState();
}

class _InAppNotificationWrapperState extends State<InAppNotificationWrapper> with WidgetsBindingObserver {
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;
  final _notificationService = NotificationService();
  StreamSubscription? _subscription;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
        _setupNotificationListener();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isReady && mounted) {
      _setupNotificationListener();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isReady) {
      _setupNotificationListener();
    }
  }
  
  void _setupNotificationListener() {
    _subscription?.cancel();
    
    _subscription = _notificationService.onNotification.listen((notification) {
      print('NotificationWrapper primio notifikaciju: ${notification['title']}');
      if (notification['type'] == 'notification') {
        _showInAppNotification(
          title: notification['title'],
          body: notification['body'],
          payload: notification['payload'],
        );
      }
    });
    
    print('Listener za notifikacije postavljen');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _dismissTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showInAppNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    if (!mounted) {
      print('Context nije dostupan (mounted = false), korištenje globalnog navigatorKey');
      if (navigatorKey.currentContext == null) {
        print('Ni globalni context nije dostupan, odustajemo od prikaza notifikacije');
        return;
      }
    }
    
    final BuildContext contextToUse = mounted && context != null
        ? context 
        : navigatorKey.currentContext!;
    
    final OverlayState? overlayState = Overlay.maybeOf(contextToUse);
    if (overlayState == null) {
      print('Overlay nije dostupan u kontekstu, ne mogu prikazati notifikaciju');
      return;
    }
    
    _dismissTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(contextToUse).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: _InAppNotification(
            title: title,
            body: body,
            payload: payload,
            onDismiss: () {
              _dismissTimer?.cancel();
              _overlayEntry?.remove();
              _overlayEntry = null;
            },
          ),
        ),
      ),
    );
    
    try {
      overlayState.insert(_overlayEntry!);
      print('Overlay notifikacija umetnuta u UI: $title');
    } catch (e) {
      print('Greška pri umetanju overlay notifikacije: $e');
    }
    
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (_overlayEntry != null) {
        try {
          _overlayEntry?.remove();
          _overlayEntry = null;
        } catch (e) {
          print('Greška pri uklanjanju overlay notifikacije: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _InAppNotification extends StatelessWidget {
  final String title;
  final String body;
  final String? payload;
  final VoidCallback onDismiss;

  const _InAppNotification({
    Key? key,
    required this.title,
    required this.body,
    this.payload,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onDismiss();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF368564),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.place,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onDismiss,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 