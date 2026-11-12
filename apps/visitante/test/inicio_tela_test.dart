import 'package:circuito_comum/circuito_comum.dart';
import 'package:circuitodescobertas/servicos/eventos_analytics.dart';
import 'package:circuitodescobertas/servicos/fluxo_checkin.dart';
import 'package:circuitodescobertas/telas/inicio_tela.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeFirebaseFirestore db;
  late EstandeRepositorio estandes;
  late FakeAnalytics analytics;
  late ValueNotifier<ConfigMissao> missao;
  late String idRobotica;

  setUp(() async {
    db = FakeFirebaseFirestore();
    estandes = EstandeRepositorio(db);
    analytics = FakeAnalytics();
    missao = ValueNotifier(ConfigMissao.desligada);
    idRobotica = await estandes.criar(
      nome: 'Robótica',
      descricao: 'Robôs autônomos',
      localizacao: 'Corredor B',
    );
    await estandes.criar(
      nome: 'Games',
      descricao: 'Jogos',
      localizacao: 'Corredor C',
    );
    await estandes.criar(
      nome: 'Fechado',
      descricao: '',
      localizacao: '',
      ativo: false,
    );
  });

  Future<void> abrir(WidgetTester tester) async {
    final eventos = EventosAnalytics(analytics);
    await tester.pumpWidget(
      MaterialApp(
        home: InicioTela(
          estandes: estandes,
          missao: missao,
          eventos: eventos,
          fluxo: FluxoCheckin(
            registro: RegistroCheckin(
              estandes: estandes,
              checkins: CheckinRepositorio(db),
            ),
            eventos: eventos,
            visitanteId: 'v',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista estandes ativos com a missão desligada', (tester) async {
    await abrir(tester);

    expect(find.text('Robótica'), findsOneWidget);
    expect(find.text('Robôs autônomos'), findsOneWidget);
    expect(find.text('Corredor B'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Fechado'), findsNothing);
    expect(find.byKey(const Key('chamada-missao')), findsNothing);
    expect(find.text('Fazer check-in'), findsOneWidget);
  });

  testWidgets('missão ligada mostra chamada e destaque; desligada retira', (
    tester,
  ) async {
    await abrir(tester);

    missao.value = ConfigMissao(ativa: true, estandeIds: {idRobotica});
    await tester.pump();
    expect(find.byKey(const Key('chamada-missao')), findsOneWidget);
    expect(find.text('Missão'), findsOneWidget);

    missao.value = ConfigMissao.desligada;
    await tester.pump();
    expect(find.byKey(const Key('chamada-missao')), findsNothing);
    expect(find.text('Missão'), findsNothing);
    expect(find.text('Robótica'), findsOneWidget);
  });

  testWidgets('abrir a missão registra missao_aberta e lista participantes', (
    tester,
  ) async {
    missao.value = ConfigMissao(ativa: true, estandeIds: {idRobotica});
    await abrir(tester);

    await tester.tap(find.text('Abrir missão'));
    await tester.pumpAndSettle();

    expect(analytics.eventos.single.nome, 'missao_aberta');
    expect(find.text('Missão surpresa'), findsOneWidget);
    expect(find.text('Robótica'), findsOneWidget);
    expect(find.text('Games'), findsNothing);

    missao.value = ConfigMissao.desligada;
    await tester.pump();
    expect(find.textContaining('encerrada'), findsOneWidget);
  });
}
