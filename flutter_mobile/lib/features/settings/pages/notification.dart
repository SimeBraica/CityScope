import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool notificationsEnabled = true;
  bool geoEnabled = false;
  bool eventReminders = false;
  TimeOfDay start = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 20, minute: 0);
  List<String> topics = ['SKULPTURAMA', 'POVIJESNIM ČINJENICAMA'];

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    await FirebaseMessaging.instance.requestPermission();
    // Ovdje možeš spremiti token korisnika u Firestore za ciljanje notifikacija
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? start : end,
    );
    if (picked != null) {
      setState(() {
        if (isStart) start = picked;
        else end = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notifications ?? 'Obavijesti', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF368564),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _settingRow(
              loc.enableNotifications ?? 'Uključi obavijesti',
              notificationsEnabled,
              (v) => setState(() => notificationsEnabled = v),
              activeColor: Colors.orange,
            ),
            const SizedBox(height: 16),
            _settingRow(
              loc.notificationTime ?? 'Vrijeme obavijesti',
              true,
              null,
              child: GestureDetector(
                onTap: () => _pickTime(true),
                child: _timeBox('${start.format(context)} - ${end.format(context)}'),
              ),
            ),
            const SizedBox(height: 16),
            _settingRow(
              loc.geoNotifications ?? 'Lokacijsko obavještavanje',
              geoEnabled,
              (v) => setState(() => geoEnabled = v),
              activeColor: Colors.orange,
            ),
            const SizedBox(height: 16),
            _settingRow(
              loc.eventReminders ?? 'Podsjetnici na lajkane događaje',
              eventReminders,
              (v) => setState(() => eventReminders = v),
              activeColor: Colors.orange,
            ),
            const SizedBox(height: 32),
            Text(
              loc.notifyMeAbout ?? 'OBAVIJESTI ME O:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF484751), letterSpacing: 1.1),
            ),
            const SizedBox(height: 12),
            _searchBox(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: topics.map((t) => _chip(t)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingRow(String label, bool value, ValueChanged<bool>? onChanged, {Widget? child, Color activeColor = Colors.grey}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54))),
        if (child != null) child,
        if (onChanged != null)
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
      ],
    );
  }

  Widget _timeBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black54)),
    );
  }

  Widget _searchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search),
          border: InputBorder.none,
          hintText: '',
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Color(0xFF368564), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      backgroundColor: const Color(0xFFE9FBF2),
      deleteIcon: const Icon(Icons.close, size: 18, color: Color(0xFF368564)),
      onDeleted: () => setState(() => topics.remove(label)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    );
  }
}
