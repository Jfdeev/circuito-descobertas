import 'package:circuito_comum/circuito_comum.dart';
import 'package:flutter/foundation.dart';

import 'eventos_analytics.dart';

/// Registra o check-in do visitante e, só após a gravação, envia o evento.
class FluxoCheckin {
  FluxoCheckin({
    required this.registro,
    required this.eventos,
    required this.visitanteId,
  });

  final RegistroCheckin registro;
  final EventosAnalytics eventos;
  final String visitanteId;

  Future<ResultadoCheckin> processar(String? conteudoQr) async {
    final resultado = await registro.registrar(
      conteudoQr: conteudoQr,
      visitanteId: visitanteId,
    );
    if (resultado.sucesso) {
      try {
        await eventos.registrarCheckinConcluido(resultado.estande!);
      } on Exception catch (e) {
        // A visita já foi gravada; falha de telemetria não a desfaz.
        debugPrint('Analytics checkin_concluido: $e');
      }
    }
    return resultado;
  }
}

/// Mensagem exibida ao visitante para cada resultado.
String mensagemCheckin(ResultadoCheckin resultado) {
  final nome = resultado.estande?.nome;
  return switch (resultado.status) {
    StatusCheckin.sucesso => 'Check-in confirmado em "$nome"!',
    StatusCheckin.qrInvalido =>
      'QR code inválido. Leia o QR oficial de um estande do circuito.',
    StatusCheckin.estandeInexistente =>
      'Este estande não existe no circuito.',
    StatusCheckin.estandeInativo =>
      'O estande "$nome" está inativo no momento.',
    StatusCheckin.jaRegistrado => 'Você já registrou visita em "$nome".',
  };
}
