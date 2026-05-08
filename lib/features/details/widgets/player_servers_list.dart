import 'package:flutter/material.dart';

class PlayerServersList extends StatelessWidget {
  final List<String> servers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const PlayerServersList({
    super.key,
    required this.servers,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Servers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final isSelected = selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text('Server ${index + 1}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onSelected(index);
                  },
                  selectedColor: Colors.blueAccent.withValues(alpha: 0.2),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blueAccent : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? Colors.blueAccent : Colors.transparent,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
