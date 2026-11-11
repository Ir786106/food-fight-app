import 'package:flutter/material.dart';

import '../theme/design_system.dart';
import '../../widgets/skeleton/shimmer_container.dart';

typedef EmptyState = EmptyStateView;
typedef ErrorState = ErrorView;
typedef ShimmerLoader = ShimmerContainer;

enum AppButtonStyle { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loadingLabel,
    this.style = AppButtonStyle.primary,
  });

  final String label;
  final String? loadingLabel;
  final VoidCallback? onPressed;
  final AppButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final callback = loadingLabel == null ? onPressed : null;
    final content = Text(loadingLabel ?? label, semanticsLabel: loadingLabel);
    const buttonStyle = ButtonStyle(
      minimumSize:
          WidgetStatePropertyAll(Size.square(DesignSystem.minTouchTarget)),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    return switch (style) {
      AppButtonStyle.primary =>
        FilledButton(onPressed: callback, style: buttonStyle, child: content),
      AppButtonStyle.secondary =>
        OutlinedButton(onPressed: callback, style: buttonStyle, child: content),
      AppButtonStyle.ghost =>
        TextButton(onPressed: callback, style: buttonStyle, child: content),
    };
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          constraints:
              const BoxConstraints(minHeight: DesignSystem.minTouchTarget),
        ),
      );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.highlighted = false});

  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(DesignSystem.radius20);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: highlighted
              ? LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    colors.surfaceContainerHigh,
                    colors.surfaceContainerLow
                  ],
                )
              : null,
        ),
        child: Padding(padding: DesignSystem.cardPadding, child: child),
      ),
    );
  }
}

enum StatusTone { neutral, active, success, warning, error }

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      StatusTone.neutral => (
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant
        ),
      StatusTone.active => (colors.primaryContainer, colors.onPrimaryContainer),
      StatusTone.success => (
          colors.tertiaryContainer,
          colors.onTertiaryContainer
        ),
      StatusTone.warning => (
          colors.secondaryContainer,
          colors.onSecondaryContainer
        ),
      StatusTone.error => (colors.errorContainer, colors.onErrorContainer),
    };
    return Chip(
      label: Text(label),
      backgroundColor: background,
      labelStyle: TextStyle(color: foreground),
      side: BorderSide.none,
    );
  }
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.initials, this.image});

  final String initials;
  final ImageProvider<Object>? image;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        foregroundImage: image,
        child: Text(initials),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: DesignSystem.space16,
        runSpacing: DesignSystem.space8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Semantics(
              header: true,
              child:
                  Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (action != null) action!,
        ],
      );
}

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SearchBar(
        hintText: hint,
        leading: const Icon(Icons.search),
        onChanged: onChanged,
      );
}

class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> labels;
  final Set<T> selected;
  final void Function(T value, bool selected) onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: DesignSystem.space8,
        runSpacing: DesignSystem.space8,
        children: [
          for (final entry in labels.entries)
            FilterChip(
              label: Text(entry.value),
              selected: selected.contains(entry.key),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (value) => onChanged(entry.key, value),
            ),
        ],
      );
}

class AppDataTable extends StatelessWidget {
  const AppDataTable({super.key, required this.columns, required this.rows});

  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.hasBoundedWidth ? constraints.maxWidth : 0,
            ),
            child: DataTable(columns: columns, rows: rows),
          ),
        ),
      );
}

abstract final class AppBottomSheet {
  static Future<T?> show<T>(BuildContext context, WidgetBuilder builder) =>
      showModalBottomSheet<T>(
        context: context,
        builder: builder,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
      );
}

abstract final class AppDialog {
  static Future<T?> show<T>(BuildContext context, WidgetBuilder builder) =>
      showDialog<T>(context: context, builder: builder);
}
