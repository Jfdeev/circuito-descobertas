import 'package:circuito_comum/circuito_comum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../servicos/eventos_analytics.dart';
import '../servicos/fluxo_checkin.dart';
import '../widgets/estande_card.dart';
import 'missao_tela.dart';
import 'scanner_tela.dart';

/// Tela inicial: lista de estandes ativos, chamada da missão e check-in.
class InicioTela extends StatefulWidget {
  const InicioTela({
    super.key,
    required this.estandes,
    required this.missao,
    required this.eventos,
    required this.fluxo,
  });

  final EstandeRepositorio estandes;
  final ValueListenable<ConfigMissao> missao;
  final EventosAnalytics eventos;
  final FluxoCheckin fluxo;

  @override
  State<InicioTela> createState() => _InicioTelaState();
}

class _InicioTelaState extends State<InicioTela> {
  late final Stream<List<Estande>> _ativos = widget.estandes.observarAtivos();

  Future<void> _abrirMissao(List<Estande> participantes) async {
    await widget.eventos.registrarMissaoAberta(
      totalEstandes: participantes.length,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MissaoTela(estandes: _ativos, missao: widget.missao),
      ),
    );
  }

  Future<void> _fazerCheckin() async {
    final resultado = await Navigator.of(context).push<ResultadoCheckin>(
      MaterialPageRoute(builder: (_) => ScannerTela(fluxo: widget.fluxo)),
    );
    if (resultado == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          resultado.sucesso ? Icons.check_circle : Icons.info_outline,
          color: resultado.sucesso ? Colors.green : null,
          size: 48,
        ),
        title: Text(resultado.sucesso ? 'Visita registrada' : 'Atenção'),
        content: Text(mensagemCheckin(resultado)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Circuito de Descobertas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fazerCheckin,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Fazer check-in'),
      ),
      body: StreamBuilder<List<Estande>>(
        stream: _ativos,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _Aviso('Não foi possível carregar os estandes.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final estandes = snapshot.data!;
          return ValueListenableBuilder<ConfigMissao>(
            valueListenable: widget.missao,
            builder: (context, missao, _) {
              final participantes = missao.participantes(estandes);
              final destaques = participantes.map((e) => e.id).toSet();
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                children: [
                  if (participantes.isNotEmpty)
                    _ChamadaMissao(
                      total: participantes.length,
                      onAbrir: () => _abrirMissao(participantes),
                    ),
                  if (estandes.isEmpty)
                    const _Aviso('Nenhum estande ativo no momento.'),
                  for (final e in estandes)
                    EstandeCard(
                      estande: e,
                      destacado: destaques.contains(e.id),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ChamadaMissao extends StatelessWidget {
  const _ChamadaMissao({required this.total, required this.onAbrir});

  final int total;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      key: const Key('chamada-missao'),
      color: cores.tertiary,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Missão surpresa!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: cores.onTertiary),
            ),
            const SizedBox(height: 4),
            Text(
              'Visite os $total estandes destacados e faça check-in em cada um.',
              style: TextStyle(color: cores.onTertiary),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onAbrir,
              icon: const Icon(Icons.flag),
              label: const Text('Abrir missão'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(texto, textAlign: TextAlign.center)),
    );
  }
}
