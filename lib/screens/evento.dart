import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nome_do_projeto/colors/index.dart';
import 'package:nome_do_projeto/components/baseScaffold.dart';
import 'package:nome_do_projeto/components/button.dart';
import 'package:nome_do_projeto/screens/editar_evento.dart';

class EventPage extends StatefulWidget {
  final String eventoId;

  const EventPage({required this.eventoId});

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  int _selectedIndex = 0;
  late Future<DocumentSnapshot> _eventoFuture;

  @override
  void initState() {
    super.initState();
    _carregarEvento();
  }

  void _carregarEvento() {
    _eventoFuture =
        FirebaseFirestore.instance
            .collection('eventos')
            .doc(widget.eventoId)
            .get();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _confirmarExclusao() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Excluir evento'),
            content: Text('Tem certeza que deseja excluir este evento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('eventos')
                      .doc(widget.eventoId)
                      .delete();

                  Navigator.pop(context);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Evento excluído com sucesso')),
                  );
                },
                child: Text('Excluir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _registrarParticipacao(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String nomeUsuario = user.displayName ?? '';

    if (nomeUsuario.isEmpty) {
      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();

      if (usuarioDoc.exists) {
        nomeUsuario = usuarioDoc.data()?['nome'] ?? '-';
      } else {
        nomeUsuario = '-';
      }
    }

    final novoParticipante = {'uid': user.uid, 'nome': nomeUsuario};

    final docRef = FirebaseFirestore.instance
        .collection('eventos')
        .doc(widget.eventoId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) return;

    final participantes = List<Map<String, dynamic>>.from(
      docSnapshot.data()!['participantes'] ?? [],
    );

    final jaParticipa = participantes.any((p) => p['uid'] == user.uid);

    if (!jaParticipa) {
      participantes.add(novoParticipante);
      await docRef.update({'participantes': participantes});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Participação confirmada!")));
      _carregarEvento();
      Navigator.pop(context);
      setState(() {});
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Você já está participando.")));
    }
  }

  Widget _buildDetalhes(Map<String, dynamic> data) {
    final titulo = data['nomeEvento'] ?? 'Sem título';
    final dataHora = (data['dataHora'] as Timestamp).toDate();
    final local = data['local'] ?? 'Sem local';
    final modalidade = data['modalidade'] ?? 'Indefinido';
    final categoria = data['categoria'] ?? 'Indefinido';
    final descricao = data['descricao'] ?? 'Sem descrição';
    final participantes = List<Map<String, dynamic>>.from(
      data['participantes'] ?? [],
    );

    final user = FirebaseAuth.instance.currentUser;
    final isOwner =
        user != null &&
        participantes.isNotEmpty &&
        participantes[0]['uid'] == user.uid;

    final diasSemana = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
    ];

    final dataFormatada =
        '${diasSemana[dataHora.weekday % 7]}, ${dataHora.day}/${dataHora.month}/${dataHora.year} às ${dataHora.hour.toString().padLeft(2, '0')}h';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Data: $dataFormatada",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text("Local: $local", style: TextStyle(fontSize: 16)),
          SizedBox(height: 4),
          Text("Modalidade: $modalidade", style: TextStyle(fontSize: 16)),
          SizedBox(height: 4),
          Text("Categoria: $categoria", style: TextStyle(fontSize: 16)),
          SizedBox(height: 4),
          Text("Descrição: $descricao", style: TextStyle(fontSize: 16)),
          SizedBox(height: 4),
          Text(
            "Confirmados: ${participantes.length}",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 32),
          Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  child: RoundedButton(
                    label: 'Participar',
                    onPressed: () => _registrarParticipacao(data),
                  ),
                ),
              ),
              if (isOwner) ...[
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    child: RoundedButton(
                      label: 'Editar Evento',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EditarEventoPage(
                                  eventoId: widget.eventoId,
                                  usuarioId: user.uid,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    child: RoundedButton(
                      label: 'Excluir Evento',
                      onPressed: _confirmarExclusao,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantes(Map<String, dynamic> data) {
    final participantes = List<Map<String, dynamic>>.from(
      data['participantes'] ?? [],
    );

    if (participantes.isEmpty) {
      return Center(child: Text('Nenhum participante ainda.'));
    }

    return ListView.builder(
      itemCount: participantes.length,
      itemBuilder: (context, index) {
        final participante = participantes[index];
        return ListTile(
          tileColor: index.isEven ? Colors.white : Color(colors.secondary),
          leading: Icon(Icons.person),
          title: Text(participante['nome'] ?? 'Sem nome'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _eventoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return BaseScaffold(
            title: "Carregando...",
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return BaseScaffold(
            title: "Erro",
            body: Center(child: Text("Evento não encontrado")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return BaseScaffold(
          title: "Evento",
          body:
              _selectedIndex == 0
                  ? _buildDetalhes(data)
                  : _buildParticipantes(data),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Color(colors.secondary),
            selectedItemColor: Color(colors.primary),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.info),
                label: 'Detalhes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Participantes',
              ),
            ],
          ),
        );
      },
    );
  }
}
