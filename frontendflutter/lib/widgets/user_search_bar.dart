import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Barra de búsqueda para usuarios en el panel de administración.
///
/// - Estética similar a `AppSearchBar`.
/// - Emite el texto en tiempo real vía `onQueryChanged`.
class UserSearchBar extends StatefulWidget {
  const UserSearchBar({
    super.key,
    this.hintText = 'Buscar por nombre o email',
    this.onQueryChanged,
  });

  final String hintText;
  final ValueChanged<String>? onQueryChanged;

  @override
  State<UserSearchBar> createState() => _UserSearchBarState();
}

class _UserSearchBarState extends State<UserSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    widget.onQueryChanged?.call(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: const Color(AppColors.lightText),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (_) => _onTextChanged(),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(AppColors.lightText),
                    ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _controller.clear();
                _onTextChanged();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
