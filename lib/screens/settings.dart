import 'package:flutter/material.dart';
import 'package:seat_sync_v2/widgets/prifile_item_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel Settings')),
      body: Center(
        child: Column(
          children: [
            ProfileItems(
              title: 'Change MCU\'s login credentials',
              icon: Icons.computer,
              onTap: () {},
            ),
            SizedBox(height: 10),
            ProfileItems(
              title: 'Change Wifi credentials',
              icon: Icons.wifi,
              onTap: () {},
            ),
            ProfileItems(
              title: 'Make seat paid/unpaid',
              icon: Icons.paid,
              onTap: () {},
            ),
            SizedBox(height: 10),
            ProfileItems(
              title: 'Make seat reserved',
              icon: Icons.star,
              onTap: () {},
            ),
            SizedBox(height: 10),
            ProfileItems(
              title: 'Make seat bolocked',
              icon: Icons.block_flipped,
              onTap: () {},
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
