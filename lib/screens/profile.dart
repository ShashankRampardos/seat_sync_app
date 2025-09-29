import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seat_sync_v2/screens/auth/login.dart';
import 'package:seat_sync_v2/utils/utils.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(context) {
    return Column(
      children: [
        ProfileItems(
          title: 'edit profile (number,name,pic)',
          icon: Icons.edit,
          onTap: () {},
        ),
        ProfileItems(
          title: 'login',
          icon: Icons.input_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        ),
        ProfileItems(
          title: 'logout',
          icon: Icons.reset_tv_rounded,
          onTap: () {
            if (_auth.currentUser == null) {
              Utils.showToast('No user logged in');
              return;
            }
            _auth.signOut();
            Utils.showToast('Logged out successfully');
          },
        ),
      ],
    );
  }
}

class ProfileItems extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const ProfileItems({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
