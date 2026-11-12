import 'package:circuito_comum/circuito_comum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../rota_qr.dart';
import 'estande_form.dart';
import 'qr_tela.dart';

/// Estandes fictícios para demonstrar o circuito.
const estandesExemplo = [
  (
    nome: 'Robótica Amazônica',
    descricao: 'Robôs que monitoram a qualidade da água dos rios.',
    localizacao: 'Corredor A, estande 03',
  ),
  (
    nome: 'Açaí Tech',
    descricao: 'Rastreamento da cadeia do açaí com IoT.',
    localizacao: 'Corredor B, estande 12',
  ),
  (
    nome: 'Floresta em Jogo',
    descricao: 'Jogo educativo sobre a biodiversidade amazônica.',
    localizacao: 'Corredor C, estande 21',
  ),
];

class PainelTela extends StatefulWidget {
  const PainelTela({
    super.key,
    required this.estandes,
    required this.checkins,
    required this.emailAdmin,
    required this.onSair,
    required this.abrirEmNovaAba,
  });

  final EstandeRepositorio estandes;
  final CheckinRepositorio checkins;
  final String emailAdmin;
  final VoidCallback onSair;
  final Future<void> Function(RotaQr rota) abrirEmNovaAba;

  @override
  State<PainelTela> createState() => _PainelTelaState();
}

class _PainelTelaState extends State<PainelTela> {
  late final Stream<List<Estande>> _estandes = widget.estandes.observarTodos();
  late final Stream<Map<String, int>> _totais = widget.checkins
      .observarTotais();

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await acao();
      mensageiro.showSnackBar(SnackBar(content: Text(sucesso)));
    } on Exception catch (e) {
      mensageiro.showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _novo() async {
    final e = await mostrarEstandeForm(context);
    if (e == null) return;
    await _executar(
      () => widget.estandes.criar(
        nome: e.nome,
        descricao: e.descricao,
        localizacao: e.localizacao,
        ativo: e.ativo,
      ),
      'Estande "${e.nome}" cadastrado.',
    );
  }

  Future<void> _editar(Estande atual) async {
    final e = await mostrarEstandeForm(context, atual: atual);
    if (e == null) return;
    await _executar(
      () => widget.estandes.atualizar(e),
      'Estande "${e.nome}" atualizado.',
    );
  }

  Future<void> _alternarAtivo(Estande e, bool ativo) => _executar(
    () => widget.estandes.atualizar(e.copyWith(ativo: ativo)),
    '"${e.nome}" ${ativo ? 'ativado' : 'desativado'}.',
  );

  Future<void> _criarExemplos() => _executar(() async {
    for (final e in estandesExemplo) {
      await widget.estandes.criar(
        nome: e.nome,
        descricao: e.descricao,
        localizacao: e.localizacao,
      );
    }
  }, 'Estandes de exemplo cadastrados.');

  void _copiarId(Estande e) {
    Clipboard.setData(ClipboardData(text: e.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ID de "${e.nome}" copiado: ${e.id}')),
    );
  }

  void _mostrarQr(Estande e) {
    final rota = RotaQr(estandeId: e.id, nome: e.nome);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(e.nome),
        // Tamanho fixo: o QrImageView usa LayoutBuilder, que não suporta o
        // cálculo de dimensões intrínsecas feito pelo AlertDialog.
        content: SizedBox(
          width: 260,
          height: 290,
          child: Column(
            children: [
              QrCodigoEstande(estandeId: e.id),
              SelectableText('ID: ${e.id}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          FilledButton.icon(
            onPressed: () => widget.abrirEmNovaAba(rota),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir para imprimir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circuito de Descobertas — Organização'),
        actions: [
          Center(child: Text(widget.emailAdmin)),
          IconButton(
            tooltip: 'Sair',
            onPressed: widget.onSair,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novo,
        icon: const Icon(Icons.add),
        label: const Text('Novo estande'),
      ),
      body: StreamBuilder<List<Estande>>(
        stream: _estandes,
        builder: (context, estandesSnap) => StreamBuilder<Map<String, int>>(
          stream: _totais,
          builder: (context, totaisSnap) {
            if (estandesSnap.hasError || totaisSnap.hasError) {
              return Center(
                child: Text(
                  'Erro ao ler o Firestore: '
                  '${estandesSnap.error ?? totaisSnap.error}',
                ),
              );
            }
            if (!estandesSnap.hasData || !totaisSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _conteudo(estandesSnap.data!, totaisSnap.data!);
          },
        ),
      ),
    );
  }

  Widget _conteudo(List<Estande> estandes, Map<String, int> totais) {
    final totalGeral = totais.values.fold(0, (a, b) => a + b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Wrap(
          spacing: 12,
          children: [
            Chip(label: Text('${estandes.length} estandes')),
            Chip(
              key: const Key('total-geral'),
              label: Text('$totalGeral check-ins confirmados'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (estandes.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('Nenhum estande cadastrado.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _criarExemplos,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Criar 3 estandes de exemplo'),
                  ),
                ],
              ),
            ),
          ),
        for (final e in estandes)
          _LinhaEstande(
            estande: e,
            total: totais[e.id] ?? 0,
            onAtivo: (v) => _alternarAtivo(e, v),
            onEditar: () => _editar(e),
            onQr: () => _mostrarQr(e),
            onCopiarId: () => _copiarId(e),
          ),
      ],
    );
  }
}

class _LinhaEstande extends StatelessWidget {
  const _LinhaEstande({
    required this.estande,
    required this.total,
    required this.onAtivo,
    required this.onEditar,
    required this.onQr,
    required this.onCopiarId,
  });

  final Estande estande;
  final int total;
  final ValueChanged<bool> onAtivo;
  final VoidCallback onEditar;
  final VoidCallback onQr;
  final VoidCallback onCopiarId;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      key: Key('estande-${estande.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  '$total',
                  key: Key('total-${estande.id}'),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: cores.primary),
                ),
                const Text('check-ins'),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estande.nome,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(estande.descricao),
                  Text('📍 ${estande.localizacao}'),
                  InkWell(
                    onTap: onCopiarId,
                    child: Text(
                      'ID: ${estande.id}  (copiar)',
                      style: TextStyle(color: cores.outline, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(value: estande.ativo, onChanged: onAtivo),
                Text(estande.ativo ? 'Ativo' : 'Inativo'),
              ],
            ),
            IconButton(
              tooltip: 'QR code',
              onPressed: onQr,
              icon: const Icon(Icons.qr_code_2),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: onEditar,
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
      ),
    );
  }
}
