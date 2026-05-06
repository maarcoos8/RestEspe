import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'app_bottom_nav_bar.dart';
import '../screens/home_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Scaffold reutilizable que incluye la barra de navegación inferior en todas
/// las vistas principales. `currentIndex` controla la pestaña activa.
class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({
    super.key,
    required this.body,
    this.title,
    this.currentIndex = 1,
  });

  final Widget body;
  final String? title;
  final int currentIndex;

  void _onNavTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: index)),
    );
  }

  void _goToProfile(BuildContext context) {
    if (currentIndex == 2) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: title != null
          ? AppBar(
              backgroundColor: const Color(AppColors.white),
              surfaceTintColor: const Color(AppColors.white),
              elevation: 0,
              scrolledUnderElevation: 0,
              title: InkWell(
                onTap: () => _onNavTap(context, 1),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(AppColors.primaryOrange),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              centerTitle: true,
              leadingWidth: 56,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0x1A000000),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(AppColors.darkText)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkResponse(
                    onTap: () => _goToProfile(context),
                    radius: 24,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(AppColors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(AppColors.primaryOrange),
                          width: 2,
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          final photoUrl = context.read<AuthProvider>().currentUser?.fotoPerfil;
                          if (photoUrl != null && photoUrl.isNotEmpty) {
                            return ClipOval(
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person_outline_rounded,
                                    color: Color(AppColors.darkText),
                                    size: 22,
                                  );
                                },
                              ),
                            );
                          }

                          return const Icon(
                            Icons.person_outline_rounded,
                            color: Color(AppColors.darkText),
                            size: 22,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: body,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        userRoleId: context.read<AuthProvider>().currentUser?.idRol,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }
}
