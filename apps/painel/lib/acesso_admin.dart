import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Login por e-mail e senha. Só é administrador quem tem documento em
/// `admins/{uid}` (criado manualmente no console do Firebase).
class AcessoAdmin {
  AcessoAdmin({required this.auth, required FirebaseFirestore db})
    : _admins = db.collection(colecao);

  static const colecao = 'admins';

  final FirebaseAuth auth;
  final CollectionReference<Map<String, dynamic>> _admins;

  Stream<User?> get usuario => auth.authStateChanges();

  Future<void> entrar(String email, String senha) =>
      auth.signInWithEmailAndPassword(email: email.trim(), password: senha);

  Future<void> sair() => auth.signOut();

  Future<bool> ehAdmin(String uid) async {
    try {
      return (await _admins.doc(uid).get()).exists;
    } on FirebaseException {
      // Regras negam a leitura para quem não é o próprio admin.
      return false;
    }
  }
}

/// Mensagem amigável para os erros de login mais comuns.
String mensagemErroLogin(FirebaseAuthException e) => switch (e.code) {
  'invalid-email' => 'E-mail inválido.',
  'user-disabled' => 'Usuário desativado.',
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' => 'E-mail ou senha incorretos.',
  'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
  _ => 'Não foi possível entrar (${e.code}).',
};
