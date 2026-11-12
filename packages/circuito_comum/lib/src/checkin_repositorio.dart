import 'package:cloud_firestore/cloud_firestore.dart';

import 'checkin.dart';

/// Acesso à coleção `checkins` no Cloud Firestore.
class CheckinRepositorio {
  CheckinRepositorio(FirebaseFirestore db) : _colecao = db.collection(colecao);

  static const colecao = 'checkins';

  final CollectionReference<Map<String, dynamic>> _colecao;

  Future<bool> existe(String visitanteId, String estandeId) async {
    final doc = await _colecao.doc(chaveCheckin(visitanteId, estandeId)).get();
    return doc.exists;
  }

  Future<void> registrar(String visitanteId, String estandeId) {
    return _colecao.doc(chaveCheckin(visitanteId, estandeId)).set({
      'visitanteId': visitanteId,
      'estandeId': estandeId,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Total de check-ins confirmados por estande, atualizado em tempo real
  /// (somente administradores).
  Stream<Map<String, int>> observarTotais() => _colecao.snapshots().map(
    (snap) => totalPorEstande(
      snap.docs.map((d) => d.data()['estandeId']).whereType<String>(),
    ),
  );
}
