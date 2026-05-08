import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedUserCircle,
            size: 64,
            color: Colors.blueAccent,
          ),
          SizedBox(height: 16),
          Text(
            'Profile',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text('Manage your account', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
