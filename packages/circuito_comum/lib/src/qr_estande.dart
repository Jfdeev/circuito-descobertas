/// Formato único do conteúdo do QR code de um estande, usado pelo painel
/// (geração) e pelo app (leitura).
///
/// Exemplo: `circuito-descobertas:estande:Ab12Cd34`.
abstract final class QrEstande {
  static const prefixo = 'circuito-descobertas:estande:';

  /// IDs aceitos: letras, números e hífen. Sem `_`, pois ele separa
  /// visitante e estande na chave do check-in.
  static final _idValido = RegExp(r'^[A-Za-z0-9-]{1,100}$');

  static bool idValido(String id) => _idValido.hasMatch(id);

  static String codificar(String estandeId) {
    if (!idValido(estandeId)) {
      throw ArgumentError.value(estandeId, 'estandeId', 'ID de estande inválido');
    }
    return '$prefixo$estandeId';
  }

  /// Retorna o ID do estande ou `null` se o conteúdo não for um QR do circuito.
  static String? decodificar(String? conteudo) {
    final texto = conteudo?.trim();
    if (texto == null || !texto.startsWith(prefixo)) return null;
    final id = texto.substring(prefixo.length);
    return idValido(id) ? id : null;
  }
}
