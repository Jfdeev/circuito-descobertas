import 'package:circuito_comum/circuito_comum.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Eventos de uso enviados ao Google Analytics 4.
class EventosAnalytics {
  EventosAnalytics(this._analytics);

  static const missaoAberta = 'missao_aberta';
  static const checkinConcluido = 'checkin_concluido';

  final FirebaseAnalytics _analytics;

  Future<void> registrarMissaoAberta({required int totalEstandes}) {
    return _analytics.logEvent(
      name: missaoAberta,
      parameters: {'total_estandes': totalEstandes},
    );
  }

  Future<void> registrarCheckinConcluido(Estande estande) {
    return _analytics.logEvent(
      name: checkinConcluido,
      parameters: {'estande_id': estande.id, 'estande_nome': estande.nome},
    );
  }
}
