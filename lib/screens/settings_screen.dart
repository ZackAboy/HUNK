import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ai_provider.dart';
import '../providers/settings_controller.dart';
import '../services/model_listing_service.dart';
import '../services/settings_storage.dart';
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'AI provider settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose one provider, save its API key locally, then select an available model.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const Text('Active provider'),
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
