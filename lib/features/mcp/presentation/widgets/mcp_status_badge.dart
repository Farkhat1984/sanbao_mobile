/// MCP server status badge with colored dot indicator.
///
/// Displays connected/disconnected/error status with appropriate
/// colors from the design system.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/mcp/domain/entities/mcp_server.dart';

/// A status badge for MCP server connection state.
///
/// Shows a colored dot (green/yellow/red) alongside a Russian
/// status label. Matches the Sanbao badge design pattern.
class McpStatusBadge extends StatelessWidget {
  const McpStatusBadge({
    required this.status,
    super.key,
    this.size = McpStatusBadgeSize.medium,
  });

  /// The connection status to display.
  final McpServerStatus status;

  /// Size preset for the badge.
  final McpStatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final (bgColor, fgColor, dotColor) = _resolveColors(colors);
    final sizing = _resolveSizing();

    return Container(
      padding: sizing.padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: SanbaoRadius.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: sizing.dotSize,
            height: sizing.dotSize,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: sizing.gap),
          Text(
            _statusLabel,
            style: TextStyle(
              fontSize: sizing.fontSize,
              fontWeight: FontWeight.w500,
              color: fgColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  String get _statusLabel => switch (status) {
        McpServerStatus.connected => 'Подключен',
        McpServerStatus.disconnected => 'Отключен',
        McpServerStatus.error => 'Ошибка',
      };

  (Color bg, Color fg, Color dot) _resolveColors(SanbaoColorScheme colors) =>
      switch (status) {
        McpServerStatus.connected => (
            colors.successLight,
            colors.success,
            colors.success,
          ),
        McpServerStatus.disconnected => (
            colors.bgSurfaceAlt,
            colors.textMuted,
            colors.textMuted,
          ),
        McpServerStatus.error => (
            colors.errorLight,
            colors.error,
            colors.error,
          ),
      };

  _BadgeSizing _resolveSizing() => switch (size) {
        McpStatusBadgeSize.small => const _BadgeSizing(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            fontSize: 11,
            dotSize: 6,
            gap: 4,
          ),
        McpStatusBadgeSize.medium => const _BadgeSizing(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            fontSize: 12,
            dotSize: 7,
            gap: 5,
          ),
      };
}

/// Size preset for the status badge.
enum McpStatusBadgeSize { small, medium }

class _BadgeSizing {
  const _BadgeSizing({
    required this.padding,
    required this.fontSize,
    required this.dotSize,
    required this.gap,
  });

  final EdgeInsets padding;
  final double fontSize;
  final double dotSize;
  final double gap;
}
