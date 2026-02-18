/// Agent icon widget with background color circle.
///
/// Renders the agent's icon on a colored circular background,
/// mapping string icon names to Material Icons.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Size presets for the agent icon.
enum AgentIconSize {
  /// 32px diameter, 16px icon.
  sm(32, 16),

  /// 40px diameter, 20px icon.
  md(40, 20),

  /// 48px diameter, 24px icon.
  lg(48, 24),

  /// 64px diameter, 32px icon.
  xl(64, 32),

  /// 80px diameter, 40px icon.
  xxl(80, 40);

  const AgentIconSize(this.diameter, this.iconSize);

  /// The outer circle diameter in logical pixels.
  final double diameter;

  /// The inner icon size in logical pixels.
  final double iconSize;
}

/// A circular icon widget for agents with a colored background.
///
/// Maps the agent's string icon name (e.g., "Bot", "Scale") to a
/// Material [IconData], and uses the agent's hex color as the
/// circle background.
class AgentIcon extends StatelessWidget {
  const AgentIcon({
    required this.icon,
    required this.color,
    super.key,
    this.size = AgentIconSize.md,
  });

  /// Icon name string (e.g., "Bot", "Scale", "Briefcase").
  final String icon;

  /// Hex color string for the background (e.g., "#4F6EF7").
  final String color;

  /// Size preset.
  final AgentIconSize size;

  @override
  Widget build(BuildContext context) {
    final bgColor = color.toColor() ?? const Color(0xFF4F6EF7);
    final iconData = _resolveIcon(icon);

    return Container(
      width: size.diameter,
      height: size.diameter,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: size.iconSize,
        color: Colors.white,
      ),
    );
  }

  /// Maps icon name strings to Material Icons.
  static IconData _resolveIcon(String name) => switch (name) {
        'Bot' => Icons.smart_toy_outlined,
        'Scale' => Icons.balance_outlined,
        'Briefcase' => Icons.work_outline,
        'Shield' => Icons.shield_outlined,
        'BookOpen' => Icons.menu_book_outlined,
        'Gavel' => Icons.gavel_outlined,
        'FileText' => Icons.description_outlined,
        'Building' => Icons.business_outlined,
        'User' => Icons.person_outlined,
        'HeartPulse' => Icons.favorite_outlined,
        'GraduationCap' => Icons.school_outlined,
        'Landmark' => Icons.account_balance_outlined,
        'Code' => Icons.code_outlined,
        'MessageSquare' => Icons.chat_outlined,
        'Globe' => Icons.language_outlined,
        'Lightbulb' => Icons.lightbulb_outlined,
        'FileSearch' => Icons.find_in_page_outlined,
        'ShieldCheck' => Icons.verified_user_outlined,
        'ClipboardCheck' => Icons.assignment_turned_in_outlined,
        'Brain' => Icons.psychology_outlined,
        'Triangle' => Icons.change_history_outlined,
        'Sparkles' => Icons.auto_awesome_outlined,
        _ => Icons.smart_toy_outlined,
      };

  /// Returns all available icon names for the picker.
  static const List<String> availableIcons = [
    'Bot', 'Scale', 'Briefcase', 'Shield', 'BookOpen', 'Gavel',
    'FileText', 'Building', 'User', 'HeartPulse', 'GraduationCap',
    'Landmark', 'Code', 'MessageSquare', 'Globe', 'Lightbulb',
    'FileSearch', 'ShieldCheck', 'ClipboardCheck', 'Brain',
    'Triangle', 'Sparkles',
  ];

  /// Returns the [IconData] for a given icon name string.
  static IconData iconDataFor(String name) => _resolveIcon(name);
}
