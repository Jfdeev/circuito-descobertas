import 'package:circuito_comum/circuito_comum.dart';
import 'package:circuitodescobertas/servicos/eventos_analytics.dart';
import 'package:circuitodescobertas/servicos/fluxo_checkin.dart';
import 'package:circuitodescobertas/servicos/missao_remota.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('MissaoRemota', () {
    late FakeRemoteConfig rc;
    late MissaoRemota missao;

    setUp(() {
      rc = FakeRemoteConfig();
      missao = MissaoRemota(rc);
    });

    test('padrão local inicia com a missão desligada', () async {
      rc.falharFetch = true;
      await missao.iniciar();
      expect(missao.config.value, ConfigMissao.desligada);
      expect(rc.configuracoes?.minimumFetchInterval, const Duration(minutes: 1));
    });

    test('aplica a configuração publicada na abertura', () async {
      rc.publicado = {'missao_ativa': true, 'missao_estandes': 'a,b'};
      await missao.iniciar();
      expect(missao.config.value.ativa, isTrue);
      expect(missao.config.value.estandeIds, {'a', 'b'});
    });

    test('liga e desliga a missão em tempo real', () async {
      await missao.iniciar();

      rc.publicar({'missao_ativa': true, 'missao_estandes': 'a'});
      await pumpEventQueue();
      expect(missao.config.value.ativa, isTrue);

      rc.publicar({'missao_ativa': false});
      await pumpEventQueue();
      expect(missao.config.value.ativa, isFalse);
    });
  });

  group('EventosAnalytics', () {
    test('envia os nomes e parâmetros exigidos', () async {
      final analytics = FakeAnalytics();
      final eventos = EventosAnalytics(analytics);
      const estande = Estande(
        id: 'est1',
        nome: 'Robótica',
        descricao: '',
        localizacao: '',
        ativo: true,
      );

      await eventos.registrarMissaoAberta(totalEstandes: 3);
      await eventos.registrarCheckinConcluido(estande);

      expect(analytics.eventos.map((e) => e.nome), [
        'missao_aberta',
        'checkin_concluido',
      ]);
      expect(analytics.eventos.first.parametros, {'total_estandes': 3});
      expect(analytics.eventos.last.parametros?['estande_id'], 'est1');
    });
  });

  group('FluxoCheckin', () {
    late FakeFirebaseFirestore db;
    late FakeAnalytics analytics;
    late EstandeRepositorio estandes;
    late FluxoCheckin fluxo;

    setUp(() {
      db = FakeFirebaseFirestore();
      analytics = FakeAnalytics();
      estandes = EstandeRepositorio(db);
      fluxo = FluxoCheckin(
        registro: RegistroCheckin(
          estandes: estandes,
          checkins: CheckinRepositorio(db),
        ),
        eventos: EventosAnalytics(analytics),
        visitanteId: 'visitante',
      );
    });

    test('envia checkin_concluido somente após gravar', () async {
      final id = await estandes.criar(nome: 'X', descricao: '', localizacao: '');

      final r = await fluxo.processar(QrEstande.codificar(id));
      expect(r.sucesso, isTrue);
      expect(analytics.eventos.single.parametros?['estande_id'], id);

      final repetido = await fluxo.processar(QrEstande.codificar(id));
      expect(repetido.status, StatusCheckin.jaRegistrado);
      expect(analytics.eventos, hasLength(1));
    });

    test('QR inválido não envia evento', () async {
      final r = await fluxo.processar('lixo');
      expect(r.status, StatusCheckin.qrInvalido);
      expect(analytics.eventos, isEmpty);
    });

    test('falha no Analytics não desfaz o check-in', () async {
      analytics.falhar = true;
      final id = await estandes.criar(nome: 'X', descricao: '', localizacao: '');
      final r = await fluxo.processar(QrEstande.codificar(id));
      expect(r.sucesso, isTrue);
    });
  });

  group('mensagemCheckin', () {
    const estande = Estande(
      id: 'e',
      nome: 'Robótica',
      descricao: '',
      localizacao: '',
      ativo: true,
    );

    test('tem um texto para cada resultado', () {
      expect(
        mensagemCheckin(
          const ResultadoCheckin(StatusCheckin.sucesso, estande: estande),
        ),
        contains('confirmado'),
      );
      expect(
        mensagemCheckin(const ResultadoCheckin(StatusCheckin.qrInvalido)),
        contains('inválido'),
      );
      expect(
        mensagemCheckin(
          const ResultadoCheckin(StatusCheckin.estandeInexistente),
        ),
        contains('não existe'),
      );
      expect(
        mensagemCheckin(
          const ResultadoCheckin(StatusCheckin.estandeInativo, estande: estande),
        ),
        contains('inativo'),
      );
      expect(
        mensagemCheckin(
          const ResultadoCheckin(StatusCheckin.jaRegistrado, estande: estande),
        ),
        contains('já registrou'),
      );
    });
  });
}
