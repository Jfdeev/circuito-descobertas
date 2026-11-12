/// Chave composta do check-in: uma visita por visitante e por estande.
/// As regras do Firestore exigem exatamente este formato de ID.
String chaveCheckin(String visitanteId, String estandeId) =>
    '${visitanteId}_$estandeId';

/// Conta os check-ins por estande a partir dos IDs de estande dos registros.
Map<String, int> totalPorEstande(Iterable<String> estandeIds) {
  final totais = <String, int>{};
  for (final id in estandeIds) {
    totais[id] = (totais[id] ?? 0) + 1;
  }
  return totais;
}
