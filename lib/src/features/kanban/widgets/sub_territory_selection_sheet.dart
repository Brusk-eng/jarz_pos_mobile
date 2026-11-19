import 'package:flutter/material.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/localized_formatters.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/territory_label.dart';

/// Bottom sheet for selecting a sub-territory for an invoice.
class SubTerritorySelectionSheet extends StatefulWidget {
  final String territory;
  final List<Map<String, dynamic>> subTerritories;
  final String? currentSelection;

  const SubTerritorySelectionSheet({
    super.key,
    required this.territory,
    required this.subTerritories,
    this.currentSelection,
  });

  @override
  State<SubTerritorySelectionSheet> createState() => _SubTerritorySelectionSheetState();
}

class _SubTerritorySelectionSheetState extends State<SubTerritorySelectionSheet> {
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return widget.subTerritories;
    final q = _searchQuery.toLowerCase();
    return widget.subTerritories.where((t) {
      final name = (t['territory_name'] ?? t['name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      initialChildSize: ResponsiveUtils.isPhoneLandscape(context) ? 0.72 : 0.55,
      minChildSize: ResponsiveUtils.isPhone(context) ? 0.42 : 0.3,
      maxChildSize: ResponsiveUtils.isPhone(context) ? 0.92 : 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.subTerritorySelectTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.subTerritoryForTerritory(widget.territory),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              // Search field
              TextField(
                decoration: InputDecoration(
                  hintText: '${l10n.kanbanFilterSearch}...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(l10n.subTerritoryNoResults, style: TextStyle(color: Colors.grey[500])),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: _filtered.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _filtered[index];
                          final code = (item['name'] ?? '').toString();
                          final displayName = territoryLabelOf(item);
                          final expense = (item['delivery_expense'] ?? 0).toDouble();
                          final isSelected = code == widget.currentSelection;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Colors.blue.withValues(alpha: 0.08),
                            leading: Icon(
                              isSelected ? Icons.check_circle : Icons.location_on_outlined,
                              color: isSelected ? Colors.blue : Colors.grey,
                              size: 22,
                            ),
                            title: Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            trailing: expense > 0
                                ? Text(
                                    formatCurrency(context, expense),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepOrange[700],
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(code),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
