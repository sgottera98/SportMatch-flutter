import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nome_do_projeto/category/index.dart';
import 'package:nome_do_projeto/components/baseScaffold.dart';
import 'package:nome_do_projeto/components/button.dart';
import 'package:nome_do_projeto/components/dropdownField.dart';
import 'package:nome_do_projeto/components/popup.dart';
import 'package:nome_do_projeto/components/textField.dart';
import 'package:nome_do_projeto/screens/evento.dart';
import 'package:nome_do_projeto/sports/index.dart';

class CriarEventoPage extends StatefulWidget {
  @override
  _CriarEventoPageState createState() => _CriarEventoPageState();
}

class _CriarEventoPageState extends State<CriarEventoPage> {
  final _formKey = GlobalKey<FormState>();
  String categoria = '';
  String modalidade = '';
  DateTime dataHora = DateTime.now();
  final _dataHoraController = TextEditingController();

  final _nomeEventoController = TextEditingController();
  final _localController = TextEditingController();
  final _descricaoController = TextEditingController();

  @override
  void dispose() {
    _nomeEventoController.dispose();
    _localController.dispose();
    _descricaoController.dispose();
    _dataHoraController.dispose();
    super.dispose();
  }

  Future<void> _salvarEvento() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String nomeUsuario;

    final providers = user.providerData.map((p) => p.providerId);
    final isSocialLogin =
        providers.contains('google.com') || providers.contains('facebook.com');

    if (isSocialLogin) {
      nomeUsuario = user.displayName ?? 'Usuário';
    } else {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('nome')) {
        nomeUsuario = doc['nome'];
      } else {
        nomeUsuario = 'Usuário';
      }
    }

    final eventData = {
      'categoria': categoria,
      'modalidade': modalidade,
      'dataHora': Timestamp.fromDate(dataHora),
      'nomeEvento': _nomeEventoController.text.trim(),
      'local': _localController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'participantes': [
        {'uid': user.uid, 'nome': nomeUsuario},
      ],
      'createdAt': Timestamp.now(),
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('eventos')
          .add(eventData);

      final eventoId = docRef.id;

      DialogHelper.PopUp(
        context,
        'Cadastro concluído',
        'Evento criado com sucesso!',
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventPage(eventoId: eventoId)),
      );
    } catch (e) {
      DialogHelper.PopUp(
        context,
        'Erro',
        'Não foi possível salvar o evento: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Novo Evento",
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CustomTextField(
                label: "Nome do Evento",
                controller: _nomeEventoController,
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());

                  final pickedDate = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                    initialDate: dataHora,
                  );

                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(dataHora),
                    );

                    if (pickedTime != null) {
                      final selected = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );

                      setState(() {
                        dataHora = selected;
                        _dataHoraController.text =
                            '${selected.day}/${selected.month}/${selected.year} ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: "Data - Hora",
                    controller: _dataHoraController,
                    validator:
                        (val) =>
                            (val == null || val.isEmpty)
                                ? 'Selecione a data e hora'
                                : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: "Local",
                controller: _localController,
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              const SizedBox(height: 16),

              CustomDropdownField(
                label: "Modalidade",
                value: modalidade.isEmpty ? null : modalidade,
                items: esportesPopulares,
                onChanged: (val) => setState(() => modalidade = val ?? ''),
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'Selecione uma modalidade'
                            : null,
              ),
              const SizedBox(height: 16),

              CustomDropdownField(
                label: "Categoria",
                value: categoria.isEmpty ? null : categoria,
                items: categorias,
                onChanged: (val) => setState(() => categoria = val ?? ''),
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'Selecione uma categoria'
                            : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: "Descrição",
                controller: _descricaoController,
                height: 90,
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              const SizedBox(height: 36),

              FractionallySizedBox(
                widthFactor: 0.5,
                alignment: Alignment.centerRight,
                child: RoundedButton(
                  label: "Criar",
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _salvarEvento();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
