import 'package:flutter/foundation.dart';

import '../models/ai_model.dart';
import '../models/ai_provider.dart';
import '../models/ai_settings.dart';
import '../services/model_listing_service.dart';
import '../services/settings_storage.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required this.storage,
    required this.modelListingService,
  });

  final SettingsStorage storage;
  final ModelListingService modelListingService;
  final Map<AiProvider, List<AiModel>> _modelCache = {};

  AiSettings _settings = AiSettings.initial();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFetchingModels = false;
  String? _message;
  String? _errorMessage;
  String? _modelErrorMessage;

  AiSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isFetchingModels => _isFetchingModels;
  bool get isBusy => _isLoading || _isSaving || _isFetchingModels;
  String? get message => _message;
  String? get errorMessage => _errorMessage;
  String? get modelErrorMessage => _modelErrorMessage;

  AiProvider get activeProvider => _settings.activeProvider;
  bool get activeProviderHasKey => _settings.isKeySaved(activeProvider);
  String? get activeSelectedModel => _settings.selectedModel(activeProvider);
  List<AiModel> get activeModels => _modelCache[activeProvider] ?? const [];

  Future<void> load() async {
    _isLoading = true;
    _message = null;
    _errorMessage = null;
    _modelErrorMessage = null;
    notifyListeners();

    try {
      _settings = await storage.loadSettings();
    } catch (_) {
      _errorMessage = 'Settings could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    await _fetchModelsIfNeeded(activeProvider);
  }

  Future<void> selectProvider(AiProvider provider) async {
    if (provider == activeProvider) {
      return;
    }

    _settings = _settings.copyWith(activeProvider: provider);
    _message = null;
    _errorMessage = null;
    _modelErrorMessage = null;
    notifyListeners();

    try {
      await storage.saveActiveProvider(provider);
    } catch (_) {
      _errorMessage = 'Provider selection could not be saved.';
      notifyListeners();
      return;
    }

    await _fetchModelsIfNeeded(provider);
  }

  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Enter an API key before saving.';
      _message = null;
      notifyListeners();
      return;
    }

    final provider = activeProvider;
    _isSaving = true;
    _message = null;
    _errorMessage = null;
    _modelErrorMessage = null;
    notifyListeners();

    try {
      await storage.saveApiKey(provider: provider, apiKey: trimmed);
      _modelCache.remove(provider);
      _settings = await storage.loadSettings();
      _message = 'Settings saved';
    } catch (_) {
      _errorMessage = 'API key could not be saved.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }

    await refreshModels();
  }

  Future<void> removeActiveProviderApiKey() async {
    final provider = activeProvider;
    _isSaving = true;
    _message = null;
    _errorMessage = null;
    _modelErrorMessage = null;
    notifyListeners();

    try {
      await storage.removeApiKey(provider);
      _modelCache.remove(provider);
      _settings = await storage.loadSettings();
      _message = '${provider.label} API key removed';
    } catch (_) {
      _errorMessage = 'API key could not be removed.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> selectModel(String modelId) async {
    final provider = activeProvider;
    _message = null;
    _errorMessage = null;
    _modelErrorMessage = null;
    notifyListeners();

    try {
      await storage.saveSelectedModel(provider: provider, modelId: modelId);
      _settings = await storage.loadSettings();
      _message = 'Model saved';
    } catch (_) {
      _errorMessage = 'Model selection could not be saved.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshModels() {
    return _fetchModels(activeProvider);
  }

  Future<void> _fetchModelsIfNeeded(AiProvider provider) async {
    if (!_settings.isKeySaved(provider) || _modelCache.containsKey(provider)) {
      return;
    }

    await _fetchModels(provider);
  }

  Future<void> _fetchModels(AiProvider provider) async {
    if (!_settings.isKeySaved(provider)) {
      return;
    }

    final String? apiKey;
    try {
      apiKey = await storage.readApiKey(provider);
    } catch (_) {
      _modelErrorMessage =
          '${provider.label} API key could not be read. Try saving it again.';
      notifyListeners();
      return;
    }

    if (apiKey == null || apiKey.isEmpty) {
      return;
    }

    _isFetchingModels = true;
    _modelErrorMessage = null;
    notifyListeners();

    try {
      final models = await modelListingService.listModels(
        provider: provider,
        apiKey: apiKey,
      );
      _modelCache[provider] = models;
      if (models.isEmpty) {
        _modelErrorMessage =
            'No compatible ${provider.label} text/tool-capable models were found.';
      }
    } on ModelListingException catch (error) {
      _modelErrorMessage = error.message;
    } catch (_) {
      _modelErrorMessage =
          '${provider.label} models could not be loaded. Try again later.';
    } finally {
      _isFetchingModels = false;
      notifyListeners();
    }
  }
}
