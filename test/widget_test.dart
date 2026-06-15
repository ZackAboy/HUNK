import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hunk/app.dart';
import 'package:hunk/models/ai_model.dart';
import 'package:hunk/models/ai_chat_message.dart';
import 'package:hunk/models/ai_provider.dart';
import 'package:hunk/models/ai_settings.dart';
import 'package:hunk/services/ai_chat_service.dart';
import 'package:hunk/services/gemini_chat_service.dart';
import 'package:hunk/services/gemini_model_listing_service.dart';
import 'package:hunk/services/model_listing_service.dart';
import 'package:hunk/services/openai_chat_service.dart';
import 'package:hunk/services/openai_model_listing_service.dart';
import 'package:hunk/services/settings_storage.dart';

void main() {
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('bottom navigation switches between shell screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      HunkApp(
        settingsStorage: FakeSettingsStorage(),
        modelListingService: FakeModelListingService(),
        chatService: FakeChatService(),
      ),
    );

    expect(find.text('AI fitness coach'), findsOneWidget);

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();
    expect(find.text('Health data sources'), findsOneWidget);

    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Ask the coach a question to test your selected provider and model.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('AI provider settings'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Daily snapshot'), findsOneWidget);
  });

  testWidgets('only selected provider API key field is shown', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);

    expect(find.byKey(const ValueKey('openai-api-key-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('gemini-api-key-field')), findsNothing);

    await tester.tap(find.text('Google Gemini'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('openai-api-key-field')), findsNothing);
    expect(find.byKey(const ValueKey('gemini-api-key-field')), findsOneWidget);
  });

  testWidgets('paste saves selected provider key and shows model dropdown', (
    WidgetTester tester,
  ) async {
    final storage = FakeSettingsStorage();
    final modelService = FakeModelListingService();
    await _pumpSettings(tester, storage: storage, modelService: modelService);
    _mockClipboard('placeholder-openai-value');

    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save API key'));
    await tester.pumpAndSettle();

    expect(find.text('Settings saved'), findsOneWidget);
    expect(find.text('OpenAI API key saved'), findsOneWidget);
    expect(find.byKey(const ValueKey('openai-api-key-field')), findsNothing);
    expect(find.byKey(const ValueKey('openai-model-dropdown')), findsOneWidget);
    expect(find.text('placeholder-openai-value'), findsNothing);
    expect(storage.openAiKeySaved, isTrue);
    expect(modelService.calls, [AiProvider.openAi]);
  });

  testWidgets('saved key state hides input field', (WidgetTester tester) async {
    await _pumpSettings(
      tester,
      storage: FakeSettingsStorage(openAiApiKey: 'stored-placeholder'),
    );

    expect(find.text('OpenAI API key saved'), findsOneWidget);
    expect(find.byKey(const ValueKey('openai-api-key-field')), findsNothing);
    expect(find.byKey(const ValueKey('openai-model-dropdown')), findsOneWidget);
  });

  testWidgets('remove key affects only selected provider', (
    WidgetTester tester,
  ) async {
    final storage = FakeSettingsStorage(
      openAiApiKey: 'stored-openai-placeholder',
      geminiApiKey: 'stored-gemini-placeholder',
    );
    await _pumpSettings(tester, storage: storage);

    await tester.tap(find.text('Google Gemini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove API key'));
    await tester.pumpAndSettle();

    expect(find.text('Google Gemini API key not saved'), findsOneWidget);
    expect(storage.openAiKeySaved, isTrue);
    expect(storage.geminiKeySaved, isFalse);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OpenAI'));
    await tester.pumpAndSettle();

    expect(find.text('OpenAI API key saved'), findsOneWidget);
  });

  testWidgets('selected model is stored and updated', (
    WidgetTester tester,
  ) async {
    final storage = FakeSettingsStorage(openAiApiKey: 'stored-placeholder');
    await _pumpSettings(tester, storage: storage);

    await tester.tap(find.byKey(const ValueKey('openai-model-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('gpt-5').last);
    await tester.pumpAndSettle();

    expect(storage.openAiSelectedModel, 'gpt-5');
    expect(find.text('Model saved'), findsOneWidget);
  });

  testWidgets('long model names fit in the settings dropdown', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const longModelName =
        'gpt-5.4-super-long-text-tool-capable-model-name-for-small-iphone-screens';
    await _pumpSettings(
      tester,
      storage: FakeSettingsStorage(
        openAiApiKey: 'stored-placeholder',
        openAiSelectedModel: longModelName,
      ),
      modelService: FakeModelListingService(
        openAiModels: [
          AiModel(
            provider: AiProvider.openAi,
            id: longModelName,
            displayName: longModelName,
          ),
        ],
      ),
    );

    expect(find.byKey(const ValueKey('openai-model-dropdown')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty clipboard is handled without saving', (
    WidgetTester tester,
  ) async {
    final storage = FakeSettingsStorage();
    await _pumpSettings(tester, storage: storage);
    _mockClipboard('');

    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();

    expect(find.text('Clipboard is empty'), findsOneWidget);
    expect(storage.openAiKeySaved, isFalse);
  });

  testWidgets(
    'coach chat sends with selected provider model and shows response',
    (WidgetTester tester) async {
      final responseCompleter = Completer<String>();
      final storage = FakeSettingsStorage(
        openAiApiKey: 'stored-openai-placeholder',
        openAiSelectedModel: 'gpt-5',
      );
      final chatService = FakeChatService(
        onSend: (_) => responseCompleter.future,
      );

      await tester.pumpWidget(
        HunkApp(
          settingsStorage: storage,
          modelListingService: FakeModelListingService(),
          chatService: chatService,
        ),
      );

      await tester.tap(find.text('Coach'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('coach-chat-input')),
        'How should I train today?',
      );
      await tester.tap(find.byKey(const ValueKey('coach-chat-send-button')));
      await tester.pump();

      expect(find.text('How should I train today?'), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(chatService.calls.single.provider, AiProvider.openAi);
      expect(chatService.calls.single.modelId, 'gpt-5');
      expect(chatService.calls.single.apiKey, 'stored-openai-placeholder');

      responseCompleter.complete('Keep it easy today.');
      await tester.pumpAndSettle();

      expect(find.text('Keep it easy today.'), findsOneWidget);
    },
  );

  testWidgets('coach chat shows missing selected model error', (
    WidgetTester tester,
  ) async {
    final chatService = FakeChatService();

    await tester.pumpWidget(
      HunkApp(
        settingsStorage: FakeSettingsStorage(
          openAiApiKey: 'stored-openai-placeholder',
        ),
        modelListingService: FakeModelListingService(),
        chatService: chatService,
      ),
    );

    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('coach-chat-input')),
      'Can I do intervals?',
    );
    await tester.tap(find.byKey(const ValueKey('coach-chat-send-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No OpenAI model is selected. Open Settings, refresh models, and choose a model.',
      ),
      findsOneWidget,
    );
    expect(chatService.calls, isEmpty);
  });

  testWidgets('coach chat shows missing API key error', (
    WidgetTester tester,
  ) async {
    final chatService = FakeChatService();

    await tester.pumpWidget(
      HunkApp(
        settingsStorage: FakeSettingsStorage(openAiSelectedModel: 'gpt-5'),
        modelListingService: FakeModelListingService(),
        chatService: chatService,
      ),
    );

    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('coach-chat-input')),
      'Can I lift today?',
    );
    await tester.tap(find.byKey(const ValueKey('coach-chat-send-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('No OpenAI API key is saved. Add one in Settings.'),
      findsOneWidget,
    );
    expect(chatService.calls, isEmpty);
  });

  testWidgets('coach chat shows API failure error', (
    WidgetTester tester,
  ) async {
    final chatService = FakeChatService(
      onSend: (_) async =>
          throw const AiChatException('OpenAI request failed with status 401.'),
    );

    await tester.pumpWidget(
      HunkApp(
        settingsStorage: FakeSettingsStorage(
          openAiApiKey: 'stored-openai-placeholder',
          openAiSelectedModel: 'gpt-5',
        ),
        modelListingService: FakeModelListingService(),
        chatService: chatService,
      ),
    );

    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('coach-chat-input')),
      'Can I lift today?',
    );
    await tester.tap(find.byKey(const ValueKey('coach-chat-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Can I lift today?'), findsOneWidget);
    expect(find.text('OpenAI request failed with status 401.'), findsOneWidget);
  });

  test(
    'OpenAI model listing filters to text/tool-capable candidates',
    () async {
      final service = OpenAiModelListingService(
        client: MockClient((request) async {
          expect(request.url.host, 'api.openai.com');
          expect(request.headers['Authorization'], 'Bearer test-key');

          return http.Response(
            jsonEncode({
              'data': [
                {'id': 'gpt-5.4'},
                {'id': 'gpt-image-2'},
                {'id': 'gpt-3.5-turbo'},
                {'id': 'text-embedding-3-large'},
                {'id': 'chatgpt-4o-latest'},
                {'id': 'gpt-realtime-2'},
                {'id': 'o3-mini'},
              ],
            }),
            200,
          );
        }),
      );

      final models = await service.listModels(apiKey: 'test-key');

      expect(models.map((model) => model.id), [
        'chatgpt-4o-latest',
        'gpt-5.4',
        'o3-mini',
      ]);
    },
  );

  test(
    'Gemini model listing filters to generateContent text candidates',
    () async {
      final service = GeminiModelListingService(
        client: MockClient((request) async {
          expect(request.url.host, 'generativelanguage.googleapis.com');
          expect(request.url.queryParameters['key'], 'test-key');

          return http.Response(
            jsonEncode({
              'models': [
                {
                  'name': 'models/gemini-3-pro',
                  'baseModelId': 'gemini-3-pro',
                  'displayName': 'Gemini 3 Pro',
                  'description': 'Text reasoning model with function calling.',
                  'supportedGenerationMethods': ['generateContent'],
                },
                {
                  'name': 'models/gemini-3-flash',
                  'baseModelId': 'gemini-3-flash',
                  'displayName': 'Gemini 3 Flash',
                  'description': 'Fast text model with tool support.',
                  'supportedGenerationMethods': ['generateContent'],
                },
                {
                  'name': 'models/text-embedding-004',
                  'baseModelId': 'text-embedding-004',
                  'displayName': 'Text Embedding 004',
                  'description': 'Embedding model.',
                  'supportedGenerationMethods': ['embedContent'],
                },
                {
                  'name': 'models/gemma-3-27b-it',
                  'baseModelId': 'gemma-3-27b-it',
                  'displayName': 'Gemma 3 27B',
                  'description': 'Open model for text generation.',
                  'supportedGenerationMethods': ['generateContent'],
                },
                {
                  'name': 'models/imagen-5',
                  'baseModelId': 'imagen-5',
                  'displayName': 'Imagen 5',
                  'description': 'Image generation model.',
                  'supportedGenerationMethods': ['generateContent'],
                },
                {
                  'name': 'models/gemini-live-3',
                  'baseModelId': 'gemini-live-3',
                  'displayName': 'Gemini Live 3',
                  'description': 'Realtime live audio model.',
                  'supportedGenerationMethods': ['generateContent'],
                },
              ],
            }),
            200,
          );
        }),
      );

      final models = await service.listModels(apiKey: 'test-key');

      expect(models.map((model) => model.id), [
        'gemini-3-flash',
        'gemini-3-pro',
      ]);
    },
  );

  test('OpenAI chat service maps request and parses output text', () async {
    final service = OpenAiChatService(
      client: MockClient((request) async {
        expect(request.url.host, 'api.openai.com');
        expect(request.url.path, '/v1/responses');
        expect(request.headers['Authorization'], 'Bearer test-key');

        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['model'], 'gpt-5');
        expect(body['store'], isFalse);

        final input = body['input'] as List;
        expect(input.last, {'role': 'user', 'content': 'Hello coach'});

        return http.Response(
          jsonEncode({'output_text': 'Hello from OpenAI'}),
          200,
        );
      }),
    );

    final response = await service.sendMessage(
      apiKey: 'test-key',
      modelId: 'gpt-5',
      messages: const [AiChatMessage.user('Hello coach')],
    );

    expect(response, 'Hello from OpenAI');
  });

  test('Gemini chat service maps request and parses candidate text', () async {
    final service = GeminiChatService(
      client: MockClient((request) async {
        expect(request.url.host, 'generativelanguage.googleapis.com');
        expect(request.url.path, '/v1beta/models/gemini-3-pro:generateContent');
        expect(request.url.queryParameters['key'], 'test-key');

        final body = jsonDecode(request.body) as Map<String, Object?>;
        final contents = body['contents'] as List;
        expect(contents.last, {
          'role': 'user',
          'parts': [
            {'text': 'Hello coach'},
          ],
        });

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Hello from Gemini'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final response = await service.sendMessage(
      apiKey: 'test-key',
      modelId: 'gemini-3-pro',
      messages: const [AiChatMessage.user('Hello coach')],
    );

    expect(response, 'Hello from Gemini');
  });
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  FakeSettingsStorage? storage,
  FakeModelListingService? modelService,
}) async {
  await tester.pumpWidget(
    HunkApp(
      settingsStorage: storage ?? FakeSettingsStorage(),
      modelListingService: modelService ?? FakeModelListingService(),
      chatService: FakeChatService(),
    ),
  );

  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
}

void _mockClipboard(String text) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
        if (methodCall.method == 'Clipboard.getData') {
          return {'text': text};
        }

        return null;
      });
}

