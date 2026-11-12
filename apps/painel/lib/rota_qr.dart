import 'package:circuito_comum/circuito_comum.dart';

/// Rota pública da página de QR: `/qr/<id>?nome=<nome>`.
/// Não depende de login nem do Firestore, então abre em outra aba e imprime.
class RotaQr {
  const RotaQr({required this.estandeId, required this.nome});

  static const _segmento = 'qr';

  final String estandeId;
  final String nome;

  String get caminho => Uri(
    pathSegments: ['', _segmento, estandeId],
    queryParameters: nome.isEmpty ? null : {'nome': nome},
  ).toString();

  /// Retorna a rota se o nome corresponder a uma página de QR válida.
  static RotaQr? interpretar(String? nomeRota) {
    if (nomeRota == null) return null;
    final uri = Uri.tryParse(nomeRota);
    final segmentos = uri?.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segmentos == null ||
        segmentos.length != 2 ||
        segmentos.first != _segmento ||
        !QrEstande.idValido(segmentos.last)) {
      return null;
    }
    return RotaQr(
      estandeId: segmentos.last,
      nome: uri!.queryParameters['nome'] ?? '',
    );
  }
}
