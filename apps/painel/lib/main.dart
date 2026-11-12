import 'package:circuito_comum/circuito_comum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'acesso_admin.dart';
import 'firebase_options.dart';
import 'rota_qr.dart';
import 'telas/login_tela.dart';
import 'telas/painel_tela.dart';
import 'telas/qr_tela.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (e) {
    runApp(PainelApp(inicio: (_) => _Mensagem('${e.message}')));
    return;
  }

  final db = FirebaseFirestore.instance;
  final acesso = AcessoAdmin(auth: FirebaseAuth.instance, db: db);
  runApp(
    PainelApp(
      inicio: (_) => PortaoAdmin(
        acesso: acesso,
        painel: (usuario) => PainelTela(
          estandes: EstandeRepositorio(db),
          checkins: CheckinRepositorio(db),
          emailAdmin: usuario.email ?? '',
          onSair: acesso.sair,
          abrirEmNovaAba: _abrirEmNovaAba,
        ),
      ),
    ),
  );
}

Future<void> _abrirEmNovaAba(RotaQr rota) async {
  final url = Uri.base.replace(fragment: rota.caminho);
  await launchUrl(url, webOnlyWindowName: '_blank');
}

class PainelApp extends StatelessWidget {
  const PainelApp({super.key, required this.inicio});

  final WidgetBuilder inicio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circuito de Descobertas — Painel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
      ),
      onGenerateRoute: (settings) {
        final rotaQr = RotaQr.interpretar(settings.name);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: rotaQr == null ? inicio : (_) => QrTela(rota: rotaQr),
        );
      },
    );
  }
}

/// Mostra o login, o painel ou o aviso de acesso negado.
class PortaoAdmin extends StatelessWidget {
  const PortaoAdmin({super.key, required this.acesso, required this.painel});

  final AcessoAdmin acesso;
  final Widget Function(User usuario) painel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: acesso.usuario,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Carregando();
        }
        final usuario = snapshot.data;
        if (usuario == null) return LoginTela(acesso: acesso);
        return FutureBuilder<bool>(
          key: ValueKey(usuario.uid),
          future: acesso.ehAdmin(usuario.uid),
          builder: (context, admin) {
            if (!admin.hasData) return const _Carregando();
            if (admin.data!) return painel(usuario);
            return _Mensagem(
              'A conta ${usuario.email ?? usuario.uid} não é administradora.',
              acao: TextButton(
                onPressed: acesso.sair,
                child: const Text('Sair'),
              ),
            );
          },
        );
      },
    );
  }
}

class _Carregando extends StatelessWidget {
  const _Carregando();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Mensagem extends StatelessWidget {
  const _Mensagem(this.texto, {this.acao});

  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(texto, textAlign: TextAlign.center),
            ),
            ?acao,
          ],
        ),
      ),
    );
  }
}
