import 'package:flutter/material.dart';

import '../models/ai_model.dart';
import '../models/ai_provider.dart';
import 'context_matrix_theme.dart';

class SettingsProviderSetup extends StatelessWidget {
  const SettingsProviderSetup({
    super.key,
    required this.provider,
    required this.hasApiKey,
    required this.apiKeyController,
    required this.models,
    required this.selectedModelId,
    required this.modelErrorMessage,
    required this.isBusy,
    required this.isFetchingModels,
    required this.onPasteApiKey,
    required this.onSaveApiKey,
    required this.onRefreshModels,
    required this.onRemoveApiKey,
    required this.onSelectModel,
  });

  final AiProvider provider;
  final bool hasApiKey;
  final TextEditingController apiKeyController;
  final List<AiModel> models;
  final String? selectedModelId;
  final String? modelErrorMessage;
  final bool isBusy;
  final bool isFetchingModels;
  final VoidCallback onPasteApiKey;
  final VoidCallback onSaveApiKey;
  final VoidCallback onRefreshModels;
  final VoidCallback onRemoveApiKey;
  final ValueChanged<String> onSelectModel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContextMatrixStyle.panel.withValues(alpha: 0.76),
        border: Border.all(
          color: ContextMatrixStyle.border.withValues(alpha: 0.78),
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ContextMatrixStyle.violet.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: hasApiKey
            ? _SavedKeySetup(
                provider: provider,
                models: models,
                selectedModelId: selectedModelId,
                modelErrorMessage: modelErrorMessage,
                isBusy: isBusy,
                isFetchingModels: isFetchingModels,
                onRefreshModels: onRefreshModels,
                onRemoveApiKey: onRemoveApiKey,
                onSelectModel: onSelectModel,
              )
            : _MissingKeySetup(
                provider: provider,
                apiKeyController: apiKeyController,
                isBusy: isBusy,
                onPasteApiKey: onPasteApiKey,
                onSaveApiKey: onSaveApiKey,
              ),
      ),
    );
  }
}

class _MissingKeySetup extends StatelessWidget {
  const _MissingKeySetup({
    required this.provider,
    required this.apiKeyController,
    required this.isBusy,
    required this.onPasteApiKey,
    required this.onSaveApiKey,
  });

  final AiProvider provider;
  final TextEditingController apiKeyController;
  final bool isBusy;
  final VoidCallback onPasteApiKey;
  final VoidCallback onSaveApiKey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KeyStatusRow(label: '${provider.label} API key not saved'),
        const SizedBox(height: 12),
        TextField(
          key: ValueKey('${provider.storageValue}-api-key-field'),
          controller: apiKeyController,
          enabled: !isBusy,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: '${provider.label} API key',
            helperText: 'Saved keys are not shown again after saving.',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: isBusy ? null : onPasteApiKey,
              icon: const Icon(Icons.content_paste),
              label: Text('Paste', style: textTheme.labelLarge),
            ),
            FilledButton.icon(
              onPressed: isBusy ? null : onSaveApiKey,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save API key'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SavedKeySetup extends StatelessWidget {
  const _SavedKeySetup({
    required this.provider,
    required this.models,
    required this.selectedModelId,
    required this.modelErrorMessage,
    required this.isBusy,
    required this.isFetchingModels,
    required this.onRefreshModels,
    required this.onRemoveApiKey,
    required this.onSelectModel,
  });

  final AiProvider provider;
  final List<AiModel> models;
  final String? selectedModelId;
  final String? modelErrorMessage;
  final bool isBusy;
  final bool isFetchingModels;
  final VoidCallback onRefreshModels;
  final VoidCallback onRemoveApiKey;
  final ValueChanged<String> onSelectModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KeyStatusRow(label: '${provider.label} API key saved', isSaved: true),
        const SizedBox(height: 16),
        if (isFetchingModels) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            'Loading available models...',
            style: textTheme.bodyMedium?.copyWith(
              color: ContextMatrixStyle.mutedText,
            ),
          ),
        ] else if (models.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            key: ValueKey('${provider.storageValue}-model-dropdown'),
            isExpanded: true,
            initialValue: _selectedDropdownValue,
            selectedItemBuilder: (context) => [
              for (final model in models) _ModelLabel(label: model.displayName),
            ],
            items: [
              for (final model in models)
                DropdownMenuItem(
                  value: model.id,
                  child: _ModelLabel(label: model.displayName),
                ),
            ],
            onChanged: isBusy
                ? null
                : (value) {
                    if (value != null) {
                      onSelectModel(value);
                    }
                  },
            decoration: const InputDecoration(labelText: 'Model'),
          ),
        ] else ...[
          Text(
            'No compatible models loaded yet.',
            style: textTheme.bodyMedium?.copyWith(
              color: ContextMatrixStyle.mutedText,
            ),
          ),
        ],
        if (modelErrorMessage != null) ...[
          const SizedBox(height: 12),
          Text(modelErrorMessage!, style: TextStyle(color: colorScheme.error)),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: isBusy || isFetchingModels ? null : onRefreshModels,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh models'),
            ),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onRemoveApiKey,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove API key'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(
                  color: ContextMatrixStyle.danger.withValues(alpha: 0.68),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? get _selectedDropdownValue {
    if (models.any((model) => model.id == selectedModelId)) {
      return selectedModelId;
    }

    return null;
  }
}

class _ModelLabel extends StatelessWidget {
  const _ModelLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

class _KeyStatusRow extends StatelessWidget {
  const _KeyStatusRow({required this.label, this.isSaved = false});

  final String label;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    final iconColor = isSaved
        ? ContextMatrixStyle.success
        : ContextMatrixStyle.mutedText;

    return Row(
      children: [
        Icon(
          isSaved ? Icons.check_circle_outline : Icons.info_outline,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSaved
                  ? ContextMatrixStyle.text
                  : ContextMatrixStyle.mutedText,
            ),
          ),
        ),
      ],
    );
  }
}
