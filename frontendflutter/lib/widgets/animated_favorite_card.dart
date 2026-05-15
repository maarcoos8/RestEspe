import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/restaurant_detail_model.dart';
import '../providers/favorites_provider.dart';
import 'restaurant_card_widget.dart';
import '../screens/restaurant_detail_screen.dart';

/// Widget que anima la salida cuando un favorito es removido de la lista.
class AnimatedFavoriteCard extends StatefulWidget {
  const AnimatedFavoriteCard({super.key, required this.restaurant});

  final RestaurantDetail restaurant;

  @override
  State<AnimatedFavoriteCard> createState() => _AnimatedFavoriteCardState();
}

class _AnimatedFavoriteCardState extends State<AnimatedFavoriteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        final isFavorite = favoritesProvider.isFavorite(
          widget.restaurant.idEstablecimiento,
        );

        // Si el item fue removido de favoritos, inicia la animación de salida
        if (!isFavorite && !_isRemoving) {
          _isRemoving = true;
          _animationController.forward();
        }

        // No renderiza si la animación terminó y el item está removido
        if (!isFavorite &&
            _animationController.status == AnimationStatus.completed) {
          return SizedBox.shrink();
        }

        return FadeTransition(
          opacity: _isRemoving
              ? Tween<double>(
                  begin: 1.0,
                  end: 0.0,
                ).animate(_animationController)
              : const AlwaysStoppedAnimation(1.0),
          child: ScaleTransition(
            scale: _isRemoving
                ? Tween<double>(
                    begin: 1.0,
                    end: 0.95,
                  ).animate(_animationController)
                : const AlwaysStoppedAnimation(1.0),
            child: RestaurantCardWidget(
              restaurant: widget.restaurant,
              compact: true,
              onCardTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        RestaurantDetailScreen(restaurant: widget.restaurant),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
