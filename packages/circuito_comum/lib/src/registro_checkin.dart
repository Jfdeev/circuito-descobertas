import 'package:cloud_firestore/cloud_firestore.dart';

import 'checkin_repositorio.dart';
import 'estande.dart';
import 'estande_repositorio.dart';
import 'qr_estande.dart';

enum StatusCheckin {
  qrInvalido,
  estandeInexistente,
  estandeInativo,
  jaRegistrado,
  sucesso,
}

class ResultadoCheckin {
  const ResultadoCheckin(this.status, {this.estande});

  final StatusCheckin status;
  final Estande? estande;

  bool get sucesso => status == StatusCheckin.sucesso;
}

/// Valida o QR lido e grava o check-in somente para estande existente e ativo.
class RegistroCheckin {
  RegistroCheckin({required this.estandes, required this.checkins});

  final EstandeRepositorio estandes;
  final CheckinRepositorio checkins;

  Future<ResultadoCheckin> registrar({
    required String? conteudoQr,
    required String visitanteId,
  }) async {
    final estandeId = QrEstande.decodificar(conteudoQr);
    if (estandeId == null) {
      return const ResultadoCheckin(StatusCheckin.qrInvalido);
    }

    final estande = await estandes.buscar(estandeId);
    if (estande == null) {
      return const ResultadoCheckin(StatusCheckin.estandeInexistente);
    }
    if (!estande.ativo) {
      return ResultadoCheckin(StatusCheckin.estandeInativo, estande: estande);
    }
    if (await checkins.existe(visitanteId, estandeId)) {
      return ResultadoCheckin(StatusCheckin.jaRegistrado, estande: estande);
    }

    try {
      await checkins.registrar(visitanteId, estandeId);
    } on FirebaseException catch (e) {
      // As regras negam sobrescrever um check-in; se outro dispositivo da
      // mesma sessão gravou antes, trata como visita já registrada.
      if (e.code == 'permission-denied' &&
          await checkins.existe(visitanteId, estandeId)) {
        return ResultadoCheckin(StatusCheckin.jaRegistrado, estande: estande);
      }
      rethrow;
    }
    return ResultadoCheckin(StatusCheckin.sucesso, estande: estande);
  }
}
