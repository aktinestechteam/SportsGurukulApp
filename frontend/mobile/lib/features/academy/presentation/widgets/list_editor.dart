import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';

class ListEditorItem<T> {
  const ListEditorItem({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final T value;
}

/// Generic editor card that manages an ordered collection of items.
///
/// Parent owns the items state and receives add/edit/remove callbacks.
class ListEditor<T> extends StatelessWidget {
  const ListEditor({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.addLabel,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String addLabel;
  final List<ListEditorItem<T>> items;
  final VoidCallback onAdd;
  final ValueChanged<T> onEdit;
  final ValueChanged<T> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: title,
            subtitle: subtitle,
            trailing: AppButton(
              label: addLabel,
              variant: AppButtonVariant.secondary,
              icon: Icons.add,
              expanded: false,
              onPressed: onAdd,
            ),
          ),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: AppRadii.br(AppRadii.medium),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'No $title added yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final item in items) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: AppRadii.br(AppRadii.medium),
                  ),
                  child: Icon(icon, size: 20, color: scheme.primary),
                ),
                title: Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: item.subtitle == null
                    ? null
                    : Text(
                        item.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit',
                      onPressed: () => onEdit(item.value),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20),
                      color: scheme.error,
                      tooltip: 'Remove',
                      onPressed: () => onRemove(item.value),
                    ),
                  ],
                ),
              ),
              if (item != items.last)
                Divider(height: 1, color: scheme.outlineVariant),
            ],
        ],
      ),
    );
  }
}
