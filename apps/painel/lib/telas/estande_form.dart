import 'package:circuito_comum/circuito_comum.dart';
import 'package:flutter/material.dart';

/// Diálogo de cadastro/edição. Retorna o estande preenchido ou `null`.
/// No cadastro, o `id` retornado é vazio (o Firestore gera o ID).
Future<Estande?> mostrarEstandeForm(BuildContext context, {Estande? atual}) {
  return showDialog<Estande>(
    context: context,
    builder: (_) => _EstandeForm(atual: atual),
  );
}

class _EstandeForm extends StatefulWidget {
  const _EstandeForm({this.atual});

  final Estande? atual;

  @override
  State<_EstandeForm> createState() => _EstandeFormState();
}

class _EstandeFormState extends State<_EstandeForm> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.atual?.nome);
  late final _descricao = TextEditingController(text: widget.atual?.descricao);
  late final _localizacao = TextEditingController(
    text: widget.atual?.localizacao,
  );
  late bool _ativo = widget.atual?.ativo ?? true;

  static String? _obrigatorio(String? valor) =>
      (valor ?? '').trim().isEmpty ? 'Campo obrigatório' : null;

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      Estande(
        id: widget.atual?.id ?? '',
        nome: _nome.text.trim(),
        descricao: _descricao.text.trim(),
        localizacao: _localizacao.text.trim(),
        ativo: _ativo,
      ),
    );
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _localizacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.atual == null ? 'Novo estande' : 'Editar estande'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: _obrigatorio,
                maxLength: 60,
              ),
              TextFormField(
                controller: _descricao,
                decoration: const InputDecoration(
                  labelText: 'Descrição breve',
                ),
                validator: _obrigatorio,
                maxLength: 160,
                maxLines: 2,
              ),
              TextFormField(
                controller: _localizacao,
                decoration: const InputDecoration(labelText: 'Localização'),
                validator: _obrigatorio,
                maxLength: 60,
              ),
              SwitchListTile(
                title: const Text('Ativo'),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
