import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';

class ManagerProfileScreen extends ConsumerWidget {
  const ManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Manager Profile'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(authRepositoryProvider).signOut();
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
