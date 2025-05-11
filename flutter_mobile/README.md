# CityScope

## Dobrodošli

Dobrodošli na projekt CityScope, Android aplikaciju koja predstavlja Vašeg turističkog vodiča. 
Glavne funkcionalnosti ove aplikacije jesu:
1. autentikacija i autorizacija putem emaila i lozinke ili putem Vašeg Google računa
2. pametno pretraživanje restorana, kafića, lokacija, mjesta za hobi ili relaksaciju na osnovi Vaše lokacije
3. geolokacijske obavijesti ovisno o tome gdje se nalazite kako nikada ne bi prošli pored znamenite lokacije nezapaženo

---

## Upute za pokretanje projekta

Slijedite korake u nastavku kako biste pokrenuli CityScope Flutter projekt na svom računalu:

1. **Instalirajte Flutter**

   * Provjerite imate li instaliran Flutter:

     ```bash
     flutter --version
     ```
   * Ako nemate, pratite službenu uputu: [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)

2. **Postavite emulatore ili uređaje**

   * Za Android: otvorite Android Studio i kreirajte AVD (Android Virtual Device).
   * Za iOS: otvorite Xcode i postavite simulator.
   * Alternativno, priključite fizički uređaj putem USB-a.

3. **Klonirajte repozitorij**

   ```bash
   git clone https://github.com/vaš-korisnik/CityScope.git
   cd CityScope
   ```

4. **Instalirajte ovisnosti**

   ```bash
   flutter pub get
   ```

5. **Pokrenite aplikaciju**

   ```bash
   flutter run
   ```

> **Napomena:** Možete dodati `-d <device_id>` ako želite ciljano pokrenuti na određenom emulatoru ili uređaju.

---

## Konfiguracija Okruženja

Ovaj projekt koristi environment varijable za pohranu osjetljivih API ključeva. Slijedite ove korake za postavljanje:

1. Kreirajte `.env` datoteku u korijenskom direktoriju projekta (`CityScope/`).
2. Dodajte sljedeće linije u `.env`:

   ```dotenv
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key
   HUGGINGFACE_API_KEY=your_huggingface_api_key
   ```
3. Zamijenite `your_google_maps_api_key` i `your_huggingface_api_key` svojim ključevima.

> **Važno:** `.env` je već uključen u `.gitignore` kako bi se spriječilo objavljivanje ključeva. Implementiran je fallback mehanizam koji koristi prazne vrijednosti ako `.env` nije pronađen te određene funkcionalnosti stoga mogu biti ograničene.

### Pubspec

U `pubspec.yaml` dodajte `.env` u assets:

```yaml
flutter:
  assets:
    - .env
```

---

## Ograničenja

Kako se radi o demo projektu koji je izgrađen bez budžeta, a koristi Firebase, Google Cloud i Hugging Face API pozive moguće je da neke funkcionalnosti s vremenom postanu ograničene. 
Najznačajnija takva funkcionalnost jest AI generacija zabavnih činjenica. Kako platforma hugging face ima ograničenje na besplatno korištenje javno dostupnih modela, jednom kada token koji je korišten u izradi aplikacije prijeđe tu granicu više neće biti moguće dobijati AI generirane činjenice, već će se koristiti fallback mehanizam na hard coded vrijednosti. Iz istog razloga geolokacijske obavijesti ne sadržavaju zabavne činjenice već isključivo lokaciju na kojoj se korisnik nalazi. 
