import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.privacyPolicy, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF368564),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.privacyPolicy,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF368564)),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.privacyDemo,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.privacyContact,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.privacyDisclaimer,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 