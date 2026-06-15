import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ai_provider.dart';
import '../providers/settings_controller.dart';
import '../services/model_listing_service.dart';
import '../services/settings_storage.dart';
import '../widgets/context_matrix_theme.dart';
import '../widgets/settings_provider_setup.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.settingsStorage,
    this.modelListingService,
  });

  final SettingsStorage? settingsStorage;
  final ModelListingService? modelListingService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SettingsController(
      storage: widget.settingsStorage ?? SecureSettingsStorage(),
      modelListingService:
          widget.modelListingService ?? ProviderModelListingService(),
    )..load();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final settings = _controller.settings;
        final activeProvider = settings.activeProvider;

        final textTheme = Theme.of(context).textTheme;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
          children: [
            Row(
              children: [
                const _SettingsPulseIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI provider settings',
                    style: textTheme.headlineSmall?.copyWith(
                      color: ContextMatrixStyle.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose one provider, save its API key locally, then select an available model.',
              style: textTheme.bodyMedium?.copyWith(
                color: ContextMatrixStyle.mutedText,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Active provider',
              style: textTheme.titleSmall?.copyWith(
                color: ContextMatrixStyle.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AiProvider>(
              segments: const [
                ButtonSegment(
                  value: AiProvider.openAi,
                  icon: Icon(Icons.auto_awesome),
                  label: Text('OpenAI'),
                ),
                ButtonSegment(
                  value: AiProvider.gemini,
                  icon: Icon(Icons.diamond_outlined),
                  label: Text('Google Gemini'),
                ),
              ],
              selected: {activeProvider},
              onSelectionChanged: _controller.isBusy
                  ? null
                  : (selection) {
                      _apiKeyController.clear();
                      _controller.selectProvider(selection.first);
                    },
            ),
            const SizedBox(height: 24),
            if (_controller.isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ],
            SettingsProviderSetup(
              provider: activeProvider,
              hasApiKey: settings.isKeySaved(activeProvider),
              apiKeyController: _apiKeyController,
              models: _controller.activeModels,
              selectedModelId: settings.selectedModel(activeProvider),
              modelErrorMessage: _controller.modelErrorMessage,
              isBusy: _controller.isBusy,
              isFetchingModels: _controller.isFetchingModels,
              onPasteApiKey: _pasteApiKey,
              onSaveApiKey: _saveApiKey,
              onRefreshModels: _refreshModels,
              onRemoveApiKey: _removeApiKey,
              onSelectModel: _selectModel,
            ),
            if (_controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _controller.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pasteApiKey() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text ?? '';
    if (text.isEmpty) {
      _showMessage('Clipboard is empty');
      return;
    }

    _apiKeyController.text = text;
    _showMessage('Clipboard pasted');
  }

  Future<void> _saveApiKey() async {
    await _controller.saveApiKey(_apiKeyController.text);
    if (_controller.message != null) {
      _apiKeyController.clear();
    }
    _showControllerMessage();
  }

  Future<void> _refreshModels() async {
    await _controller.refreshModels();
    _showControllerMessage();
  }

  Future<void> _removeApiKey() async {
    await _controller.removeActiveProviderApiKey();
    _apiKeyController.clear();
    _showControllerMessage();
  }

  Future<void> _selectModel(String modelId) async {
    await _controller.selectModel(modelId);
    _showControllerMessage();
  }

  void _showControllerMessage() {
    if (_controller.message != null) {
      _showMessage(_controller.message!);
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsPulseIcon extends StatelessWidget {
  const _SettingsPulseIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContextMatrixStyle.violet.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ContextMatrixStyle.violet.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: ContextMatrixStyle.violet.withValues(alpha: 0.17),
            blurRadius: 18,
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Icon(Icons.tune_outlined, color: ContextMatrixStyle.violet),
      ),
    );
  }
}
