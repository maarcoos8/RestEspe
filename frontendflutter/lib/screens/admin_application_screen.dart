import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

import '../core/constants.dart';
import '../widgets/scaffold_with_nav.dart';
import '../data/models/categoria_dieta_model.dart';
import '../data/models/tipo_establecimiento_model.dart';
import '../data/services/admin_service.dart';

/// Pantalla de administración de la aplicación (superadmin).
class AdminApplicationScreen extends StatefulWidget {
  const AdminApplicationScreen({super.key});

  @override
  State<AdminApplicationScreen> createState() => _AdminApplicationScreenState();
}

class _AdminApplicationScreenState extends State<AdminApplicationScreen> {
  bool _isLoadingDietas = false;
  bool _isLoadingTipos = false;
  List<CategoriaDieta>? _categoriasDieta;
  List<TipoEstablecimiento>? _tiposEstablecimiento;
  String? _errorDietas;
  String? _errorTipos;
  // Track which expansion sections are open to style the title row
  final Set<String> _expandedSections = {};

  void _showErrorSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(AppColors.errorRed),
      ),
    );
  }

  String _formatApiError(Object error, String fallbackPrefix) {
    final message = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (message.contains('Ya existe')) {
      return message;
    }
    return '$fallbackPrefix: $message';
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'Administración de la Aplicación',
      currentIndex: 3,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección: Gestión de Dietas
            _buildExpansionTile(
              title: 'Gestión de Dietas',
              icon: Icons.restaurant_rounded,
              isLoading: _isLoadingDietas,
              error: _errorDietas,
              onExpanded: (expanded) async {
                if (expanded && _categoriasDieta == null) {
                  await _loadCategoriasDieta();
                }
              },
              items: _categoriasDieta != null
                  ? [
                      _AdminAddTile(
                        title: 'Añadir Dieta',
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final newValue = await _showEditNameDialog(
                            context,
                            title: 'Añadir dieta',
                            currentValue: '',
                          );

                          if (newValue == null) {
                            return;
                          }

                          try {
                            await AdminService.createCategoriaDieta(newValue);
                            await _loadCategoriasDieta();
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('"$newValue" ha sido creado'),
                                  backgroundColor: const Color(AppColors.successGreen),
                                ),
                              );
                            }
                          } catch (e) {
                            _showErrorSnackBar(_formatApiError(e, 'Error al crear dieta'));
                          }
                        },
                      ),
                      ..._categoriasDieta!.asMap().entries.map((entry) {
                        final dieta = entry.value;
                        final isLast = entry.key == _categoriasDieta!.length - 1;
                        return _AdminItemTile(
                          title: dieta.nombreDieta,
                          isLast: isLast,
                          colorHex: dieta.colorHex,
                          onColorChanged: (String newColor) async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await AdminService.updateCategoriaDieta(
                                dieta.idCategoria,
                                dieta.nombreDieta,
                                colorHex: newColor,
                              );
                              setState(() {
                                final index = _categoriasDieta!.indexWhere((d) => d.idCategoria == dieta.idCategoria);
                                if (index != -1) {
                                  _categoriasDieta![index] = CategoriaDieta(
                                    idCategoria: dieta.idCategoria,
                                    nombreDieta: dieta.nombreDieta,
                                    colorHex: newColor,
                                  );
                                }
                              });
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Color actualizado'),
                                    backgroundColor: const Color(AppColors.successGreen),
                                  ),
                                );
                              }
                            } catch (e) {
                              _showErrorSnackBar(_formatApiError(e, 'Error al actualizar color'));
                            }
                          },
                          onEdit: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final newValue = await _showEditNameDialog(
                              context,
                              title: 'Editar categoría de dieta',
                              currentValue: dieta.nombreDieta,
                            );

                            if (newValue == null) {
                              return;
                            }

                            try {
                              await AdminService.updateCategoriaDieta(
                                dieta.idCategoria,
                                newValue,
                                colorHex: dieta.colorHex,
                              );
                              setState(() {
                                final index = _categoriasDieta!.indexWhere((d) => d.idCategoria == dieta.idCategoria);
                                if (index != -1) {
                                  _categoriasDieta![index] = CategoriaDieta(
                                    idCategoria: dieta.idCategoria,
                                    nombreDieta: newValue,
                                    colorHex: dieta.colorHex,
                                  );
                                }
                              });
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('"$newValue" ha sido actualizado'),
                                    backgroundColor: const Color(AppColors.successGreen),
                                  ),
                                );
                              }
                            } catch (e) {
                              _showErrorSnackBar(_formatApiError(e, 'Error al actualizar dieta'));
                            }
                          },
                          onDelete: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await AdminService.deleteCategoriaDieta(dieta.idCategoria);
                              setState(() {
                                _categoriasDieta!.removeWhere((d) => d.idCategoria == dieta.idCategoria);
                              });

                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('"${dieta.nombreDieta}" ha sido eliminado'),
                                    backgroundColor: const Color(AppColors.successGreen),
                                  ),
                                );
                              }
                            } catch (e) {
                              _showErrorSnackBar(_formatApiError(e, 'Error al eliminar dieta'));
                            }
                          },
                        );
                      }),
                    ]
                  : [
                      _AdminAddTile(
                        title: 'Añadir Dieta',
                        onTap: () async {
                          final newValue = await _showEditNameDialog(
                            context,
                            title: 'Añadir dieta',
                            currentValue: '',
                          );

                          if (newValue == null) {
                            return;
                          }

                          try {
                            await AdminService.createCategoriaDieta(newValue);
                            await _loadCategoriasDieta();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"$newValue" ha sido creado'),
                                  backgroundColor: const Color(AppColors.successGreen),
                                ),
                              );
                            }
                          } catch (e) {
                            _showErrorSnackBar(_formatApiError(e, 'Error al crear dieta'));
                          }
                        },
                      ),
                    ],
            ),
            const SizedBox(height: 12),
            // Sección: Gestión de Tipos de Establecimientos
            _buildExpansionTile(
              title: 'Gestión de Tipos de Establecimientos',
              icon: Icons.store_rounded,
              isLoading: _isLoadingTipos,
              error: _errorTipos,
              onExpanded: (expanded) async {
                if (expanded && _tiposEstablecimiento == null) {
                  await _loadTiposEstablecimiento();
                }
              },
              items: _tiposEstablecimiento != null
                  ? [
                      _AdminAddTile(
                        title: 'Añadir Tipo de establecimiento',
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final newValue = await _showEditNameDialog(
                            context,
                            title: 'Añadir tipo de establecimiento',
                            currentValue: '',
                          );

                          if (newValue == null) {
                            return;
                          }

                          try {
                            await AdminService.createTipoEstablecimiento(newValue);
                            await _loadTiposEstablecimiento();
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('"$newValue" ha sido creado'),
                                  backgroundColor: const Color(AppColors.successGreen),
                                ),
                              );
                            }
                          } catch (e) {
                            _showErrorSnackBar(_formatApiError(e, 'Error al crear tipo de establecimiento'));
                          }
                        },
                      ),
                      ..._tiposEstablecimiento!.asMap().entries.map((entry) {
                        final tipo = entry.value;
                        final isLast = entry.key == _tiposEstablecimiento!.length - 1;
                        return _AdminItemTile(
                          title: tipo.nombreCategoria,
                          isLast: isLast,
                          onEdit: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final newValue = await _showEditNameDialog(
                              context,
                              title: 'Editar tipo de establecimiento',
                              currentValue: tipo.nombreCategoria,
                            );

                            if (newValue == null) {
                              return;
                            }

                            try {
                              await AdminService.updateTipoEstablecimiento(tipo.idTipoEstablecimiento, newValue);
                              setState(() {
                                final index = _tiposEstablecimiento!.indexWhere((t) => t.idTipoEstablecimiento == tipo.idTipoEstablecimiento);
                                if (index != -1) {
                                  _tiposEstablecimiento![index] = TipoEstablecimiento(
                                    idTipoEstablecimiento: tipo.idTipoEstablecimiento,
                                    nombreCategoria: newValue,
                                  );
                                }
                              });
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('"$newValue" ha sido actualizado'),
                                    backgroundColor: const Color(AppColors.successGreen),
                                  ),
                                );
                              }
                            } catch (e) {
                              _showErrorSnackBar(_formatApiError(e, 'Error al actualizar tipo de establecimiento'));
                            }
                          },
                          onDelete: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await AdminService.deleteTipoEstablecimiento(tipo.idTipoEstablecimiento);
                              setState(() {
                                _tiposEstablecimiento!.removeWhere((t) => t.idTipoEstablecimiento == tipo.idTipoEstablecimiento);
                              });

                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('"${tipo.nombreCategoria}" ha sido eliminado'),
                                    backgroundColor: const Color(AppColors.successGreen),
                                  ),
                                );
                              }
                            } catch (e) {
                              _showErrorSnackBar(_formatApiError(e, 'Error al eliminar tipo de establecimiento'));
                            }
                          },
                        );
                      }),
                    ]
                  : [
                      _AdminAddTile(
                        title: 'Añadir Tipo de establecimiento',
                        onTap: () async {
                          final newValue = await _showEditNameDialog(
                            context,
                            title: 'Añadir tipo de establecimiento',
                            currentValue: '',
                          );

                          if (newValue == null) {
                            return;
                          }

                          try {
                            await AdminService.createTipoEstablecimiento(newValue);
                            await _loadTiposEstablecimiento();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"$newValue" ha sido creado'),
                                  backgroundColor: const Color(AppColors.successGreen),
                                ),
                              );
                            }
                          } catch (e) {
                            _showErrorSnackBar(_formatApiError(e, 'Error al crear tipo de establecimiento'));
                          }
                        },
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCategoriasDieta() async {
    setState(() {
      _isLoadingDietas = true;
      _errorDietas = null;
    });

    try {
      final dietas = await AdminService.getCategoriasDieta();
      setState(() {
        _categoriasDieta = dietas;
        _isLoadingDietas = false;
      });
    } catch (e) {
      setState(() {
        _errorDietas = 'Error al cargar las dietas';
        _isLoadingDietas = false;
      });
    }
  }

  Future<void> _loadTiposEstablecimiento() async {
    setState(() {
      _isLoadingTipos = true;
      _errorTipos = null;
    });

    try {
      final tipos = await AdminService.getTiposEstablecimiento();
      setState(() {
        _tiposEstablecimiento = tipos;
        _isLoadingTipos = false;
      });
    } catch (e) {
      setState(() {
        _errorTipos = 'Error al cargar los tipos de establecimiento';
        _isLoadingTipos = false;
      });
    }
  }

  Future<String?> _showEditNameDialog(
    BuildContext context, {
    required String title,
    required String currentValue,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        String editedValue = currentValue;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: TextFormField(
                initialValue: currentValue,
                autofocus: true,
                onChanged: (value) {
                  editedValue = value;
                },
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(editedValue.trim()),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result.isEmpty) {
      if (mounted && result != null) {
        messenger.showSnackBar(const SnackBar(content: Text('El nombre no puede estar vacío')));
      }
      return null;
    }

    return result;
  }

  Widget _buildExpansionTile({
    required String title,
    required IconData icon,
    required bool isLoading,
    required String? error,
    required Function(bool) onExpanded,
    required List<Widget> items,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    return Material(
      color: const Color(AppColors.white),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: const Border.fromBorderSide(
            BorderSide(
              color: Color(0x1A000000),
              width: 1,
            ),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          // Remove default dividers that appear when expanding
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Builder(builder: (context) {
            final isExpanded = _expandedSections.contains(title);
            return ExpansionTile(
              onExpansionChanged: (expanded) {
                setState(() {
                  if (expanded) {
                    _expandedSections.add(title);
                  } else {
                    _expandedSections.remove(title);
                  }
                });
                onExpanded(expanded);
              },
              leading: Icon(icon, color: const Color(AppColors.primaryOrange)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: titleStyle?.copyWith(
                      color: isExpanded ? const Color(AppColors.primaryOrange) : null,
                    ),
                  ),
                  if (isExpanded)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Divider(
                        height: 2,
                        thickness: 2,
                        color: Color(AppColors.primaryOrange),
                      ),
                    ),
                ],
              ),
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )
              else if (error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                  ),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No hay datos disponibles',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(AppColors.lightText),
                        ),
                  ),
                )
                else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: () {
                      // Insert a subtle divider after the first item (typically the "Añadir ..." tile)
                      final List<Widget> children = [];
                      for (var i = 0; i < items.length; i++) {
                        children.add(items[i]);
                        if (i == 0 && items.length > 1) {
                          children.add(const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0x0A000000),
                            ),
                          ));
                        }
                      }
                      return children;
                    }(),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Widget para mostrar un elemento en la lista de administración.
