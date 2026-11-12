import 'package:circuito_comum/circuito_comum.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:painel/acesso_admin.dart';
import 'package:painel/main.dart';
import 'package:painel/rota_qr.dart';
import 'package:painel/telas/painel_tela.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  late FakeFirebaseFirestore db;
  late EstandeRepositorio estandes;
  late CheckinRepositorio checkins;
  late List<RotaQr> abertas;

  setUp(() {
    db = FakeFirebaseFirestore();
    estandes = EstandeRepositorio(db);
    checkins = CheckinRepositorio(db);
    abertas = [];
  });

  Widget painel() => MaterialApp(
    home: PainelTela(
      estandes: estandes,
      checkins: checkins,
      emailAdmin: 'adm@feira.com',
      onSair: () {},
      abrirEmNovaAba: (rota) async => abertas.add(rota),
    ),
  );

  Future<void> usarTelaGrande(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('cria 3 estandes de exemplo quando vazio', (tester) async {
    await usarTelaGrande(tester);
    await tester.pumpWidget(painel());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar 3 estandes de exemplo'));
    await tester.pumpAndSettle();

    for (final e in estandesExemplo) {
      expect(find.text(e.nome), findsOneWidget);
    }
    expect(find.text('3 estandes'), findsOneWidget);
  });

  testWidgets('mostra o novo total após um check-in no app', (tester) async {
    await usarTelaGrande(tester);
    final id = await estandes.criar(nome: 'X', descricao: 'd', localizacao: 'l');
    await tester.pumpWidget(painel());
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(Key('total-$id'))).data, '0');

    await checkins.registrar('visitante', id);
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(Key('total-$id'))).data, '1');
    expect(find.text('1 check-ins confirmados'), findsOneWidget);
  });

  testWidgets('cadastra estande pelo formulário com validação', (
    tester,
  ) async {
    await usarTelaGrande(tester);
    await tester.pumpWidget(painel());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Campo obrigatório'), findsNWidgets(3));

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Drones');
    await tester.enterText(campos.at(1), 'Drones de entrega');
    await tester.enterText(campos.at(2), 'Corredor D');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final salvos = (await tester.runAsync(
      () => estandes.observarTodos().first,
    ))!;
    expect(salvos.single.nome, 'Drones');
    expect(salvos.single.ativo, isTrue);
  });

  testWidgets('desativa estande pelo switch', (tester) async {
    await usarTelaGrande(tester);
    final id = await estandes.criar(nome: 'X', descricao: 'd', localizacao: 'l');
    await tester.pumpWidget(painel());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final salvo = await tester.runAsync(() => estandes.buscar(id));
    expect(salvo?.ativo, isFalse);
    expect(find.text('Inativo'), findsOneWidget);
  });

  testWidgets('mostra QR e abre a página de impressão', (tester) async {
    await usarTelaGrande(tester);
    final id = await estandes.criar(nome: 'X', descricao: 'd', localizacao: 'l');
    await tester.pumpWidget(painel());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('QR code'));
    await tester.pumpAndSettle();
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr, isNotNull);

    await tester.tap(find.text('Abrir para imprimir'));
    expect(abertas.single.estandeId, id);
    expect(abertas.single.nome, 'X');
  });

  group('PainelApp e PortaoAdmin', () {
    Widget app(MockFirebaseAuth auth) => PainelApp(
      inicio: (_) => PortaoAdmin(
        acesso: AcessoAdmin(auth: auth, db: db),
        painel: (u) => Text('painel de ${u.email}'),
      ),
    );

    testWidgets('sem login mostra a tela de login', (tester) async {
      await tester.pumpWidget(app(MockFirebaseAuth()));
      await tester.pumpAndSettle();
      expect(find.text('Painel da organização'), findsOneWidget);
    });

    testWidgets('admin autenticado vê o painel', (tester) async {
      await db.collection('admins').doc('adm').set({});
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'adm', email: 'adm@feira.com'),
      );
      await tester.pumpWidget(app(auth));
      await tester.pumpAndSettle();
      expect(find.text('painel de adm@feira.com'), findsOneWidget);
    });

    testWidgets('usuário sem admins/{uid} é bloqueado', (tester) async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'x', email: 'x@feira.com'),
      );
      await tester.pumpWidget(app(auth));
      await tester.pumpAndSettle();
      expect(find.textContaining('não é administradora'), findsOneWidget);
    });

    testWidgets('rota /qr/<id> abre a página pública sem login', (
      tester,
    ) async {
      tester.platformDispatcher.defaultRouteNameTestValue =
          '/qr/abc?nome=Rob%C3%B3tica';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);

      await tester.pumpWidget(app(MockFirebaseAuth()));
      await tester.pumpAndSettle();

      expect(find.text('Robótica'), findsOneWidget);
      expect(find.text('ID: abc'), findsOneWidget);
      expect(
        tester.widget<QrImageView>(find.byType(QrImageView)),
        isNotNull,
      );
      expect(find.text('Painel da organização'), findsNothing);
    });
  });
}
