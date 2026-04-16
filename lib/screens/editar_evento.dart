import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nome_do_projeto/category/index.dart';
import 'package:nome_do_projeto/components/button.dart';
import 'package:nome_do_projeto/components/dropdownField.dart';
import 'package:nome_do_projeto/components/textField.dart';
import 'package:nome_do_projeto/sports/index.dart';

class EditarEventoPage extends StatefulWidget {
  final String eventoId;
  final String usuarioId;

  const EditarEventoPage({
    Key? key,
    required this.eventoId,
    required this.usuarioId,
  }) : super(key: key);

  @override
  _EditarEventoPageState createState() => _EditarEventoPageState();
}

class _EditarEventoPageState extends State<EditarEventoPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _localController = TextEditingController();
  final TextEditingController _dataHoraController = TextEditingController();

  String _modalidade = 'Futebol';
  String _categoria = 'Masculino';

  DateTime? _dataHora;

  bool _isLoading = true;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _carregarEvento();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _localController.dispose();
    _dataHoraController.dispose();
    super.dispose();
  }

  Future<void> _carregarEvento() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('eventos')
            .doc(widget.eventoId)
            .get();

    final data = doc.data();

    if (data != null) {
      final participantes = List<Map<String, dynamic>>.from(
        data['participantes'] ?? [],
      );

      final timestamp = data['dataHora'] as Timestamp;
      final dataConvertida = timestamp.toDate();

      setState(() {
        _isOwner =
            participantes.isNotEmpty &&
            participantes[0]['uid'] == widget.usuarioId;

        _tituloController.text = data['nomeEvento'] ?? '';
        _descricaoController.text = data['descricao'] ?? '';
        _localController.text = data['local'] ?? '';

        final modalidadeFirestore = data['modalidade'] ?? 'Futebol';
        _modalidade =
            esportesPopulares.contains(modalidadeFirestore)
                ? modalidadeFirestore
                : esportesPopulares.first;

        _categoria = data['categoria'] ?? 'Masculino';

        _dataHora = dataConvertida;

        _dataHoraController.text =
            '${dataConvertida.day}/${dataConvertida.month}/${dataConvertida.year} '
            '${dataConvertida.hour.toString().padLeft(2, '0')}:'
            '${dataConvertida.minute.toString().padLeft(2, '0')}';

        _isLoading = false;
      });
    }
  }

  Future<void> _salvarEdicao() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance
        .collection('eventos')
        .doc(widget.eventoId)
        .update({
          'nomeEvento': _tituloController.text,
          'descricao': _descricaoController.text,
          'local': _localController.text,
          'modalidade': _modalidade,
          'categoria': _categoria,
          'dataHora': Timestamp.fromDate(_dataHora!),
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Evento atualizado com sucesso!')));

    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Editar Evento')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isOwner) {
      return Scaffold(
        appBar: AppBar(title: Text('Editar Evento')),
        body: Center(
          child: Text('Você não tem permissão para editar este evento'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Editar Evento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CustomTextField(
                label: 'Nome do Evento',
                controller: _tituloController,
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());

                  final pickedDate = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                    initialDate: _dataHora ?? DateTime.now(),
                  );

                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        _dataHora ?? DateTime.now(),
                      ),
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
                        _dataHora = selected;
                        _dataHoraController.text =
                            '${selected.day}/${selected.month}/${selected.year} '
                            '${pickedTime.hour.toString().padLeft(2, '0')}:'
                            '${pickedTime.minute.toString().padLeft(2, '0')}';
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
              SizedBox(height: 16),

              CustomTextField(
                label: 'Local',
                controller: _localController,
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              SizedBox(height: 16),

              CustomDropdownField(
                label: 'Modalidade',
                value: _modalidade.isEmpty ? null : _modalidade,
                items: esportesPopulares,
                onChanged: (val) {
                  setState(() {
                    _modalidade = val ?? '';
                  });
                },
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'Selecione uma modalidade'
                            : null,
              ),
              SizedBox(height: 16),

              CustomDropdownField(
                label: 'Categoria',
                value: _categoria,
                items: categorias,
                onChanged: (val) => setState(() => _categoria = val ?? ''),
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'Selecione uma categoria'
                            : null,
              ),
              SizedBox(height: 16),

              CustomTextField(
                label: 'Descrição',
                controller: _descricaoController,
                height: 90,
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              SizedBox(height: 36),

              FractionallySizedBox(
                widthFactor: 0.7,
                alignment: Alignment.centerRight,
                child: RoundedButton(
                  label: "Salvar alterações",
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _salvarEdicao();
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
