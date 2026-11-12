// ARQUIVO PROVISÓRIO.
//
// Será substituído ao executar, dentro de apps/visitante:
//   flutterfire configure --platforms=android
// Veja docs/FIREBASE_SETUP.md.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase ainda não configurado. Execute "flutterfire configure" em '
    'apps/visitante (veja docs/FIREBASE_SETUP.md).',
  );
}
