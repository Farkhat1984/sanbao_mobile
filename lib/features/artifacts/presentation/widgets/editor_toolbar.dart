/// Formatting toolbar for the markdown editor.
///
/// A horizontally scrollable row of formatting buttons that insert
/// or toggle markdown syntax in the editor. Organized into logical
/// groups: undo/redo, text formatting, headings, block elements,
/// and inline elements.
///
/// Each button shows an icon and tooltip, and supports an active
/// state when the cursor is inside a formatted block.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Callback signature for toolbar formatting actions.
typedef ToolbarAction = void Function();

/// Describes a single formatting command available in the toolbar.
class ToolbarCommand {
  const ToolbarCommand({
    required this.id,
    required this.tooltip,
    required this.onTap,
    this.icon,
    this.label,
    this.isEnabled = true,
    this.isActive = false,
  }) : assert(icon != null || label != null, 'Icon or label required');

  /// Unique identifier for this command (e.g., 'bold', 'h1').
  final String id;

  /// Tooltip text displayed on long press.
  final String tooltip;

  /// Callback when the button is tapped.
  final ToolbarAction onTap;

  /// Icon to display. If null, [label] is used instead.
  final IconData? icon;

  /// Text label to display when [icon] is null (e.g., 'H1').
  final String? label;

  /// Whether this button is currently enabled.
  final bool isEnabled;

  /// Whether this command is currently active at the cursor position.
  final bool isActive;
}

/// Represents a visual divider between toolbar button groups.
class ToolbarDivider {
  const ToolbarDivider();
}

/// A toolbar item is either a command button or a divider.
sealed class ToolbarItem {
  const ToolbarItem();
}

/// A command button item in the toolbar.
final class ToolbarCommandItem extends ToolbarItem {
  const ToolbarCommandItem(this.command);
  final ToolbarCommand command;
}

/// A visual divider item in the toolbar.
final class ToolbarDividerItem extends ToolbarItem {
  const ToolbarDividerItem();
}

/// Horizontal scrollable formatting toolbar for the markdown editor.
///
/// Renders a row of [ToolbarItem] widgets: icon/text buttons and
/// dividers. Styled consistently with the Sanbao design system.
///
/// Usage:
/// ```dart
/// EditorToolbar(
///   items: [
///     ToolbarCommandItem(ToolbarCommand(
///       id: 'bold',
///       icon: Icons.format_bold_rounded,
///       tooltip: 'Жирный',
///       onTap: () => editor.toggleBold(),
///       isActive: isBoldActive,
///     )),
///     const ToolbarDividerItem(),
///     // ...
///   ],
/// )
/// ```
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    required this.items,
    super.key,
    this.visible = true,
  });

  /// The toolbar items to render.
  final List<ToolbarItem> items;

  /// Whether the toolbar is visible. When false, renders nothing.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final colors = context.sanbaoColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) => _buildItem(item, colors)).toList(),
        ),
      ),
    );
  }

  Widget _buildItem(ToolbarItem item, SanbaoColorScheme colors) =>
      switch (item) {
        ToolbarCommandItem(:final command) => command.icon != null
            ? _ToolbarIconButton(command: command, colors: colors)
            : _ToolbarTextButton(command: command, colors: colors),
        ToolbarDividerItem() => _ToolbarDivider(color: colors.border),
      };
}

/// An icon-based toolbar button with hover/active visual states.
class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.command,
    required this.colors,
  });

  final ToolbarCommand command;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: command.tooltip,
        child: GestureDetector(
          onTap: command.isEnabled ? command.onTap : null,
          child: AnimatedContainer(
            duration: SanbaoAnimations.durationFast,
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: command.isActive ? colors.accentLight : Colors.transparent,
              borderRadius: SanbaoRadius.sm,
            ),
            child: Icon(
              command.icon,
              size: 18,
              color: _resolveColor(),
            ),
          ),
        ),
      );

  Color _resolveColor() {
    if (command.isActive) return colors.accent;
    if (!command.isEnabled) return colors.textMuted.withValues(alpha: 0.4);
    return colors.textSecondary;
  }
}

/// A text-label toolbar button (for heading levels like H1, H2, H3).
class _ToolbarTextButton extends StatelessWidget {
  const _ToolbarTextButton({
    required this.command,
    required this.colors,
  });

  final ToolbarCommand command;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: command.tooltip,
        child: GestureDetector(
          onTap: command.isEnabled ? command.onTap : null,
          child: AnimatedContainer(
            duration: SanbaoAnimations.durationFast,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: command.isActive ? colors.accentLight : Colors.transparent,
              borderRadius: SanbaoRadius.sm,
            ),
            child: Text(
              command.label ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: command.isActive ? colors.accent : colors.textSecondary,
              ),
            ),
          ),
        ),
      );
}

/// Thin vertical divider between toolbar button groups.
class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: color,
      );
}
