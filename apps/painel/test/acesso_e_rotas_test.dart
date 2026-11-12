import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:painel/acesso_admin.dart';
import 'package:painel/rota_qr.dart';

void main() {
  group('AcessoAdmin', () {
    test('é admin somente com documento em admins/{uid}', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('admins').doc('adm').set({'email': 'a@x.com'});
      final acesso = AcessoAdmin(auth: MockFirebaseAuth(), db: db);

      expect(await acesso.ehAdmin('adm'), isTrue);
      expect(await acesso.ehAdmin('outro'), isFalse);
    });

    test('entrar e sair alteram o usuário autenticado', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'adm', email: 'a@x.com'),
      );
      final acesso = AcessoAdmin(auth: auth, db: FakeFirebaseFirestore());

      await acesso.entrar(' a@x.com ', 'senha');
      expect(auth.currentUser?.uid, 'adm');

      await acesso.sair();
      expect(auth.currentUser, isNull);
    });

    test('mensagens de erro de login', () {
      String msg(String code) =>
          mensagemErroLogin(FirebaseAuthException(code: code));
      expect(msg('invalid-credential'), 'E-mail ou senha incorretos.');
      expect(msg('wrong-password'), 'E-mail ou senha incorretos.');
      expect(msg('invalid-email'), 'E-mail inválido.');
      expect(msg('outro'), contains('outro'));
    });
  });

  group('RotaQr', () {
    test('gera e interpreta o mesmo caminho', () {
      const rota = RotaQr(estandeId: 'Ab12', nome: 'Açaí Tech');
      final lida = RotaQr.interpretar(rota.caminho);
      expect(rota.caminho, startsWith('/qr/Ab12'));
      expect(lida?.estandeId, 'Ab12');
      expect(lida?.nome, 'Açaí Tech');
    });

    test('nome é opcional', () {
      expect(RotaQr.interpretar('/qr/abc')?.nome, '');
    });

    test('rejeita outras rotas e IDs inválidos', () {
      expect(RotaQr.interpretar(null), isNull);
      expect(RotaQr.interpretar('/'), isNull);
      expect(RotaQr.interpretar('/qr'), isNull);
      expect(RotaQr.interpretar('/outra/abc'), isNull);
      expect(RotaQr.interpretar('/qr/a_b'), isNull);
    });
  });
}