class _AdminItemTile extends StatefulWidget {
  final String title;
  final bool isLast;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;
  final String? colorHex;
  final Future<void> Function(String)? onColorChanged;

  const _AdminItemTile({
    required this.title,
    required this.isLast,
    this.onEdit,
    this.onDelete,
    this.colorHex,
    this.onColorChanged,
  });

  @override
  State<_AdminItemTile> createState() => _AdminItemTileState();
}

class _AdminItemTileState extends State<_AdminItemTile> {
  Color _hexToColor(String hexString) {
    String hex = hexString.replaceFirst('#', '');
    // Si tiene 6 caracteres, agregar FF al inicio para opacidad completa
    if (hex.length == 6) {
      return Color(int.parse('ff$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    // Color por defecto si el formato es inválido
    return Color(int.parse('ffFF6B6B', radix: 16));
  }

  Future<void> _showColorPicker(BuildContext context) async {
    Color screenPickerColor = _hexToColor(widget.colorHex!);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(AppColors.white),
          title: const Text('Selecciona un color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: screenPickerColor,
              onColorChanged: (Color color) {
                screenPickerColor = color;
              },
              width: 40,
              height: 40,
              spacing: 4,
              runSpacing: 4,
              borderRadius: 0,
              wheelDiameter: 165,
              heading: Text(
                'Selecciona el tono',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subheading: Text(
                'Selecciona la intensidad',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final hexColor = '#${screenPickerColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                Navigator.of(context).pop();
                if (widget.onColorChanged != null) {
                  try {
                    await widget.onColorChanged!(hexColor);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al cambiar color: $e'),
                          backgroundColor: const Color(AppColors.errorRed),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0x0A000000),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.circle,
            size: 8,
            color: Color(AppColors.primaryOrange),
          ),
          const SizedBox(width: 12),
          // Color square for diet categories
          if (widget.colorHex != null)
            GestureDetector(
              onTap: widget.onColorChanged != null ? () => _showColorPicker(context) : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _hexToColor(widget.colorHex!),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0x20000000),
                    width: 1,
                  ),
                ),
              ),
            ),
          if (widget.colorHex != null) const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: itemStyle,
            ),
          ),
          if (widget.onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(AppColors.primaryBlue)),
              tooltip: 'Editar',
              onPressed: () async {
                try {
                  await widget.onEdit!();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al editar: $e'),
                        backgroundColor: const Color(AppColors.errorRed),
                      ),
                    );
                  }
                }
              },
            ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(AppColors.errorRed)),
              tooltip: 'Eliminar',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(AppColors.white),
                    title: Text(
                      'Eliminar Elemento',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            color: const Color(AppColors.darkText),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    content: Text(
                      '¿Estás seguro de que quieres eliminar "${widget.title}"? Esta acción no se puede deshacer.',
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: const Color(AppColors.darkText),
                          ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Cancelar',
                          style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                                color: const Color(AppColors.lightText),
                              ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.errorRed),
                        ),
                        onPressed: () async {
                          final navigator = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(ctx);
                          try {
                            await widget.onDelete!();
                            navigator.pop();
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('"${widget.title}" ha sido eliminado'),
                                  backgroundColor: const Color(AppColors.successGreen),
                                ),
                              );
                            }
                          } catch (e) {
                            navigator.pop();
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error al eliminar: $e'),
                                  backgroundColor: const Color(AppColors.errorRed),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(color: Color(AppColors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AdminAddTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _AdminAddTile({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final itemStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    return Material(
      color: const Color(AppColors.white),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: Color(AppColors.primaryGreen),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: itemStyle?.copyWith(color: const Color(AppColors.primaryGreen)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
