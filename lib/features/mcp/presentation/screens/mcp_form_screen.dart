/// MCP server add/edit form screen.
///
/// Provides fields for name, URL, API key (masked), and a test
/// connection button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_input.dart';
import 'package:sanbao_flutter/features/mcp/domain/entities/mcp_server.dart';
import 'package:sanbao_flutter/features/mcp/presentation/providers/mcp_provider.dart';
import 'package:sanbao_flutter/features/mcp/presentation/widgets/mcp_status_badge.dart';

/// Screen for creating or editing an MCP server configuration.
///
/// Shows form fields for name, URL, and API key. Includes a test
/// connection button that validates the server is reachable.
class McpFormScreen extends ConsumerStatefulWidget {
  const McpFormScreen({super.key, this.server});

  /// If provided, the form edits this existing server.
  /// If null, the form creates a new server.
  final McpServer? server;

  @override
  ConsumerState<McpFormScreen> createState() => _McpFormScreenState();
}

class _McpFormScreenState extends ConsumerState<McpFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _apiKeyController;
  bool _obscureApiKey = true;

  bool get _isEditing => widget.server != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server?.name ?? '');
    _urlController = TextEditingController(text: widget.server?.url ?? '');
    _apiKeyController =
        TextEditingController(text: widget.server?.apiKey ?? '');

    // Initialize form state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(mcpFormProvider.notifier)
          .initialize(server: widget.server);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref.read(mcpFormSubmittingProvider.notifier).state = true;

    try {
      final notifier = ref.read(mcpServersProvider.notifier);

      if (_isEditing) {
        await notifier.updateServer(
          id: widget.server!.id,
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          apiKey: _apiKeyController.text.trim().nullIfEmpty,
        );
        if (mounted) {
          context.showSuccessSnackBar('Сервер обновлен');
        }
      } else {
        await notifier.createServer(
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          apiKey: _apiKeyController.text.trim().nullIfEmpty,
        );
        if (mounted) {
          context.showSuccessSnackBar('Сервер добавлен');
        }
      }

      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Ошибка: $e');
      }
    } finally {
      ref.read(mcpFormSubmittingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final isSubmitting = ref.watch(mcpFormSubmittingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать сервер' : 'Новый MCP сервер'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status indicator for existing servers
            if (_isEditing && widget.server != null) ...[
              _buildCurrentStatus(widget.server!),
              const SizedBox(height: 24),
            ],

            // Name
            SanbaoInput(
              controller: _nameController,
              label: 'Название',
              hint: 'Мой MCP сервер',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название сервера';
                }
                return null;
              },
              onChanged: (value) =>
                  ref.read(mcpFormProvider.notifier).updateName(value),
            ),

            const SizedBox(height: 16),

            // URL
            SanbaoInput(
              controller: _urlController,
              label: 'URL сервера',
              hint: 'https://mcp.example.com',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите URL сервера';
                }
                if (!value.trim().isValidUrl) {
                  return 'Введите корректный URL';
                }
                return null;
              },
              onChanged: (value) =>
                  ref.read(mcpFormProvider.notifier).updateUrl(value),
            ),

            const SizedBox(height: 16),

            // API Key
            SanbaoInput(
              controller: _apiKeyController,
              label: 'API ключ (необязательно)',
              hint: 'sk-...',
              obscureText: _obscureApiKey,
              textInputAction: TextInputAction.done,
              suffix: IconButton(
                onPressed: () {
                  setState(() => _obscureApiKey = !_obscureApiKey);
                },
                icon: Icon(
                  _obscureApiKey
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: colors.textMuted,
                ),
              ),
              onChanged: (value) =>
                  ref.read(mcpFormProvider.notifier).updateApiKey(value),
            ),

            const SizedBox(height: 8),
            Text(
              'API ключ хранится в зашифрованном виде',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            ),

            const SizedBox(height: 32),

            // Submit
            SanbaoButton(
              label: _isEditing ? 'Сохранить' : 'Добавить сервер',
              onPressed: isSubmitting ? null : _submit,
              isLoading: isSubmitting,
              isExpanded: true,
              leadingIcon: _isEditing ? Icons.save_outlined : Icons.add,
            ),

            const SizedBox(height: 12),

            // Test connection (only for existing servers)
            if (_isEditing)
              SanbaoButton(
                label: 'Проверить подключение',
                onPressed: isSubmitting
                    ? null
                    : () async {
                        try {
                          final updated = await ref
                              .read(mcpServersProvider.notifier)
                              .testConnection(widget.server!.id);
                          if (mounted) {
                            if (updated.status == McpServerStatus.connected) {
                              context.showSuccessSnackBar(
                                'Подключение успешно',
                              );
                            } else {
                              context.showErrorSnackBar(
                                updated.errorMessage ??
                                    'Не удалось подключиться',
                              );
                            }
                          }
                        } on Object catch (e) {
                          if (mounted) {
                            context.showErrorSnackBar('Ошибка: $e');
                          }
                        }
                      },
                variant: SanbaoButtonVariant.secondary,
                isExpanded: true,
                leadingIcon: Icons.wifi_tethering,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus(McpServer server) {
    final colors = context.sanbaoColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurfaceAlt,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.dns_outlined, color: colors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Текущий статус',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                McpStatusBadge(status: server.status),
              ],
            ),
          ),
          if (server.tools.isNotEmpty)
            Text(
              '${server.tools.length} инстр.',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