class FakeChatService implements AiChatService {
  FakeChatService({this.onSend});

  final Future<String> Function(FakeChatCall call)? onSend;
  final List<FakeChatCall> calls = [];

  @override
  Future<String> sendMessage({
    required AiProvider provider,
    required String apiKey,
    required String modelId,
    required List<AiChatMessage> messages,
  }) async {
    final call = FakeChatCall(
      provider: provider,
      apiKey: apiKey,
      modelId: modelId,
      messages: List.of(messages),
    );
    calls.add(call);

    return onSend?.call(call) ?? 'Placeholder coach response';
  }
}

class FakeChatCall {
  const FakeChatCall({
    required this.provider,
    required this.apiKey,
    required this.modelId,
    required this.messages,
  });

  final AiProvider provider;
  final String apiKey;
  final String modelId;
  final List<AiChatMessage> messages;
}

class FakeModelListingService implements ModelListingService {
  FakeModelListingService({
    List<AiModel>? openAiModels,
    List<AiModel>? geminiModels,
  }) : openAiModels =
           openAiModels ??
           const [
             AiModel(
               provider: AiProvider.openAi,
               id: 'gpt-5',
               displayName: 'gpt-5',
             ),
             AiModel(
               provider: AiProvider.openAi,
               id: 'gpt-5-mini',
               displayName: 'gpt-5-mini',
             ),
           ],
       geminiModels =
           geminiModels ??
           const [
             AiModel(
               provider: AiProvider.gemini,
               id: 'gemini-3.5-flash',
               displayName: 'Gemini 3.5 Flash',
             ),
           ];

