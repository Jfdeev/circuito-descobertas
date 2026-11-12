import 'package:circuito_comum/circuito_comum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/estande_card.dart';

/// Estandes participantes da missão. Acompanha o Remote Config em tempo real:
/// se a missão for desligada com a tela aberta, avisa o encerramento.
class MissaoTela extends StatelessWidget {
  const MissaoTela({super.key, required this.estandes, required this.missao});

  final Stream<List<Estande>> estandes;
  final ValueListenable<ConfigMissao> missao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Missão surpresa')),
      body: StreamBuilder<List<Estande>>(
        stream: estandes,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ValueListenableBuilder<ConfigMissao>(
            valueListenable: missao,
            builder: (context, config, _) {
              final participantes = config.participantes(snapshot.data!);
              if (participantes.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'A missão foi encerrada pela organização.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Encontre estes estandes e leia o QR code de cada um '
                      'para registrar sua visita.',
                    ),
                  ),
                  for (final e in participantes)
                    EstandeCard(estande: e, destacado: true),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
