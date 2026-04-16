import 'package:flutter/material.dart';
import 'package:nome_do_projeto/colors/index.dart';

class SportFilterBar extends StatelessWidget {
  final List<String> sports;
  final String selectedSport;
  final Function(String) onSelected;

  const SportFilterBar({
    Key? key,
    required this.sports,
    required this.selectedSport,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sports.length,
        itemBuilder: (context, index) {
          final sport = sports[index];
          final isSelected = sport == selectedSport;

          return GestureDetector(
            onTap: () => onSelected(sport),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Color(colors.primary)
                        : Color(colors.secondary),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  sport,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
