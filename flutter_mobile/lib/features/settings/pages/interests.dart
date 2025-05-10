import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mobile/features/settings/pages/music_page.dart';
import 'package:flutter_mobile/features/settings/pages/food_page.dart';
import 'package:flutter_mobile/features/settings/pages/attractions_page.dart';
import 'package:flutter_mobile/features/settings/pages/culture_page.dart';
import 'package:flutter_mobile/features/settings/pages/hobbies_page.dart';

class InterestsPage extends StatelessWidget {
  const InterestsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.interests, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF368564),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('interests').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final interests = snapshot.data!.docs;
            return ListView.separated(
              itemCount: interests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final data = interests[index].data() as Map<String, dynamic>;
                final name = locale == 'hr' ? data['name'] : data['en'];
                return ListTile(
                  title: Text(
                    name ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  leading: const Icon(Icons.label, color: Color(0xFF368564)),
                  onTap: () {
                    final firstWord = (data['name'] ?? '').split(' ').first.toLowerCase();
                    Widget? page;

                    switch (firstWord) {
                      case 'glazbeni':
                        page = const MusicPage();
                        break;
                      case 'hrana':
                        page = const FoodPage();
                        break;
                      case 'znamenitosti':
                        page = const AttractionsPage();
                        break;
                      case 'kultura':
                        page = const CulturePage();
                        break;
                      case 'hobiji':
                        page = const HobbiesPage();
                        break;
                      default: break;
                    }

                    if (page != null) {
                        Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => page!),
                        );
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
