/// MCP server card widget for the server list.
///
/// Displays name, truncated URL, status dot, tool count,
/// and last connected time.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/features/mcp/domain/entities/mcp_server.dart';
import 'package:sanbao_flutter/features/mcp/presentation/widgets/mcp_status_badge.dart';

/// A card displaying an MCP server's summary information.
///
/// Shows the server name, truncated URL, connection status badge,
/// tool count, and last connected timestamp.
class McpServerCard extends StatefulWidget {
  const McpServerCard({
    required this.server,
    required this.onTap,
    super.key,
    this.onTestConnection,
    this.isTesting = false,
  });

  /// The MCP server to display.
  final McpServer server;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Callback to test the server connection.
  final VoidCallback? onTestConnection;

  /// Whether this server is currently being tested.
  final bool isTesting;

  @override
  State<McpServerCard> createState() => _McpServerCardState();
}

class _McpServerCardState extends State<McpServerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationFast,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: SanbaoAnimations.buttonPressScale,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final server = widget.server;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: SanbaoRadius.lg,
            border: Border.all(color: colors.border, width: 0.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(server, colors),
              const SizedBox(height: 12),
              _buildUrl(server, colors),
              const SizedBox(height: 12),
              _buildFooter(server, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(McpServer server, SanbaoColorScheme colors) => Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.accentLight,
              borderRadius: SanbaoRadius.md,
            ),
            child: Icon(
              Icons.dns_outlined,
              color: colors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.name,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                McpStatusBadge(
                  status: server.status,
                  size: McpStatusBadgeSize.small,
                ),
              ],
            ),
          ),
          if (widget.isTesting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.accent,
              ),
            )
          else if (widget.onTestConnection != null)
            IconButton(
              onPressed: widget.onTestConnection,
              icon: Icon(
                Icons.refresh,
                color: colors.textMuted,
                size: 20,
              ),
              tooltip: 'Проверить подключение',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
        ],
      );

  Widget _buildUrl(McpServer server, SanbaoColorScheme colors) => Text(
        server.url.truncate(50),
        style: context.textTheme.bodySmall?.copyWith(
          color: colors.textMuted,
          fontFamily: 'JetBrainsMono',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildFooter(McpServer server, SanbaoColorScheme colors) => Row(
        children: [
          if (server.tools.isNotEmpty)
            SanbaoBadge(
              label: '${server.tools.length} инстр.',
              variant: SanbaoBadgeVariant.accent,
              icon: Icons.build_outlined,
              size: SanbaoBadgeSize.small,
            ),
          const Spacer(),
          if (server.lastConnected != null)
            Text(
              _formatLastConnected(server.lastConnected!),
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
                fontSize: 11,
              ),
            ),
        ],
      );

  String _formatLastConnected(DateTime date) {
    if (date.isToday) return 'Сегодня ${date.timeString}';
    if (date.isYesterday) return 'Вчера ${date.timeString}';
    final daysAgo = date.daysAgo;
    if (daysAgo < 7) return '$daysAgo дн. назад';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
