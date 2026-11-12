import 'package:circuito_comum/circuito_comum.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../rota_qr.dart';

/// Página de impressão do QR code de um estande (Ctrl+P no navegador).
class QrTela extends StatelessWidget {
  const QrTela({super.key, required this.rota});

  final RotaQr rota;

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(context).textTheme.headlineMedium;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Circuito de Descobertas', style: titulo),
              if (rota.nome.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(rota.nome, style: Theme.of(context).textTheme.titleLarge),
              ],
              const SizedBox(height: 24),
              QrCodigoEstande(estandeId: rota.estandeId, tamanho: 320),
              const SizedBox(height: 16),
              const Text('Leia com o app do visitante para registrar a visita'),
              const SizedBox(height: 8),
              SelectableText(
                'ID: ${rota.estandeId}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              const Text(
                'Para imprimir, use Ctrl+P (Cmd+P no Mac).',
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// QR gerado a partir do identificador do estande.
class QrCodigoEstande extends StatelessWidget {
  const QrCodigoEstande({
    super.key,
    required this.estandeId,
    this.tamanho = 240,
  });

  final String estandeId;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: QrEstande.codificar(estandeId),
      size: tamanho,
      backgroundColor: Colors.white,
    );
  }
}
