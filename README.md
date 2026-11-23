# pawapay_test

App Flutter de test pour déclencher un dépôt PawaPay (sandbox).

## Local
    flutter create --platforms=android .
    # ajouter <uses-permission android:name="android.permission.INTERNET"/> dans android/app/src/main/AndroidManifest.xml
    flutter run --dart-define=PAWAPAY_TOKEN=votre_token

## GitHub Actions
1. Poussez le projet sur GitHub.
2. Settings > Secrets and variables > Actions > New secret : `PAWAPAY_TOKEN`.
3. Onglet Actions > "Build APK" > Run workflow.
4. Téléchargez l'APK dans les Artifacts.

Sandbox uniquement : ne mettez jamais un token de production dans l'APK.