  final List<AiProvider> calls = [];
  final List<AiModel> openAiModels;
  final List<AiModel> geminiModels;

  @override
  Future<List<AiModel>> listModels({
    required AiProvider provider,
    required String apiKey,
  }) async {
    calls.add(provider);

    return switch (provider) {
      AiProvider.openAi => openAiModels,
      AiProvider.gemini => geminiModels,
    };
  }
}

class FakeSettingsStorage implements SettingsStorage {
  FakeSettingsStorage({
    this.activeProvider = AiProvider.openAi,
    this.openAiApiKey,
    this.geminiApiKey,
    this.openAiSelectedModel,
    this.geminiSelectedModel,
  });

  AiProvider activeProvider;
  String? openAiApiKey;
  String? geminiApiKey;
  String? openAiSelectedModel;
  String? geminiSelectedModel;

  bool get openAiKeySaved => openAiApiKey != null;
  bool get geminiKeySaved => geminiApiKey != null;

  @override
  Future<AiSettings> loadSettings() async {
    return AiSettings(
      activeProvider: activeProvider,
      openAiKeySaved: openAiKeySaved,
      geminiKeySaved: geminiKeySaved,
      openAiSelectedModel: openAiSelectedModel,
      geminiSelectedModel: geminiSelectedModel,
    );
  }

