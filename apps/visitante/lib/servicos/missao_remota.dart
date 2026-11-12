import 'dart:async';

import 'package:circuito_comum/circuito_comum.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Lê a missão surpresa do Remote Config e reage às publicações em tempo
/// real, sem reinstalar o app.
class MissaoRemota {
  MissaoRemota(this._rc);

  static const chaveAtiva = 'missao_ativa';
  static const chaveEstandes = 'missao_estandes';

  /// Padrão local: missão desligada.
  static const padroes = <String, Object>{chaveAtiva: false, chaveEstandes: ''};

  final FirebaseRemoteConfig _rc;
  final ValueNotifier<ConfigMissao> _config = ValueNotifier(
    ConfigMissao.desligada,
  );
  StreamSubscription<RemoteConfigUpdate>? _atualizacoes;

  ValueListenable<ConfigMissao> get config => _config;

  Future<void> iniciar() async {
    await _rc.setDefaults(padroes);
    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ),
    );
    _publicar();

    _atualizacoes = _rc.onConfigUpdated.listen(
      (_) => _ativar(),
      onError: (Object e) => debugPrint('Remote Config em tempo real: $e'),
    );

    try {
      await _rc.fetchAndActivate();
    } on Exception catch (e) {
      // Sem rede: segue com o padrão local ou o último valor ativado.
      debugPrint('Remote Config fetch: $e');
    }
    _publicar();
  }

  Future<void> _ativar() async {
    await _rc.activate();
    _publicar();
  }

  void _publicar() {
    _config.value = ConfigMissao.fromValores(
      ativa: _rc.getBool(chaveAtiva),
      estandes: _rc.getString(chaveEstandes),
    );
  }

  Future<void> dispose() async {
    await _atualizacoes?.cancel();
    _config.dispose();
  }
}
