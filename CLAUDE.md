# CLAUDE.md — Sanbao Flutter Mobile Client

## ГЛАВНОЕ ПРАВИЛО

**Мы работаем ТОЛЬКО внутри `sanbao_flutter/`.** Файлы в `sanbao/` (веб-проект) мы **читаем как референс**, но **никогда не редактируем**.

Веб-проект `sanbao/` — это источник правды:
- Весь **функционал** берётся из веб-версии и адаптируется под мобайл
- Весь **дизайн** (токены, компоненты, анимации) повторяет веб-версию
- Все **API-эндпоинты** и стриминг-протокол идентичны веб-клиенту

**Мы делаем мобильную версию Sanbao БЕЗ функций администратора.** Не реализуем:
- Панель администратора
- Управление пользователями / ролями
- Системные настройки платформы
- Модерацию контента
- Управление биллингом / подписками (admin-сторона)
- Любые admin-only API-эндпоинты

Реализуем только пользовательский функционал: чат с AI, артефакты, агенты, навыки, профиль, настройки пользователя.

## Где искать референс

Когда нужно понять, как работает фича или API — смотри в веб-проект **только для чтения**:

| Что нужно | Где искать в `sanbao/` |
|-----------|----------------------|
| API-эндпоинты | `sanbao/src/app/api/` |
| Чат-стриминг | `sanbao/src/app/api/chat/route.ts` |
| Prisma-схема (модели данных) | `sanbao/prisma/schema.prisma` |
| Дизайн-токены | `sanbao/docs/STYLEGUIDE.md` |
| Компоненты UI | `sanbao/src/components/` |
| Авторизация | `sanbao/src/lib/auth/` |
| Типы и интерфейсы | `sanbao/src/types/` |
| Веб CLAUDE.md | `sanbao/CLAUDE.md` |

## Команды

```bash
cd sanbao_flutter

# Зависимости
flutter pub get

# Кодогенерация (после изменения @freezed / @JsonSerializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Запуск
flutter run -d <device>
flutter run --dart-define=API_BASE_URL=https://api.sanbao.ai

# Сборка
flutter build apk            # Android APK
flutter build appbundle       # Android App Bundle
flutter build ios             # iOS

# Тесты и анализ
flutter test
flutter analyze
```

## Архитектура

### Clean Architecture

```
lib/
├── core/                    # Общий слой
│   ├── config/              # env.dart (--dart-define), routes.dart (GoRouter)
│   ├── network/             # dio_client, api_interceptor, ndjson_parser, api_exceptions
│   ├── storage/             # secure_storage (токены), local_db (кэш), preferences
│   ├── theme/               # colors, typography, shadows, radius, animations
│   ├── widgets/             # UI-kit: SanbaoButton, SanbaoInput, SanbaoCard, GlassContainer...
│   ├── utils/               # extensions, validators, formatters, debouncer
│   ├── errors/              # failure.dart — Failure union type
│   └── l10n/                # app_ru.arb, app_en.arb
│
├── features/
│   ├── auth/                # Авторизация: login, register, 2FA, Google OAuth
│   ├── chat/                # Чат: стриминг, сообщения, файлы, беседы
│   ├── artifacts/           # Артефакты: документы, код, превью
│   ├── agents/              # AI-агенты: выбор, настройка
│   └── skills/              # Навыки: список, интеграция
│
└── main.dart                # ProviderScope, ErrorHandler, ориентация
```

### Каждая фича

```
features/<feature>/
  domain/        # Entities, abstract repos, use cases — чистый Dart, без зависимостей
  data/          # Models (Freezed + JSON), datasources (Dio), repo implementations
  presentation/  # Screens, widgets, Riverpod providers
```

### State Management — Riverpod 2.6.1

Используем `riverpod_generator` для кодогенерации провайдеров. Основные провайдеры:

- `authProvider` — состояние авторизации
- `chatProvider` — сообщения и NDJSON-стриминг
- `conversationsProvider` — список бесед
- `agentProvider` — выбор агента
- `artifactProvider` — артефакты
- `skillProvider` — навыки
- `fileProvider` — файловые вложения

### Стриминг-протокол (NDJSON)

Идентичен веб-клиенту:
- `POST /api/chat` → поток NDJSON-объектов `{t, v}`
- Типы: `c` (content), `r` (reasoning), `p` (plan), `s` (search status), `x` (context), `e` (error)
- Парсер: `lib/core/network/ndjson_parser.dart`
- Потребитель: `chatProvider`

### Кодогенерация

Freezed + json_serializable. После любых изменений в `@freezed` / `@JsonSerializable` классах:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Генерируемые файлы (`*.freezed.dart`, `*.g.dart`) в gitignore — всегда регенерировать после клонирования.

## Дизайн-система — Soft Corporate Minimalism

Полностью повторяет веб-версию. Референс: `sanbao/docs/STYLEGUIDE.md`.

| Токен | Значение |
|-------|---------|
| Фон light | #FAFBFD (никогда чистый белый) |
| Фон dark | #0F1219 (никогда чистый чёрный) |
| Акцент light | #4F6EF7 |
| Акцент dark | #6B8AFF |
| Радиус кнопок | 12px |
| Радиус карточек | 16px |
| Радиус чат-инпута | 32px |
| Основной шрифт | Inter |
| Шрифт кода | JetBrains Mono |
| Анимации | Spring: damping 25, stiffness 300 |
| Glassmorphism | backdrop-filter blur 16px |

