/// Version selector dropdown for artifacts.
///
/// Displays a dropdown showing all versions of an artifact with
/// dates, labels, and a restore button. The current version is
/// highlighted with an accent indicator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact_version.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/providers/artifact_provider.dart';

/// A compact version indicator that opens the version selector.
///
/// Shows "vN" with a chevron. Tapping opens a bottom sheet on
/// mobile with the full version list.
class VersionSelector extends ConsumerStatefulWidget {
  const VersionSelector({
    required this.artifact,
    super.key,
  });

  final FullArtifact artifact;

  @override
  ConsumerState<VersionSelector> createState() => _VersionSelectorState();
}

class _VersionSelectorState extends ConsumerState<VersionSelector> {
  @override
  void initState() {
    super.initState();
    // Load versions when the selector appears
    if (widget.artifact.versions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(artifactVersionsProvider.notifier)
            .loadVersions(widget.artifact.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final hasMultipleVersions = widget.artifact.versions.length > 1;

    return GestureDetector(
      onTap: hasMultipleVersions ? () => _showVersionSheet(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.bgSurfaceAlt,
          borderRadius: SanbaoRadius.sm,
          border: Border.all(
            color: colors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'v${widget.artifact.currentVersion}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textMuted,
              ),
            ),
            if (hasMultipleVersions) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 12,
                color: colors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showVersionSheet(BuildContext context) async {
    // Ensure versions are loaded
    final versionsState = ref.read(artifactVersionsProvider);
    if (versionsState is! VersionsLoaded) {
      await ref
          .read(artifactVersionsProvider.notifier)
          .loadVersions(widget.artifact.id);
    }

    if (!mounted) return;

    await showSanbaoBottomSheet<void>(
      context: context,
      builder: (context) => _VersionListSheet(
        artifact: widget.artifact,
      ),
    );
  }
}

/// Bottom sheet showing all versions with restore actions.
class _VersionListSheet extends ConsumerWidget {
  const _VersionListSheet({required this.artifact});

  final FullArtifact artifact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final versionsState = ref.watch(artifactVersionsProvider);

    return SanbaoBottomSheetContent(
      title: 'История версий',
      child: switch (versionsState) {
        VersionsInitial() || VersionsLoading() => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        VersionsError(:final message) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: colors.error, size: 32),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        VersionsLoaded(:final versions) => _VersionList(
            versions: versions,
            currentVersion: artifact.currentVersion,
            artifactId: artifact.id,
            colors: colors,
          ),
      },
    );
  }
}

/// The scrollable list of version items.
class _VersionList extends ConsumerWidget {
  const _VersionList({
    required this.versions,
    required this.currentVersion,
    required this.artifactId,
    required this.colors,
  });

  final List<ArtifactVersion> versions;
  final int currentVersion;
  final String artifactId;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sort by version number descending (newest first)
    final sorted = [...versions]
      ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: context.screenHeight * 0.4,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: sorted.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: colors.border,
        ),
        itemBuilder: (context, index) {
          final version = sorted[index];
          final isCurrent = version.versionNumber == currentVersion;

          return _VersionTile(
            version: version,
            isCurrent: isCurrent,
            colors: colors,
            onRestore: isCurrent
                ? null
                : () async {
                    await ref
                        .read(artifactVersionsProvider.notifier)
                        .restoreVersion(
                          artifactId: artifactId,
                          versionNumber: version.versionNumber,
                        );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      context.showSuccessSnackBar(
                        'Восстановлена версия v${version.versionNumber}',
                      );
                    }
                  },
          );
        },
      ),
    );
  }
}

/// A single version row in the list.
class _VersionTile extends StatelessWidget {
  const _VersionTile({
    required this.version,
    required this.isCurrent,
    required this.colors,
    this.onRestore,
  });

  final ArtifactVersion version;
  final bool isCurrent;
  final SanbaoColorScheme colors;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? colors.accentLight : Colors.transparent,
        borderRadius: SanbaoRadius.sm,
      ),
      child: Row(
        children: [
          // Version number badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCurrent
                  ? colors.accent
                  : colors.bgSurfaceAlt,
              borderRadius: SanbaoRadius.sm,
            ),
            alignment: Alignment.center,
            child: Text(
              'v${version.versionNumber}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCurrent ? colors.textInverse : colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Label and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  version.label ?? 'Версия ${version.versionNumber}',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCurrent ? colors.accent : colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(version.createdAt),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Current indicator or restore button
          if (isCurrent)
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: colors.accent,
            )
          else if (onRestore != null)
            GestureDetector(
              onTap: onRestore,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceAlt,
                  borderRadius: SanbaoRadius.sm,
                  border: Border.all(
                    color: colors.border,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Восстановить',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Formats a date for version display.
  String _formatDate(DateTime date) {
    if (date.isToday) {
      return 'Сегодня, ${date.timeString}';
    }
    if (date.isYesterday) {
      return 'Вчера, ${date.timeString}';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}, ${date.timeString}';
  }
}
