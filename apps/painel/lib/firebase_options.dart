// ARQUIVO PROVISÓRIO.
//
// Será substituído ao executar, dentro de apps/painel:
//   flutterfire configure --platforms=web
// Veja docs/FIREBASE_SETUP.md.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase ainda não configurado. Execute "flutterfire configure" em '
    'apps/painel (veja docs/FIREBASE_SETUP.md).',
  );
}
