import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(context) {
    return Column(
      children: [
        ProfileItems(title: 'edit profile', icon: Icons.edit),
        ProfileItems(title: 'signin', icon: Icons.input_rounded),
        ProfileItems(title: 'signout', icon: Icons.reset_tv_rounded),
      ],
    );
  }
}

class ProfileItems extends StatelessWidget {
  final String title;
  final IconData icon;
  const ProfileItems({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        // Handle item tap
      },
    );
  }
}
