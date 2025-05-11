# flutter_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

### Environment Configuration

Ovaj projekt koristi environment varijable za pohranu osjetljivih API ključeva. Slijedite ove korake za postavljanje svog okruženja:

1. Kreirajte `.env` datoteku u korijenskom direktoriju projekta (flutter_mobile/)
2. Dodajte sljedeće linije u vašu `.env` datoteku:
```
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
HUGGINGFACE_API_KEY=your_huggingface_api_key
```
3. Zamijenite `your_google_maps_api_key` i `your_huggingface_api_key` s vašim stvarnim API ključevima.

**Napomena:** 
- `.env` datoteka je uključena u `.gitignore` kako bi se spriječilo objavljivanje osjetljivih informacija u sustavu za kontrolu verzija.
- Dodali smo fallback mehanizam koji će koristiti zadane vrijednosti ako `.env` datoteka nije pronađena.
- Nije potrebno rekonstruirati aplikaciju nakon izmjene `.env` datoteke.

**Važno:** Dodajte `.env` datoteku u assets u `pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env
```

## Flutter Resources

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
