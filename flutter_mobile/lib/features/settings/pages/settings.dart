import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_mobile/features/auth/presentation/pages/login/login.dart';
import 'package:flutter_mobile/features/settings/pages/personal_info.dart';
import 'package:flutter_mobile/features/settings/pages/privacy.dart';
import 'package:flutter_mobile/core/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mobile/features/settings/pages/interests.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF368564),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding + 32, left: 24, right: 24, bottom: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.settings,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Color(0xFFF6FFFA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '👋 ${AppLocalizations.of(context)!.greeting}',
                            style: const TextStyle(
                              color: Color(0xFF368564),
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _SettingsTile(title: AppLocalizations.of(context)!.personalInfo, onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
                      );
                    }),
                    _SettingsTile(title: AppLocalizations.of(context)!.interests, onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InterestsPage()),
                      );
                    }),
                    _SettingsTile(title: AppLocalizations.of(context)!.notifications, onTap: () {}),
                    _SettingsTile(title: AppLocalizations.of(context)!.language, onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const _LanguageDialog(),
                      );
                    }),
                    _SettingsTile(title: AppLocalizations.of(context)!.privacy, onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PrivacyPage()),
                      );
                    }),
                    const Divider(height: 32, thickness: 0.5),
                    _SettingsTile(
                      title: AppLocalizations.of(context)!.logout,
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const Login()),
                            (route) => false,
                          );
                        }
                      },
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color? color;
  const _SettingsTile({required this.title, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
          fontSize: 17,
        ),
      ),
      trailing: title == AppLocalizations.of(context)!.logout ? null : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      shape: const Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
    );
  }
}

class _LanguageDialog extends StatelessWidget {
  const _LanguageDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.language),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Hrvatski'),
            onTap: () {
              LocaleProvider.of(context)?.setLocale(const Locale('hr'));
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('English'),
            onTap: () {
              LocaleProvider.of(context)?.setLocale(const Locale('en'));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
