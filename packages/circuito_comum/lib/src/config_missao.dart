import 'estande.dart';

/// Configuração da missão surpresa, publicada pelo Remote Config.
class ConfigMissao {
  const ConfigMissao({required this.ativa, required this.estandeIds});

  /// Interpreta o texto de `missao_estandes`: IDs separados por vírgula,
  /// ponto e vírgula, espaço ou quebra de linha.
  factory ConfigMissao.fromValores({
    required bool ativa,
    required String estandes,
  }) {
    final ids = estandes
        .split(RegExp(r'[,;\s]+'))
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    return ConfigMissao(ativa: ativa, estandeIds: ids);
  }

  /// Padrão local: missão desligada.
  static const desligada = ConfigMissao(ativa: false, estandeIds: {});

  final bool ativa;
  final Set<String> estandeIds;

  /// Estandes ativos que participam da missão. Vazio com a missão desligada.
  List<Estande> participantes(Iterable<Estande> estandes) {
    if (!ativa) return const [];
    return estandes
        .where((e) => e.ativo && estandeIds.contains(e.id))
        .toList(growable: false);
  }

  /// A chamada só aparece se a missão estiver ligada e houver participantes.
  bool visivel(Iterable<Estande> estandes) =>
      participantes(estandes).isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is ConfigMissao &&
      other.ativa == ativa &&
      other.estandeIds.length == estandeIds.length &&
      other.estandeIds.containsAll(estandeIds);

  @override
  int get hashCode => Object.hash(ativa, Object.hashAllUnordered(estandeIds));
}
