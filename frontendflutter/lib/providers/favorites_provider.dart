import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../data/models/auth_models.dart';
import '../data/models/restaurant_detail_model.dart';
import '../data/services/favorite_service.dart';
import '../data/services/restaurant_detail_service.dart';

/// Provider para gestionar el estado de favoritos del usuario autenticado.
class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({
    FavoriteService? favoriteService,
    RestaurantDetailService? restaurantDetailService,
  })  : _favoriteService = favoriteService ?? FavoriteService(),
        _restaurantDetailService = restaurantDetailService ?? RestaurantDetailService();

  final FavoriteService _favoriteService;
  final RestaurantDetailService _restaurantDetailService;

  int? _currentUserId;
  bool _isLoading = false;
  String? _errorMessage;
  final Set<int> _favoriteIds = <int>{};
  final List<RestaurantDetail> _favoriteRestaurants = <RestaurantDetail>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RestaurantDetail> get favoriteRestaurants => List.unmodifiable(_favoriteRestaurants);

  bool isFavorite(int establishmentId) => _favoriteIds.contains(establishmentId);

  Future<void> syncUser(GoogleUserProfile? user) async {
    final nextUserId = user?.idUsuario;
    if (_currentUserId == nextUserId) {
      return;
    }

    _currentUserId = nextUserId;
    _favoriteIds.clear();
    _favoriteRestaurants.clear();

    if (nextUserId == null) {
      _notifyListenersAfterBuild();
      return;
    }

    await loadFavorites();
  }

  Future<void> loadFavorites() async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final favoriteSummaries = await _favoriteService.getFavoritesByUser(userId);
      _favoriteIds
        ..clear()
        ..addAll(favoriteSummaries.map((favorite) => favorite.idEstablecimiento));

      final detailFutures = favoriteSummaries
          .map((favorite) => _restaurantDetailService.getRestaurantDetail(favorite.idEstablecimiento))
          .toList();
      final details = await Future.wait(detailFutures);
      _favoriteRestaurants
        ..clear()
        ..addAll(details.whereType<RestaurantDetail>());
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleFavorite({required int establishmentId}) async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    if (isFavorite(establishmentId)) {
      await _favoriteService.removeFavorite(userId: userId, establishmentId: establishmentId);
      _favoriteIds.remove(establishmentId);
      _favoriteRestaurants.removeWhere((restaurant) => restaurant.idEstablecimiento == establishmentId);
      _notifyListenersAfterBuild();
      return;
    }

    await _favoriteService.addFavorite(userId: userId, establishmentId: establishmentId);
    _favoriteIds.add(establishmentId);
    final detail = await _restaurantDetailService.getRestaurantDetail(establishmentId);
    if (detail != null) {
      _favoriteRestaurants.insert(0, detail);
    }
    _notifyListenersAfterBuild();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notifyListenersAfterBuild();
  }

  void _notifyListenersAfterBuild() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _favoriteService.dispose();
    super.dispose();
  }
}