## Окружение и внешние сервисы

### Нужно для мобилки (--dart-define)

Все внешние ключи передаются через `--dart-define` и читаются в `lib/core/config/env.dart`.

| Переменная | Сервис | Статус | Описание |
|-----------|--------|--------|---------|
| `API_BASE_URL` | Sanbao Backend | Есть (`https://sanbao.ai`) | Единый API для веба и мобайла |
| `GOOGLE_CLIENT_ID` | Google OAuth | **Нужно создать** | Отдельный Mobile Client ID в Google Cloud Console (iOS + Android) |
| `SENTRY_DSN` | Sentry | **Нужен отдельный** | Отдельный DSN от веб-проекта для мобильных крашей |
| `ENV` | — | Есть | `development` / `staging` / `production` |

### Платформенные конфиги (не --dart-define)

| Сервис | Файл | Статус | Описание |
|--------|------|--------|---------|
| Firebase / FCM | `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` | **Нужно создать** | Push-уведомления через Firebase Cloud Messaging |
| Apple Sign In | Xcode Capabilities + Apple Developer | **Нужно создать** | Обязательно для App Store если есть Google Login |
| Deep Links (Android) | `android/app/src/main/AndroidManifest.xml` | **Нужно настроить** | `intent-filter` для `sanbao.ai` |
| Deep Links (iOS) | `ios/Runner/Runner.entitlements` | **Нужно настроить** | Associated Domains для `sanbao.ai` |

### Нужна доработка на бэкенде (`sanbao/`)

Мобилка **зависит** от этих доработок (мы их не делаем, но должны знать):

| Что | Зачем | Текущий статус в `sanbao/` |
|-----|-------|--------------------------|
| Token-based auth (Bearer) | Мобилка не может использовать cookie-based NextAuth | Есть `src/lib/api-key-auth.ts` — нужно расширить |
| `POST /api/notifications/push` | Регистрация FCM-токена устройства | Нужно создать |
| `/.well-known/apple-app-site-association` | Universal Links для iOS | Нужно добавить на сервер |
| `/.well-known/assetlinks.json` | App Links для Android | Нужно добавить на сервер |

### НЕ нужно для мобилки (бэкенд/инфра)

Cloudflare, SMTP, Redis, PostgreSQL, MCP, FragmentDB, Telegram bot — всё это на стороне бэкенда. Мобилка просто обращается к `API_BASE_URL`.

### Для публикации (не влияет на разработку)

- Apple Developer ($99/год) — App Store, сертификаты, provisioning profiles
- Google Play Console ($25 единоразово) — Play Store, signing keys
- CodePush/EAS НЕ актуально — это React Native/Expo, для Flutter есть Shorebird (опционально)

## Ключевые паттерны

- **Env-конфигурация:** `Env.apiBaseUrl`, `Env.sentryDsn` — через `--dart-define`, никогда не хардкодить
- **Provider overrides:** `SharedPreferences` и `LocalDatabase` инициализируются в `main()` до `runApp()`, передаются через `ProviderScope.overrides`
- **Только портрет** на телефонах — блокировка ориентации в `main.dart`
- **Error handling:** `ErrorHandler.initialize()` — Sentry + Flutter error zone
- **Offline-first:** `LocalDatabase` (файловый кэш) для бесед/сообщений
- **Авторизация:** JWT-токены в `flutter_secure_storage`, auto-refresh через interceptor

## Локализация

- Русский (по умолчанию) и English
- ARB-файлы: `lib/core/l10n/app_ru.arb`, `lib/core/l10n/app_en.arb`
- Конфиг: `l10n.yaml`
- Пакет: `intl: ^0.20.2`
- Весь UI-текст по умолчанию на русском

## Зависимости (ключевые)

| Пакет | Версия | Назначение |
|-------|--------|-----------|
| flutter_riverpod | ^2.6.1 | State management |
| go_router | ^14.6.2 | Навигация |
| dio | ^5.7.0 | HTTP-клиент |
| freezed | ^2.5.7 | Иммутабельные модели |
| flutter_secure_storage | ^9.2.2 | Безопасное хранение токенов |
| flutter_markdown | ^0.7.4+3 | Рендеринг Markdown |
| google_sign_in | ^6.2.2 | OAuth авторизация |
| sentry_flutter | ^9.0.0 | Трекинг ошибок |
| speech_to_text | ^7.0.0 | Голосовой ввод |
| flutter_animate | ^4.5.0 | Анимации |

## Рабочий процесс

1. **Новая фича** — сначала изучи реализацию в `sanbao/` (только чтение), затем реализуй в `sanbao_flutter/` по Clean Architecture
2. **Новый API-вызов** — сверься с `sanbao/src/app/api/` для эндпоинта, типов запроса/ответа
3. **Новый UI-компонент** — сверься с `sanbao/src/components/` и `STYLEGUIDE.md` для дизайна
4. **Модели данных** — сверься с `sanbao/prisma/schema.prisma` для структуры
5. **Никогда** не реализуй admin-функционал — только пользовательские фичи
