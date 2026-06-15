import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hunk/app.dart';
import 'package:hunk/models/ai_model.dart';
import 'package:hunk/models/ai_chat_message.dart';
import 'package:hunk/models/ai_provider.dart';
import 'package:hunk/models/ai_settings.dart';
import 'package:hunk/models/context_entry.dart';
import 'package:hunk/models/context_matrix.dart';
import 'package:hunk/screens/context_web_screen.dart';
import 'package:hunk/services/ai_chat_service.dart';
import 'package:hunk/services/context_extraction_service.dart';
import 'package:hunk/services/context_missing_basics_detector.dart';
import 'package:hunk/services/context_repository.dart';
import 'package:hunk/services/context_summary_builder.dart';
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

  test('context entry serializes and restores metadata', () {
    final createdAt = DateTime.utc(2026, 6, 15, 12);
    final updatedAt = DateTime.utc(2026, 6, 15, 13);
    final entry = ContextEntry(
      id: 'ctx_1',
      section: ContextSection.goals,
      node: 'Running',
      parentId: 'ctx_parent',
      title: 'Primary fitness goal',
      value: 'Run a half marathon',
      source: ContextSource.chatExtracted,
      lifespan: ContextLifespan.longTerm,
      status: ContextStatus.active,
      confirmationState: ContextConfirmationState.confirmed,
      sensitivity: ContextSensitivity.personal,
      priority: 0.83,
      confidence: 0.7,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastUsedAt: updatedAt,
      expiresAt: DateTime.utc(2026, 6, 20),
      isPinned: true,
    );

    final restored = ContextEntry.fromJson(entry.toJson());

    expect(restored.id, 'ctx_1');
    expect(restored.section, ContextSection.goals);
    expect(restored.nodeLabel, 'Running');
    expect(restored.parentId, 'ctx_parent');
    expect(restored.source, ContextSource.chatExtracted);
    expect(restored.lifespan, ContextLifespan.longTerm);
    expect(restored.status, ContextStatus.active);
    expect(restored.confirmationState, ContextConfirmationState.confirmed);
    expect(restored.sensitivity, ContextSensitivity.personal);
    expect(restored.priority, 0.83);
    expect(restored.confidence, 0.7);
    expect(restored.createdAt, createdAt);
    expect(restored.updatedAt, updatedAt);
    expect(restored.lastUsedAt, updatedAt);
    expect(restored.expiresAt, DateTime.utc(2026, 6, 20));
    expect(restored.isPinned, isTrue);
  });

  test('context summary filters status, lifespan, and confirmation state', () {
    final now = DateTime.utc(2026, 6, 15);
    final summary =
        const ContextSummaryBuilder(maxEntries: 4, maxCharacters: 1600).build(
          ContextMatrix(
            entries: [
              ContextEntry(
                id: 'goal',
                section: ContextSection.goals,
                node: 'Running',
                title: 'Primary goal',
                value: 'Run a half marathon',
                source: ContextSource.userConfirmed,
                lifespan: ContextLifespan.permanent,
                confirmationState: ContextConfirmationState.confirmed,
                priority: 0.95,
                createdAt: now,
                updatedAt: now,
                isPinned: true,
              ),
              ContextEntry(
                id: 'today',
                section: ContextSection.currentState,
                node: 'Today',
                title: 'Energy',
                value: 'Low energy today',
                source: ContextSource.chatExtracted,
                lifespan: ContextLifespan.temporary,
                expiresAt: now.add(const Duration(hours: 8)),
                createdAt: now,
                updatedAt: now,
              ),
              ContextEntry(
                id: 'archived',
                section: ContextSection.healthConstraints,
                title: 'Old injury note',
                value: 'Archived value',
                source: ContextSource.manual,
                createdAt: now,
                updatedAt: now,
                isArchived: true,
              ),
              ContextEntry(
                id: 'deleted',
                section: ContextSection.preferences,
                title: 'Deleted preference',
                value: 'Do not send deleted context',
                source: ContextSource.manual,
                status: ContextStatus.deleted,
                createdAt: now,
                updatedAt: now,
              ),
              ContextEntry(
                id: 'rejected',
                section: ContextSection.preferences,
                title: 'Rejected preference',
                value: 'Do not send rejected context',
                source: ContextSource.chatExtracted,
                confirmationState: ContextConfirmationState.rejected,
                createdAt: now,
                updatedAt: now,
              ),
              ContextEntry(
                id: 'expired',
                section: ContextSection.currentState,
                title: 'Expired state',
                value: 'Do not send expired context',
                source: ContextSource.chatExtracted,
                lifespan: ContextLifespan.temporary,
                expiresAt: now.subtract(const Duration(minutes: 1)),
                createdAt: now,
                updatedAt: now,
              ),
            ],
          ),
          now: now,
        );

    expect(summary, contains('APP-STORED USER CONTEXT MATRIX'));
    expect(summary, contains('Primary goal: Run a half marathon'));
    expect(summary, contains('Energy: Low energy today'));
    expect(summary, contains('Missing basics to ask naturally'));
    expect(summary, contains('END APP-STORED USER CONTEXT MATRIX'));
    expect(summary, isNot(contains('Archived value')));
    expect(summary, isNot(contains('Do not send deleted context')));
    expect(summary, isNot(contains('Do not send rejected context')));
    expect(summary, isNot(contains('Do not send expired context')));
    expect(summary.length, lessThanOrEqualTo(1600));
  });

  test('missing basics detector reports only absent required basics', () {
    final now = DateTime.utc(2026, 6, 15);
    final missing = const ContextMissingBasicsDetector().missingBasics(
      ContextMatrix(
        entries: [
          ContextEntry(
            id: 'age',
            section: ContextSection.profile,
            node: 'Body',
            title: 'Age',
            value: '34',
            source: ContextSource.manual,
            createdAt: now,
            updatedAt: now,
          ),
          ContextEntry(
            id: 'goal',
            section: ContextSection.goals,
            node: 'Goals',
            title: 'Primary goal',
            value: 'Run a 5K',
            source: ContextSource.manual,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      now: now,
    );

    expect(missing.map((item) => item.title), isNot(contains('Age')));
    expect(missing.map((item) => item.title), isNot(contains('Primary goal')));
    expect(missing.map((item) => item.title), contains('Height'));
    expect(missing.map((item) => item.title), contains('Equipment/access'));
  });

  test('context extraction is conservative around manual entries', () {
    final now = DateTime.utc(2026, 6, 15);
    final existing = [
      ContextEntry(
        id: 'manual_age',
        section: ContextSection.profile,
        title: 'Age',
        value: '34',
        source: ContextSource.manual,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final extracted = const ContextExtractionService().extractFromUserMessage(
      message:
          "I'm 35 and my goal is to run a marathon. I have dumbbells at home.",
      existingEntries: existing,
      now: now,
    );

    expect(
      extracted.any(
        (entry) =>
            entry.section == ContextSection.profile && entry.title == 'Age',
      ),
      isFalse,
    );
    expect(
      extracted.any((entry) => entry.section == ContextSection.goals),
      isTrue,
    );
    expect(
      extracted.any((entry) => entry.section == ContextSection.equipmentAccess),
      isTrue,
    );
    expect(
      extracted.every((entry) => entry.source == ContextSource.chatExtracted),
      isTrue,
    );
    expect(
      extracted.any(
        (entry) =>
            entry.nodeLabel == 'Running' &&
            entry.lifespan == ContextLifespan.longTerm,
      ),
      isTrue,
    );
  });

  test('context extraction captures temporary current state safely', () {
    final now = DateTime.utc(2026, 6, 15, 9);

    final extracted = const ContextExtractionService().extractFromUserMessage(
      message:
          'Today my legs are sore and my energy is low, avoid heavy squats this week.',
      existingEntries: const [],
      now: now,
    );

    expect(
      extracted.any(
        (entry) =>
            entry.lifespan == ContextLifespan.temporary &&
            entry.expiresAt != null,
      ),
      isTrue,
    );
    expect(
      extracted.any((entry) => entry.sensitivity == ContextSensitivity.health),
      isTrue,
    );
  });

  test('context extraction parser accepts guarded JSON suggestions', () {
    final suggestions = const ContextExtractionService().parseSuggestionsJson(
      jsonEncode({
        'updates': [
          {
            'action': 'create',
            'node': 'Running',
            'key': '5K goal',
            'value': 'Improve 5K time',
            'lifespan': 'long_term',
            'sensitivity': 'normal',
            'confidence': 0.81,
            'reason': 'User stated a running goal',
          },
          {'action': 'create', 'node': 'Health'},
          {'action': 'nonsense'},
        ],
      }),
    );

    expect(suggestions, hasLength(1));
    expect(suggestions.single.action, ContextSuggestionAction.create);
    expect(suggestions.single.section, ContextSection.goals);
    expect(suggestions.single.node, 'Running');
    expect(suggestions.single.lifespan, ContextLifespan.longTerm);
    expect(suggestions.single.confidence, 0.81);
  });

  testWidgets('bottom navigation switches between shell screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      HunkApp(
        settingsStorage: FakeSettingsStorage(),
        modelListingService: FakeModelListingService(),
        chatService: FakeChatService(),
        contextRepository: FakeContextRepository(),
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
          contextRepository: FakeContextRepository(),
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
        contextRepository: FakeContextRepository(),
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
        contextRepository: FakeContextRepository(),
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
        contextRepository: FakeContextRepository(),
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

  testWidgets('coach chat renders assistant markdown', (
    WidgetTester tester,
  ) async {
    final chatService = FakeChatService(
      onSend: (_) async => '## Plan\n\n- **Easy run**\n- `Zone 2`',
    );

    await tester.pumpWidget(
      HunkApp(
        settingsStorage: FakeSettingsStorage(
          openAiApiKey: 'stored-openai-placeholder',
          openAiSelectedModel: 'gpt-5',
        ),
        modelListingService: FakeModelListingService(),
        chatService: chatService,
        contextRepository: FakeContextRepository(),
      ),
    );

    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('coach-chat-input')),
      'Give me a short plan.',
    );
    await tester.tap(find.byKey(const ValueKey('coach-chat-send-button')));
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
  });

  testWidgets('coach chat sends compact active context summary', (
    WidgetTester tester,
  ) async {
    final now = DateTime.utc(2026, 6, 15);
    final contextRepository = FakeContextRepository(
      ContextMatrix(
        entries: [
          ContextEntry(
            id: 'goal',
            section: ContextSection.goals,
            title: 'Primary fitness goal',
            value: 'Run a half marathon',
            source: ContextSource.manual,
            createdAt: now,
            updatedAt: now,
            isPinned: true,
          ),
          ContextEntry(
            id: 'old',
            section: ContextSection.healthConstraints,
            title: 'Old note',
            value: 'Archived context should not be sent',
            source: ContextSource.manual,
            createdAt: now,
            updatedAt: now,
            isArchived: true,
          ),
        ],
      ),
    );
    final chatService = FakeChatService();

    await tester.pumpWidget(
      HunkApp(
        settingsStorage: FakeSettingsStorage(
          openAiApiKey: 'stored-openai-placeholder',
          openAiSelectedModel: 'gpt-5',
        ),
        modelListingService: FakeModelListingService(),
        chatService: chatService,
        contextRepository: contextRepository,
      ),
    );

    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('coach-chat-input')),
      'What should I focus on?',
    );
    await tester.tap(find.byKey(const ValueKey('coach-chat-send-button')));
    await tester.pumpAndSettle();

    expect(
      chatService.calls.single.contextSummary,
      contains('Primary fitness goal: Run a half marathon'),
    );
    expect(
      chatService.calls.single.contextSummary,
      isNot(contains('Archived context should not be sent')),
    );
  });

  testWidgets('coach chat opens Context Web from fixed Matrix button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      HunkApp(
        settingsStorage: FakeSettingsStorage(
          openAiApiKey: 'stored-openai-placeholder',
          openAiSelectedModel: 'gpt-5',
        ),
        modelListingService: FakeModelListingService(),
        chatService: FakeChatService(),
        contextRepository: FakeContextRepository(),
      ),
    );

    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('coach-chat-context-button')),
      findsOneWidget,
    );
    expect(find.text('Matrix'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('coach-chat-context-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('context-network-chart')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('context-web-close-button')),
      findsOneWidget,
    );
    expect(find.text('Core'), findsWidgets);
  });

  testWidgets(
    'context matrix is fullscreen and hides raw metadata by default',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF237A57),
            ),
            useMaterial3: true,
          ),
          home: ContextWebScreen(repository: FakeContextRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('context-network-chart')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('context-matrix-infinite-backdrop')),
        findsOneWidget,
      );
      expect(find.text('Core'), findsWidgets);
      expect(find.text('Goals'), findsWidgets);
      expect(find.text('Age'), findsNothing);
      expect(find.text('Info Matrix'), findsNothing);
      expect(find.text('Complete profile'), findsNothing);
      expect(find.textContaining('confidence'), findsNothing);
      expect(find.textContaining('active'), findsNothing);
    },
  );

  testWidgets('context matrix node management opens details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF237A57)),
          useMaterial3: true,
        ),
        home: ContextWebScreen(repository: FakeContextRepository()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(
      find.byKey(const ValueKey('context-section-profile')).first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('context-detail-profile')),
      findsOneWidget,
    );
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Age'), findsWidgets);
  });

  testWidgets('context matrix shows only the clicked node subnodes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF237A57)),
          useMaterial3: true,
        ),
        home: ContextWebScreen(repository: FakeContextRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Age'), findsNothing);
    expect(find.text('Primary goal'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('context-section-profile')).first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Age'), findsWidgets);
    expect(find.text('Primary goal'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('context-section-goals')).first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Age'), findsNothing);
    expect(find.text('Primary goal'), findsWidgets);
  });

  testWidgets('context web renders and archives manual context', (
    WidgetTester tester,
  ) async {
    final repository = FakeContextRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF237A57)),
          useMaterial3: true,
        ),
        home: ContextWebScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('context-network-chart')), findsOneWidget);
    expect(find.text('Complete profile'), findsNothing);
    expect(find.text('Goals'), findsWidgets);
    expect(find.text('Nutrition'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('context-web-add-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('context-entry-title-field')),
      'Age',
    );
    await tester.enterText(
      find.byKey(const ValueKey('context-entry-value-field')),
      '34',
    );
    await tester.tap(find.byKey(const ValueKey('context-save-button')));
    await tester.pumpAndSettle();

    expect(repository.matrix.activeEntries.single.title, 'Age');
    expect(
      repository.matrix.activeEntries.single.source,
      ContextSource.userConfirmed,
    );

    await tester.longPress(
      find.byKey(const ValueKey('context-section-profile')).first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Archive').first);
    await tester.pumpAndSettle();

    expect(repository.matrix.activeEntries, isEmpty);
  });

  testWidgets('context web missing fields fit small iPhone screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF237A57)),
          useMaterial3: true,
        ),
        home: ContextWebScreen(repository: FakeContextRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Age'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('context-section-profile')).first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Age'), findsWidgets);
    expect(find.text('Primary goal'), findsNothing);
    expect(find.text('Complete profile'), findsNothing);
    expect(tester.takeException(), isNull);
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
        final systemMessage = input.first as Map<String, Object?>;
        expect(
          systemMessage['content'],
          contains('APP-STORED USER CONTEXT MATRIX'),
        );
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
      contextSummary: 'APP-STORED USER CONTEXT MATRIX\nGoals:\n- Run',
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
        final systemInstruction =
            body['systemInstruction'] as Map<String, Object?>;
        final systemParts = systemInstruction['parts'] as List;
        expect(
          (systemParts.first as Map<String, Object?>)['text'],
          contains('APP-STORED USER CONTEXT MATRIX'),
        );
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
      contextSummary: 'APP-STORED USER CONTEXT MATRIX\nGoals:\n- Run',
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
      contextRepository: FakeContextRepository(),
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
    String contextSummary = '',
  }) async {
    final call = FakeChatCall(
      provider: provider,
      apiKey: apiKey,
      modelId: modelId,
      messages: List.of(messages),
      contextSummary: contextSummary,
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
    required this.contextSummary,
  });

  final AiProvider provider;
  final String apiKey;
  final String modelId;
  final List<AiChatMessage> messages;
  final String contextSummary;
}

class FakeContextRepository implements ContextRepository {
  FakeContextRepository([ContextMatrix? matrix])
    : matrix = matrix ?? ContextMatrix.empty();

  ContextMatrix matrix;

  @override
  Future<ContextMatrix> loadMatrix() async {
    return matrix;
  }

  @override
  Future<void> saveMatrix(ContextMatrix matrix) async {
    this.matrix = matrix;
  }

  @override
  Future<ContextEntry> saveEntry(ContextEntry entry) async {
    final entries = [...matrix.entries];
    final index = entries.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
    matrix = ContextMatrix(entries: entries);
    return entry;
  }

  @override
  Future<void> archiveEntry(String entryId) async {
    final now = DateTime.utc(2026, 6, 15);
    matrix = ContextMatrix(
      entries: [
        for (final entry in matrix.entries)
          if (entry.id == entryId)
            entry.copyWith(status: ContextStatus.archived, updatedAt: now)
          else
            entry,
      ],
    );
  }

  @override
  Future<void> removeEntry(String entryId) async {
    matrix = ContextMatrix(
      entries: [
        for (final entry in matrix.entries)
          if (entry.id == entryId)
            entry.copyWith(status: ContextStatus.deleted)
          else
            entry,
      ],
    );
  }
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
