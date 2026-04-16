import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nome_do_projeto/colors/index.dart';
import 'package:nome_do_projeto/components/eventCard.dart';
import 'package:nome_do_projeto/screens/cadastro_evento.dart';
import 'package:nome_do_projeto/components/menu.dart';
import 'package:nome_do_projeto/components/sportFilterBar.dart';
import 'package:nome_do_projeto/sports/index.dart';

final List<String> sports = ['Todos', ...esportesPopulares];

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String _selectedSport = 'Todos';
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(title: Text('Eventos Agendados')),
      body: Column(
        children: [
          SizedBox(height: 10),

          SportFilterBar(
            sports: sports,
            selectedSport: _selectedSport,
            onSelected: (sport) {
              setState(() {
                _selectedSport = sport;
              });
            },
          ),

          SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('eventos')
                      .orderBy('dataHora')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Nenhum evento encontrado'));
                }

                final eventos = snapshot.data!.docs;
                final eventosFiltrados =
                    eventos.where((evento) {
                      final data = evento.data() as Map<String, dynamic>;

                      final titulo =
                          (data['titulo'] ?? '').toString().toLowerCase();

                      final modalidade = (data['modalidade'] ?? '').toString();

                      final matchesSearch = titulo.contains(
                        _searchText.toLowerCase(),
                      );

                      final matchesSport =
                          _selectedSport == 'Todos' ||
                          modalidade == _selectedSport;

                      return matchesSearch && matchesSport;
                    }).toList();

                if (eventosFiltrados.isEmpty) {
                  return Center(child: Text('Nenhum evento encontrado'));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: eventosFiltrados.length,
                  itemBuilder: (context, index) {
                    final evento = eventosFiltrados[index];

                    return EventCard(
                      backgroundColor:
                          index.isEven ? Color(colors.secondary) : Colors.white,
                      eventoId: evento.id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CriarEventoPage()),
            ),
        backgroundColor: Color(colors.primary),
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
