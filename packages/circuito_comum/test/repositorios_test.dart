import 'package:circuito_comum/circuito_comum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late EstandeRepositorio estandes;
  late CheckinRepositorio checkins;

  setUp(() {
    db = FakeFirebaseFirestore();
    estandes = EstandeRepositorio(db);
    checkins = CheckinRepositorio(db);
  });

  group('EstandeRepositorio', () {
    test('cria, busca e atualiza um estande', () async {
      final id = await estandes.criar(
        nome: 'Robótica',
        descricao: 'Robôs',
        localizacao: 'Corredor B',
      );

      final criado = await estandes.buscar(id);
      expect(criado?.nome, 'Robótica');
      expect(criado?.ativo, isTrue);

      await estandes.atualizar(criado!.copyWith(ativo: false));
      expect((await estandes.buscar(id))?.ativo, isFalse);
    });

    test('buscar retorna null para ID inexistente', () async {
      expect(await estandes.buscar('nao-existe'), isNull);
    });

    test('observarAtivos lista apenas ativos, ordenados por nome', () async {
      await estandes.criar(nome: 'Zeta', descricao: '', localizacao: '');
      await estandes.criar(nome: 'alfa', descricao: '', localizacao: '');
      await estandes.criar(
        nome: 'Beta',
        descricao: '',
        localizacao: '',
        ativo: false,
      );

      final ativos = await estandes.observarAtivos().first;
      expect(ativos.map((e) => e.nome), ['alfa', 'Zeta']);

      final todos = await estandes.observarTodos().first;
      expect(todos.map((e) => e.nome), ['alfa', 'Beta', 'Zeta']);
    });
  });

  group('CheckinRepositorio', () {
    test('registra com a chave composta e os campos esperados', () async {
      await checkins.registrar('uid1', 'est1');

      final doc = await db.collection('checkins').doc('uid1_est1').get();
      expect(doc.data()?['visitanteId'], 'uid1');
      expect(doc.data()?['estandeId'], 'est1');
      expect(doc.data()?['criadoEm'], isA<Timestamp>());
      expect(await checkins.existe('uid1', 'est1'), isTrue);
      expect(await checkins.existe('uid2', 'est1'), isFalse);
    });

    test('observarTotais soma check-ins por estande', () async {
      await checkins.registrar('u1', 'a');
      await checkins.registrar('u2', 'a');
      await checkins.registrar('u1', 'b');

      expect(await checkins.observarTotais().first, {'a': 2, 'b': 1});
    });

    test('observarTotais emite o novo total após um check-in', () async {
      final totais = checkins.observarTotais();
      final esperado = expectLater(
        totais,
        emitsInOrder([
          <String, int>{},
          {'a': 1},
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      await checkins.registrar('u1', 'a');
      await esperado;
    });
  });

  group('RegistroCheckin', () {
    late RegistroCheckin registro;

    setUp(() {
      registro = RegistroCheckin(estandes: estandes, checkins: checkins);
    });

    Future<ResultadoCheckin> ler(String? qr) =>
        registro.registrar(conteudoQr: qr, visitanteId: 'visitante');

    test('QR fora do formato é inválido', () async {
      expect((await ler('qualquer coisa')).status, StatusCheckin.qrInvalido);
    });

    test('estande inexistente não grava', () async {
      final r = await ler(QrEstande.codificar('fantasma'));
      expect(r.status, StatusCheckin.estandeInexistente);
      expect((await db.collection('checkins').get()).docs, isEmpty);
    });

    test('estande inativo não grava', () async {
      final id = await estandes.criar(
        nome: 'X',
        descricao: '',
        localizacao: '',
        ativo: false,
      );
      final r = await ler(QrEstande.codificar(id));
      expect(r.status, StatusCheckin.estandeInativo);
      expect(await checkins.existe('visitante', id), isFalse);
    });

    test('grava a primeira visita e recusa a segunda', () async {
      final id = await estandes.criar(nome: 'X', descricao: '', localizacao: '');

      final primeira = await ler(QrEstande.codificar(id));
      expect(primeira.sucesso, isTrue);
      expect(primeira.estande?.id, id);
      expect(await checkins.existe('visitante', id), isTrue);

      final segunda = await ler(QrEstande.codificar(id));
      expect(segunda.status, StatusCheckin.jaRegistrado);
      expect((await db.collection('checkins').get()).docs, hasLength(1));
    });
  });
}
