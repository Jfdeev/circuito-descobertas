import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../servicos/fluxo_checkin.dart';

/// Lê o QR code do estande pela câmera e devolve o resultado do check-in.
class ScannerTela extends StatefulWidget {
  const ScannerTela({super.key, required this.fluxo});

  final FluxoCheckin fluxo;

  @override
  State<ScannerTela> createState() => _ScannerTelaState();
}

class _ScannerTelaState extends State<ScannerTela> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _processando = false;

  Future<void> _aoDetectar(BarcodeCapture captura) async {
    if (_processando || captura.barcodes.isEmpty) return;
    setState(() => _processando = true);
    try {
      final resultado = await widget.fluxo.processar(
        captura.barcodes.first.rawValue,
      );
      if (mounted) Navigator.of(context).pop(resultado);
    } on Exception catch (e) {
      debugPrint('Falha no check-in: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível registrar. Verifique a conexão.'),
        ),
      );
      setState(() => _processando = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR do estande')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _aoDetectar),
          if (_processando)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Text(
              'Aponte a câmera para o QR code do estande',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
