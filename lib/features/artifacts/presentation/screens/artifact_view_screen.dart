/// Full-screen artifact viewer with tabbed interface.
///
/// Opens as a modal bottom sheet on mobile or full-screen route
/// on tablet. Provides three tabs:
/// - Просмотр (Preview): Rendered Markdown or code preview
/// - Редактор (Editor): Rich text editor with toolbar
/// - Исходник (Source): Raw Markdown/source code view
///
/// The header includes the artifact title, type badge, version
/// selector, export button, share, and print actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/theme/typography.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/providers/artifact_provider.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/widgets/code_preview.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/widgets/document_editor.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/widgets/document_preview.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/widgets/export_menu.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/widgets/version_selector.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the artifact viewer.
///
/// On mobile (< 600px), opens as a full-screen bottom sheet.
/// On tablet, opens as a full-screen page route.
Future<void> openArtifactViewer({
  required BuildContext context,
  required WidgetRef ref,
  required FullArtifact artifact,
}) async {
  // Set the current artifact in the provider
  ref.read(currentArtifactProvider.notifier).open(artifact);

  if (context.isMobile) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: SanbaoColors.mobileOverlay,
      builder: (context) => const _ArtifactViewSheet(),
    );
  } else {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => const ArtifactViewScreen(),
      ),
    );
  }

  // Clean up when closed
  ref.read(currentArtifactProvider.notifier).close();
  ref.read(exportProvider.notifier).reset();
}

/// Full-screen artifact viewer widget.
///
/// Used as a standalone route on tablets and desktops.
class ArtifactViewScreen extends ConsumerWidget {
  const ArtifactViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artifact = ref.watch(currentArtifactProvider);
    if (artifact == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: _ArtifactViewBody(artifact: artifact),
      ),
    );
  }
}

/// Bottom sheet wrapper for mobile artifact viewing.
class _ArtifactViewSheet extends ConsumerWidget {
  const _ArtifactViewSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final artifact = ref.watch(currentArtifactProvider);

    if (artifact == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: context.screenHeight * 0.95,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SanbaoRadius.lgValue),
        ),
        boxShadow: SanbaoShadows.lg,
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Drag handle
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderHover,
              borderRadius: SanbaoRadius.full,
            ),
          ),
          const SizedBox(height: 4),
          // Body
          Expanded(
            child: _ArtifactViewBody(artifact: artifact),
          ),
        ],
      ),
    );
  }
}

/// The main body of the artifact viewer (shared between sheet and screen).
class _ArtifactViewBody extends ConsumerWidget {
  const _ArtifactViewBody({required this.artifact});

  final FullArtifact artifact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(artifactViewTabProvider);

    return Column(
      children: [
        // Header with title, badges, actions
        _ArtifactHeader(artifact: artifact),

        // Tab bar (hidden for image type)
        if (artifact.type != ArtifactType.image)
          _ArtifactTabBar(
            activeTab: activeTab,
            artifactType: artifact.type,
          ),

        // Tab content
        Expanded(
          child: AnimatedSwitcher(
            duration: SanbaoAnimations.durationFast,
            child: _buildTabContent(activeTab, artifact, ref),
          ),
        ),
      ],
    );
  }

  /// Builds the content widget for the active tab.
  Widget _buildTabContent(
    ArtifactViewTab tab,
    FullArtifact artifact,
    WidgetRef ref,
  ) {
    return switch (tab) {
      ArtifactViewTab.preview => _buildPreview(artifact),
      ArtifactViewTab.editor => _buildEditor(artifact, ref),
      ArtifactViewTab.source => _buildSource(artifact),
    };
  }

  /// Preview tab: rendered Markdown or code preview.
  Widget _buildPreview(FullArtifact artifact) {
    if (artifact.type == ArtifactType.code) {
      return CodePreview(
        key: const ValueKey('preview'),
        code: artifact.content,
        language: artifact.language,
      );
    }

    return DocumentPreview(
      key: const ValueKey('preview'),
      content: artifact.content,
    );
  }

  /// Editor tab: Markdown editor with toolbar.
  Widget _buildEditor(FullArtifact artifact, WidgetRef ref) {
    return DocumentEditor(
      key: const ValueKey('editor'),
      content: artifact.content,
      onContentChanged: (newContent) {
        ref.read(currentArtifactProvider.notifier).updateContent(newContent);
        // Auto-save to server
        ref.read(exportProvider.notifier).saveContent(
              artifactId: artifact.id,
              content: newContent,
            );
      },
    );
  }

  /// Source tab: raw text/code view.
  Widget _buildSource(FullArtifact artifact) {
    return _SourceView(
      key: const ValueKey('source'),
      content: artifact.content,
      language: artifact.language,
    );
  }
}

