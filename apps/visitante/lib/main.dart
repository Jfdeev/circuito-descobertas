import 'package:circuito_comum/circuito_comum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'servicos/eventos_analytics.dart';
import 'servicos/fluxo_checkin.dart';
import 'servicos/missao_remota.dart';
import 'telas/inicio_tela.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (e) {
    runApp(VisitanteApp(home: MensagemTela('${e.message}')));
    return;
  }

  final String visitanteId;
  try {
    final auth = FirebaseAuth.instance;
    // Sessão anônima: identifica o visitante sem cadastro.
    visitanteId =
        auth.currentUser?.uid ?? (await auth.signInAnonymously()).user!.uid;
  } on FirebaseAuthException catch (e) {
    runApp(
      VisitanteApp(
        home: MensagemTela(
          'Não foi possível entrar como visitante (${e.code}). '
          'Verifique a conexão e reabra o app.',
        ),
      ),
    );
    return;
  }

  final db = FirebaseFirestore.instance;
  final estandes = EstandeRepositorio(db);
  final eventos = EventosAnalytics(FirebaseAnalytics.instance);
  final missao = MissaoRemota(FirebaseRemoteConfig.instance);
  await missao.iniciar();

  runApp(
    VisitanteApp(
      home: InicioTela(
        estandes: estandes,
        missao: missao.config,
        eventos: eventos,
        fluxo: FluxoCheckin(
          registro: RegistroCheckin(
            estandes: estandes,
            checkins: CheckinRepositorio(db),
          ),
          eventos: eventos,
          visitanteId: visitanteId,
        ),
      ),
    ),
  );
}

class VisitanteApp extends StatelessWidget {
  const VisitanteApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circuito de Descobertas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
      ),
      home: home,
    );
  }
}

/// Tela simples para estados em que o app não pode continuar.
class MensagemTela extends StatelessWidget {
  const MensagemTela(this.mensagem, {super.key});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(mensagem, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
