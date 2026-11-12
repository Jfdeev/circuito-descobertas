import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class EventoRegistrado {
  EventoRegistrado(this.nome, this.parametros);

  final String nome;
  final Map<String, Object>? parametros;
}

class FakeAnalytics implements FirebaseAnalytics {
  final eventos = <EventoRegistrado>[];
  bool falhar = false;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    List<AnalyticsEventItem>? items,
    AnalyticsCallOptions? callOptions,
  }) async {
    if (falhar) throw Exception('analytics indisponível');
    eventos.add(EventoRegistrado(name, parameters));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Simula o Remote Config: `publicado` é o que está no console e
/// `ativo` o que o app enxerga após activate().
class FakeRemoteConfig implements FirebaseRemoteConfig {
  Map<String, Object> ativo = {};
  Map<String, Object> publicado = {};
  bool falharFetch = false;
  RemoteConfigSettings? configuracoes;
  final atualizacoes = StreamController<RemoteConfigUpdate>.broadcast();

  @override
  Future<void> setDefaults(Map<String, dynamic> defaultParameters) async {
    ativo = {...defaultParameters.cast<String, Object>(), ...ativo};
  }

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {
    configuracoes = settings;
  }

  @override
  Future<bool> fetchAndActivate() async {
    if (falharFetch) throw Exception('offline');
    return activate();
  }

  @override
  Future<bool> activate() async {
    ativo = {...ativo, ...publicado};
    return true;
  }

  @override
  bool getBool(String key) => ativo[key] as bool? ?? false;

  @override
  String getString(String key) => ativo[key] as String? ?? '';

  @override
  Stream<RemoteConfigUpdate> get onConfigUpdated => atualizacoes.stream;

  /// Publica no "console" e dispara a atualização em tempo real.
  void publicar(Map<String, Object> valores) {
    publicado = {...publicado, ...valores};
    atualizacoes.add(RemoteConfigUpdate(valores.keys.toSet()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