/// Header section with title, type badge, version, and action buttons.
class _ArtifactHeader extends ConsumerWidget {
  const _ArtifactHeader({required this.artifact});

  final FullArtifact artifact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: close button + actions
          Row(
            children: [
              // Back / Close button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.bgSurfaceAlt,
                    borderRadius: SanbaoRadius.sm,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  artifact.title,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              // Action buttons
              _HeaderActions(artifact: artifact),
            ],
          ),

          const SizedBox(height: 8),

          // Bottom row: type badge + version + export
          Row(
            children: [
              // Type badge
              SanbaoBadge(
                label: artifact.type.badgeLabel,
                variant: _badgeVariant(artifact.type),
                size: SanbaoBadgeSize.small,
                icon: _typeIcon(artifact.type),
              ),

              const SizedBox(width: 8),

              // Version selector
              VersionSelector(artifact: artifact),

              const Spacer(),

              // Export action bar
              ExportActionBar(
                artifactId: artifact.id,
                artifactType: artifact.type,
              ),
            ],
          ),
        ],
      ),
    );
  }

  SanbaoBadgeVariant _badgeVariant(ArtifactType type) => switch (type) {
        ArtifactType.document => SanbaoBadgeVariant.accent,
        ArtifactType.code => SanbaoBadgeVariant.success,
        ArtifactType.legal => SanbaoBadgeVariant.legal,
        ArtifactType.spreadsheet => SanbaoBadgeVariant.warning,
        ArtifactType.analysis => SanbaoBadgeVariant.legal,
        ArtifactType.image => SanbaoBadgeVariant.warning,
      };

  IconData _typeIcon(ArtifactType type) => switch (type) {
        ArtifactType.document => Icons.description_rounded,
        ArtifactType.code => Icons.code_rounded,
        ArtifactType.legal => Icons.gavel_rounded,
        ArtifactType.spreadsheet => Icons.table_chart_rounded,
        ArtifactType.analysis => Icons.analytics_rounded,
        ArtifactType.image => Icons.image_rounded,
      };
}

/// Action buttons in the header (copy, share, print).
class _HeaderActions extends ConsumerStatefulWidget {
  const _HeaderActions({required this.artifact});

  final FullArtifact artifact;

  @override
  ConsumerState<_HeaderActions> createState() => _HeaderActionsState();
}

class _HeaderActionsState extends ConsumerState<_HeaderActions> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.artifact.content));
    setState(() => _copied = true);
    if (mounted) context.showSuccessSnackBar('Скопировано в буфер обмена');
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _handleShare() async {
    await Share.share(
      widget.artifact.content,
      subject: widget.artifact.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Copy button
        _ActionIconButton(
          icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
          tooltip: _copied ? 'Скопировано' : 'Копировать',
          color: _copied ? colors.success : colors.textMuted,
          onTap: _handleCopy,
        ),
        const SizedBox(width: 4),

        // Share button
        _ActionIconButton(
          icon: Icons.share_rounded,
          tooltip: 'Поделиться',
          color: colors.textMuted,
          onTap: _handleShare,
        ),
      ],
    );
  }
}

/// Small icon button used in the header actions.
class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: SanbaoRadius.sm,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

/// Tab bar for switching between Preview, Editor, and Source.
class _ArtifactTabBar extends ConsumerWidget {
  const _ArtifactTabBar({
    required this.activeTab,
    required this.artifactType,
  });

  final ArtifactViewTab activeTab;
  final ArtifactType artifactType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final tabs = _availableTabs();

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = tab == activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(artifactViewTabProvider.notifier).state = tab;
              },
              behavior: HitTestBehavior.opaque,
              child: _TabItem(
                label: tab.label,
                isActive: isActive,
                colors: colors,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Returns tabs available for the current artifact type.
  List<ArtifactViewTab> _availableTabs() {
    if (!artifactType.supportsEditor) {
      return [ArtifactViewTab.preview, ArtifactViewTab.source];
    }
    return ArtifactViewTab.values;
  }
}

/// A single tab item with animated underline.
class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isActive,
    required this.colors,
  });

  final String label;
  final bool isActive;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SanbaoAnimations.durationFast,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? colors.accent : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? colors.accent : colors.textMuted,
        ),
      ),
    );
  }
}

/// Raw source view with monospaced font.
class _SourceView extends StatelessWidget {
  const _SourceView({
    super.key,
    required this.content,
    this.language,
  });

  final String content;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Container(
      color: colors.bgSurfaceAlt,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          content,
          style: SanbaoTypography.codeStyle(
            color: colors.textSecondary,
            fontSize: 13,
          ).copyWith(
            height: 1.7,
          ),
        ),
      ),
    );
  }
}
