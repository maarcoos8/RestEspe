import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/favorites_provider.dart';

/// Widget para el botón de favorito con animación.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.establishmentId,
    this.size = 28,
  });

  final int establishmentId;
  final double size;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap(FavoritesProvider favoritesProvider) async {
    await favoritesProvider.toggleFavorite(
      establishmentId: widget.establishmentId,
    );
    // Animar el corazón
    await _animationController.forward();
    await _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        final isFavorite = favoritesProvider.isFavorite(widget.establishmentId);
        
        return ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: () => _onTap(favoritesProvider),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: const Color(AppColors.primaryOrange),
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}
