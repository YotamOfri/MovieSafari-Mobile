import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedFilm02,
            size: 64,
            color: Colors.blueAccent,
          ),
          SizedBox(height: 16),
          Text(
            'Home',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(
            'Explore series, movies & TV shows',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
