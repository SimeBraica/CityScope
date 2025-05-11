import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_mobile/features/home/presentation/home.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PersonalizePage extends StatefulWidget {
  const PersonalizePage({Key? key}) : super(key: key);

  @override
  State<PersonalizePage> createState() => _PersonalizePageState();
}

class _PersonalizePageState extends State<PersonalizePage> {
  List<Map<String, dynamic>> _preferences = [];
  Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
    final prefsSnap = await FirebaseFirestore.instance.collection('preferences').get();
    setState(() {
      _preferences = prefsSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _loading = false;
    });
  }

  Future<void> _savePreferences() async {
    setState(() { _saving = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': _selected.toList(),
      }, SetOptions(merge: true));
    }
    setState(() { _saving = false; });
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: _selected.length / 3 < 1 ? _selected.length / 3 : 1,
                          backgroundColor: const Color(0xFFE5E7EB),
                          color: const Color(0xFF368564),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context)!.personalizeExperience,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Color(0xFF484751)),
                        ),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.chooseInterests, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _preferences.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final pref = _preferences[i];
                        final selected = _selected.contains(pref['id']);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selected.remove(pref['id']);
                              } else {
                                _selected.add(pref['id']);
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFEAF3FF) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: selected ? const Color(0xFF368564) : Colors.grey.shade300, width: 1.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(pref['name'] ?? '', style: const TextStyle(fontSize: 18)),
                                if (selected)
                                  const Icon(Icons.check, color: Color(0xFF368564)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selected.length >= 3 && !_saving ? _savePreferences : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF368564),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(AppLocalizations.of(context)!.next, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