  @override
  Future<String?> readApiKey(AiProvider provider) async {
    return switch (provider) {
      AiProvider.openAi => openAiApiKey,
      AiProvider.gemini => geminiApiKey,
    };
  }

  @override
  Future<void> removeApiKey(AiProvider provider) async {
    switch (provider) {
      case AiProvider.openAi:
        openAiApiKey = null;
        openAiSelectedModel = null;
      case AiProvider.gemini:
        geminiApiKey = null;
        geminiSelectedModel = null;
    }
  }

  @override
  Future<void> saveActiveProvider(AiProvider provider) async {
    activeProvider = provider;
  }

  @override
  Future<void> saveApiKey({
    required AiProvider provider,
    required String apiKey,
  }) async {
    switch (provider) {
      case AiProvider.openAi:
        openAiApiKey = apiKey;
        openAiSelectedModel = null;
      case AiProvider.gemini:
        geminiApiKey = apiKey;
        geminiSelectedModel = null;
    }
  }

  @override
  Future<void> saveSelectedModel({
    required AiProvider provider,
    required String modelId,
  }) async {
    switch (provider) {
      case AiProvider.openAi:
        openAiSelectedModel = modelId;
      case AiProvider.gemini:
        geminiSelectedModel = modelId;
    }
  }
}
