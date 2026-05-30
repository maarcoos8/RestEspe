import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../data/models/categoria_dieta_model.dart';
import '../data/models/search_models.dart';
import '../data/models/tipo_establecimiento_model.dart';
import '../data/services/admin_service.dart';

class MapFiltersSheet extends StatefulWidget {
  const MapFiltersSheet({super.key, required this.initialFilters});

  final RestaurantMapFilters initialFilters;

  @override
  State<MapFiltersSheet> createState() => _MapFiltersSheetState();
}

class _MapFiltersSheetState extends State<MapFiltersSheet> {
  late Set<int> _selectedDietIds;
  late Set<int> _selectedTypeIds;
  late bool _onlyVerified;
  double? _minimumRating;
  late Future<_MapFiltersOptions> _optionsFuture;
  bool _typesExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedDietIds = widget.initialFilters.selectedDietIds.toSet();
    _selectedTypeIds = widget.initialFilters.selectedTypeIds.toSet();
    _onlyVerified = widget.initialFilters.onlyVerified;
    _minimumRating = widget.initialFilters.minimumRating;
    _optionsFuture = _loadOptions();
  }

  Future<_MapFiltersOptions> _loadOptions() async {
    final results = await Future.wait([
      AdminService.getCategoriasDieta(),
      AdminService.getTiposEstablecimiento(),
    ]);

    return _MapFiltersOptions(
      dietas: results[0] as List<CategoriaDieta>,
      tipos: results[1] as List<TipoEstablecimiento>,
    );
  }

  void _applyRating(double rating) {
    setState(() {
      _minimumRating = rating;
    });
  }

  void _toggleDiet(int id) {
    setState(() {
      if (_selectedDietIds.contains(id)) {
        _selectedDietIds.remove(id);
      } else {
        _selectedDietIds.add(id);
      }
    });
  }

  void _toggleType(int id) {
    setState(() {
      if (_selectedTypeIds.contains(id)) {
        _selectedTypeIds.remove(id);
      } else {
        _selectedTypeIds.add(id);
      }
    });
  }

  RestaurantMapFilters _buildFilters() {
    final selectedDietIds = _selectedDietIds.toList()..sort();
    final selectedTypeIds = _selectedTypeIds.toList()..sort();

    return RestaurantMapFilters(
      selectedDietIds: selectedDietIds,
      selectedTypeIds: selectedTypeIds,
      onlyVerified: _onlyVerified,
      minimumRating: _minimumRating,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedDietIds.clear();
      _selectedTypeIds.clear();
      _onlyVerified = false;
      _minimumRating = null;
      _typesExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(AppColors.background),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: FutureBuilder<_MapFiltersOptions>(
              future: _optionsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        20 + bottomInset,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 24),
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 42,
                            color: Color(AppColors.errorRed),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No se pudieron cargar los filtros',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Inténtalo de nuevo en unos segundos.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(AppColors.lightText),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _optionsFuture = _loadOptions();
                              });
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(AppColors.primaryOrange),
                    ),
                  );
                }

                final options = snapshot.data!;

                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: [
                              _buildSectionTitle(
                                context,
                                'Dietas',
                                'Selecciona una o varias dietas.',
                              ),
                              const SizedBox(height: 12),
                              if (options.dietas.isEmpty)
                                Text(
                                  'No hay dietas disponibles.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(AppColors.lightText),
                                      ),
                                )
                              else
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: options.dietas
                                      .map((dieta) {
                                        final isSelected = _selectedDietIds
                                            .contains(dieta.idCategoria);
                                        return FilterChip(
                                          selected: isSelected,
                                          label: Text(dieta.nombreDieta),
                                          showCheckmark: false,
                                          onSelected: (_) =>
                                              _toggleDiet(dieta.idCategoria),
                                          selectedColor: _hexToColor(
                                            dieta.colorHex,
                                          ).withValues(alpha: 0.18),
                                          backgroundColor: const Color(
                                            AppColors.white,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? _hexToColor(dieta.colorHex)
                                                : const Color(0x1F000000),
                                          ),
                                          labelStyle: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: isSelected
                                                    ? _hexToColor(
                                                        dieta.colorHex,
                                                      )
                                                    : const Color(
                                                        AppColors.darkText,
                                                      ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        );
                                      })
                                      .toList(growable: false),
                                ),
                              const SizedBox(height: 24),
                              _buildSectionTitle(
                                context,
                                'Tipos de restaurantes',
                                'Se muestra como un desplegable porque puede haber muchos tipos.',
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(AppColors.white),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(AppColors.accentBeige),
                                  ),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: _typesExpanded,
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide.none,
                                  ),
                                  collapsedShape: const RoundedRectangleBorder(
                                    side: BorderSide.none,
                                  ),
                                  onExpansionChanged: (value) {
                                    setState(() {
                                      _typesExpanded = value;
                                    });
                                  },
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  title: Text(
                                    _selectedTypeIds.isEmpty
                                        ? 'Seleccionar tipo de restaurantes'
                                        : '${_selectedTypeIds.length} tipo(s) seleccionados',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                    _selectedTypeIds.isEmpty
                                        ? 'Sin filtros aplicados'
                                        : 'Toca para ver o cambiar la selección',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: const Color(
                                            AppColors.lightText,
                                          ),
                                        ),
                                  ),
                                  children: [
                                    if (options.tipos.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'No hay tipos disponibles.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: const Color(
                                                  AppColors.lightText,
                                                ),
                                              ),
                                        ),
                                      )
                                    else
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 260,
                                        ),
                                        child: Scrollbar(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: options.tipos.length,
                                            itemBuilder: (context, index) {
                                              final tipo = options.tipos[index];
                                              final isSelected =
                                                  _selectedTypeIds.contains(
                                                    tipo.idTipoEstablecimiento,
                                                  );
                                              return CheckboxListTile(
                                                contentPadding: EdgeInsets.zero,
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                dense: true,
                                                title: Text(
                                                  tipo.nombreCategoria,
                                                ),
                                                value: isSelected,
                                                onChanged: (_) => _toggleType(
                                                  tipo.idTipoEstablecimiento,
                                                ),
                                                fillColor:
                                                    WidgetStateProperty.resolveWith(
                                                      (states) {
                                                        if (states.contains(
                                                          WidgetState.selected,
                                                        )) {
                                                          return const Color(
                                                            AppColors
                                                                .primaryOrange,
                                                          );
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionTitle(
                                context,
                                'Verificados',
                                'Si se activa, solo aparecerán establecimientos verificados.',
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(AppColors.white),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(AppColors.accentBeige),
                                  ),
                                ),
                                child: SwitchListTile.adaptive(
                                  value: _onlyVerified,
                                  onChanged: (value) {
                                    setState(() {
                                      _onlyVerified = value;
                                    });
                                  },
                                  title: const Text('Verificados'),
                                  activeTrackColor: const Color(
                                    AppColors.primaryOrange,
                                  ),
                                  activeThumbColor: const Color(
                                    AppColors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionTitle(
                                context,
                                'Puntuación mínima',
                                'Usa estrellas para fijar una media mínima de reseñas.',
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(AppColors.white),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(AppColors.accentBeige),
                                  ),
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  18,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed: _minimumRating == null
                                            ? null
                                            : () => setState(() {
                                                _minimumRating = null;
                                              }),
                                        child: const Text('Sin mínimo'),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    _RatingSelector(
                                      selectedRating: _minimumRating,
                                      onChanged: _applyRating,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _minimumRating == null
                                          ? 'Se mostrarán todos los establecimientos por puntuación.'
                                          : 'Se mostrarán establecimientos con media igual o superior a ${_minimumRating!.toStringAsFixed(_minimumRating! % 1 == 0 ? 0 : 1)} ⭐',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: const Color(
                                              AppColors.lightText,
                                            ),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _clearFilters,
                                child: const Text('Limpiar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pop(_buildFilters());
                                },
                                child: const Text('Aplicar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Filtros del mapa',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(AppColors.primaryOrange),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Combina varios apartados a la vez para refinar la búsqueda.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(AppColors.lightText),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(AppColors.lightText),
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    final cleanedHex = hexString.replaceFirst('#', '').trim();

    if (cleanedHex.length == 6) {
      buffer.write('FF');
    }

    buffer.write(cleanedHex);

    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(AppColors.primaryOrange);
    }
  }
}

class _MapFiltersOptions {
  const _MapFiltersOptions({required this.dietas, required this.tipos});

  final List<CategoriaDieta> dietas;
  final List<TipoEstablecimiento> tipos;
}

class _RatingSelector extends StatelessWidget {
  const _RatingSelector({
    required this.selectedRating,
    required this.onChanged,
  });

  final double? selectedRating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveRating = selectedRating ?? 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            const double width = 40.0;
            final dx = details.localPosition.dx;
            final isHalf = dx < (width / 2);
            final newRating = isHalf ? (starIndex - 0.5) : starIndex.toDouble();
            onChanged(newRating);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Icon(
                  effectiveRating >= starIndex
                      ? Icons.star
                      : effectiveRating >= (starIndex - 0.5)
                      ? Icons.star_half
                      : Icons.star_outline,
                  size: 32,
                  color: effectiveRating >= (starIndex - 0.5)
                      ? const Color(AppColors.primaryOrange)
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
