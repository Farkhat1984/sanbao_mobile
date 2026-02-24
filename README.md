# Sanbao Mobile — Flutter AI Platform Client

Мобильный клиент (iOS + Android) для AI-платформы **Sanbao**. Пользовательская часть веб-приложения — весь функционал без админки.

**Версия:** 1.0.0 (build 4) | **API:** https://www.sanbao.ai | **TestFlight:** Загружен

## Быстрый старт

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run -d <device>
```

## Сборка

```bash
# iOS → TestFlight
flutter build ios --release
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -archivePath build/ios/Runner.xcarchive archive
xcodebuild -exportArchive -archivePath build/ios/Runner.xcarchive \
  -exportOptionsPlist build/ios/ExportOptions.plist -exportPath build/ios/export

# Android
flutter build apk            # APK
flutter build appbundle       # AAB для Play Store
```

## Архитектура

Clean Architecture + Riverpod 2.6.1 + GoRouter (28 маршрутов)

```
lib/
├── core/
│   ├── config/       # env.dart, routes.dart, app_config.dart (24 API endpoint)
│   ├── network/      # dio_client (retry + auth interceptor), ndjson_parser
│   ├── storage/      # secure_storage, local_db, preferences
│   ├── theme/        # Soft Corporate Minimalism (light + dark)
│   ├── widgets/      # 13 UI-kit компонентов
│   ├── errors/       # Failure union type, ErrorHandler + Sentry
│   └── l10n/         # ru (default), en
│
├── features/         # 19 фич-модулей
│   ├── auth/         # JWT, Google, Apple, 2FA
│   ├── chat/         # NDJSON стриминг, sanbao-doc парсинг, голос
│   ├── artifacts/    # Viewer, editor, export, версии
│   ├── agents/       # CRUD + AI-генерация
│   ├── skills/       # CRUD + маркетплейс
│   ├── tools/        # 4 типа (Template, Webhook, URL, Function)
│   ├── plugins/      # CRUD + enable/disable
│   ├── mcp/          # MCP-серверы CRUD + статус
│   ├── memory/       # AI-память с категориями
│   ├── tasks/        # Задачи с прогрессом
│   ├── knowledge/    # База знаний (файлы)
│   ├── billing/      # Подписки, тарифы, промокоды
│   ├── profile/      # Профиль, аватар
│   ├── settings/     # Тема, биометрия, 2FA, язык
│   ├── notifications/# Поллинг + bell
│   ├── image_gen/    # Генерация изображений AI
│   ├── code_fix/     # Исправление кода AI
│   ├── legal/        # Юр. статьи (19 кодексов РК)
│   └── onboarding/   # 4-шаговый онбординг
│
└── main.dart
```

## Статус фич (85% production-ready)

| Фича | % | Ключевое |
|------|---|----------|
| Чат + NDJSON стриминг | 95% | Streaming, reasoning, phases, attachments |
| Парсинг sanbao-doc тегов | 95% | `SanbaoTagParser` — артефакты + clarify |
| Артефакты viewer/editor | 85% | Preview, editor, code, export, версии |
| Inline artifact cards | 90% | Карточки в сообщениях с анимацией |
| Авторизация | 90% | JWT, Google, Apple, 2FA |
| Агенты | 90% | CRUD + AI-генерация |
| Навыки | 85% | CRUD + маркетплейс |
| Инструменты | 80% | CRUD по 4 типам |
| Плагины | 75% | Базовый CRUD |
| MCP-серверы | 80% | CRUD + статус |
| Память | 90% | CRUD + категории |
| Задачи | 85% | Список + прогресс + шаги |
| База знаний | 85% | Файлы CRUD |
| Биллинг | 70% | UI готов, нет Stripe/Freedom Pay |
| Профиль/Настройки | 95% | Полный набор |
| Уведомления | 80% | Polling (нет FCM push) |
| Генерация картинок | 75% | Промпт + стили |
| Юр. статьи | 85% | 19 кодексов, inline ссылки |

## Стек

| Категория | Технологии |
|-----------|-----------|
| Framework | Flutter 3.24+, Dart 3.5+ |
| State | Riverpod 2.6.1 (20 provider файлов, 4750 строк) |
| Navigation | GoRouter 14.6.2 (28 маршрутов) |
| Network | Dio 5.7 + NDJSON sealed classes |
| Models | Freezed + json_serializable (80+ моделей) |
| Storage | flutter_secure_storage, SharedPreferences, file cache |
| Firebase | firebase_core 3.8.1 |
| OAuth | google_sign_in 6.2, sign_in_with_apple 6.1 |
| Monitoring | Sentry Flutter 9.0 |
| L10n | intl 0.20.2 (ru, en) |

## Метрики

- **246** Dart-файлов
- **19** фич-модулей
- **32** экрана
- **13** core-виджетов
- **40+** datasource-классов
- **80+** моделей
- **9** тест-файлов

## Дизайн — Soft Corporate Minimalism

Фон: `#FAFBFD`/`#0F1219` | Акцент: `#4F6EF7`/`#6B8AFF` | Радиусы: 12/16/32px | Inter + JetBrains Mono
