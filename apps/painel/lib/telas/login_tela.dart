import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../acesso_admin.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key, required this.acesso});

  final AcessoAdmin acesso;

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _enviando = false;
  String? _erro;

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await widget.acesso.entrar(_email.text, _senha.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = mensagemErroLogin(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Painel da organização',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Informe o e-mail' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _senha,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Informe a senha' : null,
                      onFieldSubmitted: (_) => _entrar(),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _erro!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _enviando ? null : _entrar,
                      child: Text(_enviando ? 'Entrando...' : 'Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
