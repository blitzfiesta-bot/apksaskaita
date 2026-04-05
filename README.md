# SaskaitaOnline.lt — Flutter Programėlė

## Reikalavimai

- Flutter SDK 3.x ([flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install))
- Android Studio arba VS Code
- Java 17+

## Greitas startas

```bash
# 1. Įdiegti priklausomybes
flutter pub get

# 2. Patikrinti aplinką
flutter doctor

# 3. Paleisti debug režimu (reikia prijungto telefono arba emuliatorius)
flutter run

# 4. Sukompiliuoti Android APK (testiniam įdiegimui)
flutter build apk --release

# 5. Sukompiliuoti Android App Bundle (Google Play)
flutter build appbundle --release
```

## APK failo vieta po kompiliavimo

```
build/app/outputs/flutter-apk/app-release.apk        ← tiesioginis diegimas
build/app/outputs/bundle/release/app-release.aab      ← Google Play
```

## Google Play pateikimas (žingsnis po žingsnio)

### 1. Sukurkite Developer paskyrą
- Eikite į [play.google.com/console](https://play.google.com/console)
- Sumokėkite **25 USD** vienkartinį mokestį
- Užpildykite kūrėjo profilį

### 2. Sukurkite Keystore (pasirašymui)
```bash
keytool -genkey -v \
  -keystore android/app/keystore.jks \
  -alias saskaitaonline \
  -keyalg RSA -keysize 2048 \
  -validity 10000
```
⚠️ **SVARBU:** Išsaugokite keystore.jks ir slaptažodžius saugiai!
Praradus keystore negalėsite atnaujinti programėlės.

### 3. Sukurkite key.properties failą
```
# android/key.properties
storePassword=JUSU_SLAPTAZODIS
keyPassword=JUSU_KEY_SLAPTAZODIS
keyAlias=saskaitaonline
storeFile=keystore.jks
```

### 4. Atnaujinkite build.gradle
Pakeiskite `signingConfigs.debug` į `signingConfigs.release` faile
`android/app/build.gradle` ir įtraukite key.properties.

### 5. Sukompiliuokite App Bundle
```bash
flutter build appbundle --release
```

### 6. Google Play Console
1. Sukurkite naują programėlę
2. Užpildykite: pavadinimas, aprašymas, kategorija (Business)
3. Įkelkite `app-release.aab`
4. Pridėkite ekranų nuotraukas (min. 2)
5. Pateikite peržiūrai (~3-7 d. d.)

## iOS (App Store)

Reikia:
- Mac kompiuterio
- Apple Developer paskyros (**99 USD/m.**) → [developer.apple.com](https://developer.apple.com)
- Xcode 15+

```bash
flutter build ios --release
# Tada atidaryti Xcode ir Archive → Distribute
```

## Struktūra

```
lib/
  main.dart              ← Programėlės įėjimas
  screens/
    splash_screen.dart   ← Paleidimo ekranas
    webview_screen.dart  ← WebView + navigacija
android/                 ← Android konfigūracija
ios/                     ← iOS konfigūracija
assets/
  offline.html           ← Offline puslapis
```

## Versijų keitimas

`pubspec.yaml`:
```yaml
version: 1.0.1+2   # pirmoji dalis — vartotojui matoma, +2 — versionCode
```
