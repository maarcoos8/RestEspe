import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../widgets/scaffold_with_nav.dart';

/// Pantalla de administración de establecimientos (superadmin).
class AdminEstablishmentsScreen extends StatelessWidget {
  const AdminEstablishmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'Administración de Establecimientos',
      currentIndex: 3,
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_rounded,
              size: 80,
              color: const Color(AppColors.primaryOrange),
            ),
            const SizedBox(height: 24),
            Text(
              'Administración de Establecimientos',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Gestiona los establecimientos de la aplicación',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(AppColors.lightText),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
