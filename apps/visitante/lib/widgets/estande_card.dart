import 'package:circuito_comum/circuito_comum.dart';
import 'package:flutter/material.dart';

class EstandeCard extends StatelessWidget {
  const EstandeCard({super.key, required this.estande, this.destacado = false});

  final Estande estande;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      color: destacado ? cores.tertiaryContainer : null,
      shape: destacado
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cores.tertiary, width: 2),
            )
          : null,
      child: ListTile(
        leading: Icon(
          destacado ? Icons.star : Icons.storefront_outlined,
          color: destacado ? cores.tertiary : null,
        ),
        title: Text(estande.nome),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(estande.descricao),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16),
                const SizedBox(width: 4),
                Expanded(child: Text(estande.localizacao)),
              ],
            ),
          ],
        ),
        trailing: destacado
            ? Chip(
                label: const Text('Missão'),
                backgroundColor: cores.tertiary,
                labelStyle: TextStyle(color: cores.onTertiary),
              )
            : null,
        isThreeLine: true,
      ),
    );
  }
}
