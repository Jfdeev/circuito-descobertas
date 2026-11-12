import 'package:cloud_firestore/cloud_firestore.dart';

import 'estande.dart';

/// Acesso à coleção `estandes` no Cloud Firestore.
class EstandeRepositorio {
  EstandeRepositorio(FirebaseFirestore db) : _colecao = db.collection(colecao);

  static const colecao = 'estandes';

  final CollectionReference<Map<String, dynamic>> _colecao;

  /// Estandes ativos, ordenados por nome (consulta permitida ao visitante).
  Stream<List<Estande>> observarAtivos() => _colecao
      .where('ativo', isEqualTo: true)
      .snapshots()
      .map(_ordenados);

  /// Todos os estandes (somente administradores).
  Stream<List<Estande>> observarTodos() => _colecao.snapshots().map(_ordenados);

  Future<Estande?> buscar(String id) async {
    final doc = await _colecao.doc(id).get();
    final dados = doc.data();
    return dados == null ? null : Estande.fromMap(doc.id, dados);
  }

  /// Cria o estande com ID automático do Firestore e o retorna.
  Future<String> criar({
    required String nome,
    required String descricao,
    required String localizacao,
    bool ativo = true,
  }) async {
    final doc = _colecao.doc();
    final estande = Estande(
      id: doc.id,
      nome: nome,
      descricao: descricao,
      localizacao: localizacao,
      ativo: ativo,
    );
    await doc.set(estande.toMap());
    return doc.id;
  }

  Future<void> atualizar(Estande estande) =>
      _colecao.doc(estande.id).update(estande.toMap());

  static List<Estande> _ordenados(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map((d) => Estande.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }
}
