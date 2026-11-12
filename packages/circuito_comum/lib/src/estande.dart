/// Estande da feira cadastrado pela organização.
class Estande {
  const Estande({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.localizacao,
    required this.ativo,
  });

  factory Estande.fromMap(String id, Map<String, dynamic> dados) {
    return Estande(
      id: id,
      nome: dados['nome'] as String? ?? '',
      descricao: dados['descricao'] as String? ?? '',
      localizacao: dados['localizacao'] as String? ?? '',
      ativo: dados['ativo'] as bool? ?? false,
    );
  }

  final String id;
  final String nome;
  final String descricao;
  final String localizacao;
  final bool ativo;

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'descricao': descricao,
    'localizacao': localizacao,
    'ativo': ativo,
  };

  Estande copyWith({
    String? nome,
    String? descricao,
    String? localizacao,
    bool? ativo,
  }) {
    return Estande(
      id: id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      localizacao: localizacao ?? this.localizacao,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Estande &&
      other.id == id &&
      other.nome == nome &&
      other.descricao == descricao &&
      other.localizacao == localizacao &&
      other.ativo == ativo;

  @override
  int get hashCode => Object.hash(id, nome, descricao, localizacao, ativo);
}
