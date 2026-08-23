import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import 'app_empty_state.dart';

/// Standardized enterprise data table.
///
/// Renders the [DataTable] inside a rounded, bordered card with horizontal
/// scrolling on narrow screens and a themed empty state.
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.title,
    this.subtitle,
    this.trailing,
    this.maxLines = 0,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  /// Max visible rows before the table scrolls vertically (0 = no limit).
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadii.brLarge,
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) ?trailing,
                ],
              ),
            ),
          if (rows.isEmpty)
            AppEmptyState(
              compact: true,
              icon: Icons.table_rows_outlined,
              title: 'No records yet',
              subtitle: 'Nothing to display here right now.',
            )
          else
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.sizeOf(context).width,
                  ),
                  child: maxLines > 0
                      ? SizedBox(
                          height: (48 + 54 * maxLines).toDouble(),
                          child: SingleChildScrollView(
                            child: DataTable(columns: columns, rows: rows),
                          ),
                        )
                      : DataTable(columns: columns, rows: rows),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
