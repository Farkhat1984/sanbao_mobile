# CLAUDE.md — Sanbao Flutter Mobile Client

## ГЛАВНОЕ ПРАВИЛО

Рабочая директория: `sanbao_mobile/`. Веб-проект `sanbao/` — источс правды, читаем как референс, не редактируем.

Только пользовательский функционал. НЕ реализуем: админку, управление ролями, системные настройки, модерацию.

## Текущее состояние: 85% production-ready

Проект НЕ scaffold — большинство фич полностью реализованы с реальной API интеграцией.
**Парсинг `<sanbao-doc>` тегов РЕАЛИЗОВАН** в `SanbaoTagParser`.
Полный аудит: `docs/AUDIT.md` | Маппинг веб→мобайл: `docs/react_to_flutter.md`

## Референс (только чтение)

| Что | Где в `sanbao/` |
|-----|----------------|
| API-эндпоинты | `src/app/api/` |
| Чат + стриминг | `src/app/api/chat/route.ts` |
| Prisma-схема | `prisma/schema.prisma` |
| Артефакты UI | `src/components/artifacts/`, `src/components/panel/` |
| Artifact store | `src/stores/artifactStore.ts` |
| Парсинг тегов | `src/components/chat/MessageBubble.tsx` |
| Типы | `src/types/chat.ts` |
| Системный промпт | `src/app/api/chat/route.ts` (строки 212-340) |
| Дизайн | `docs/STYLEGUIDE.md` |

## Команды

```bash
flutter pub get                                                    # Зависимости
flutter pub run build_runner build --delete-conflicting-outputs    # Кодогенерация
flutter run -d <device>                                            # Запуск
flutter build ios --release                                        # iOS билд
flutter build apk                                                  # Android APK
flutter analyze                                                    # Анализ
flutter test                                                       # Тесты
```

## Архитектура

```
lib/
├── core/
│   ├── config/
│   │   ├── env.dart            # --dart-define (API_BASE_URL, SENTRY_DSN, etc.)
│   │   ├── routes.dart         # GoRouter, 28 маршрутов, auth guard
│   │   └── app_config.dart     # 24 API endpoint, timeouts, limits
│   ├── network/
│   │   ├── dio_client.dart     # HTTP + retry + auth interceptor + streaming
│   │   ├── ndjson_parser.dart  # Sealed classes: Content/Reasoning/Plan/Status/Context/Error
│   │   └── api_exceptions.dart # Exception → Failure mapping
│   ├── storage/                # secure_storage, local_db, preferences
│   ├── theme/                  # colors, typography, shadows, radius
│   ├── widgets/                # 13 UI-kit виджетов
│   ├── errors/                 # Failure union, ErrorHandler + Sentry
│   └── l10n/                   # ru (default), en
│
├── features/                   # 19 модулей, каждый: domain/ + data/ + presentation/
└── main.dart                   # Firebase init (try-catch), ProviderScope
```

## Ключевые реализации

### NDJSON Стриминг
- `ndjson_parser.dart` — sealed class `ChatEvent` с 6 типами
- `chat_remote_datasource.dart` — `postStream` через Dio + CancelToken
- `chat_provider.dart` — `ChatController._handleEvent()` обрабатывает каждый тип

Типы стрима: `c` (content), `r` (reasoning), `p` (plan), `s` (status), `x` (context), `e` (error)

### Парсинг Sanbao-тегов ✅ РЕАЛИЗОВАН
- `chat_event_model.dart` → `SanbaoTagParser`
- Парсит: `<sanbao-doc>`, `<sanbao-clarify>`
- `finishStreaming()` вызывает `SanbaoTagParser.extractArtifacts()`
- Артефакты отображаются через `ArtifactCard` виджет в message bubble

```dart
// SanbaoTagParser — уже работает:
static final RegExp artifactPattern = RegExp(
  r'<sanbao-doc\s+type="([^"]*?)"\s+title="([^"]*?)">([\s\S]*?)</sanbao-doc>',
);
```

### Артефакты
- **Viewer**: `artifact_view_screen.dart` — tabs: Preview/Editor/Source
- **Editor**: `document_editor.dart` — markdown toolbar, auto-save
- **Code**: `code_preview.dart` — line numbers, language detection
- **Export**: `export_menu.dart` — PDF, DOCX, MD, TXT, HTML
- **Versions**: `version_selector.dart` + API integration
- **Provider**: `artifact_provider.dart` — current artifact, tab state, versions

### Авторизация
- JWT в `flutter_secure_storage` + auto-refresh через interceptor
- `POST /api/auth/login` — email/password
- `POST /api/auth/mobile/google` — Google OAuth (native)
- `POST /api/auth/apple` — Apple Sign In
- `POST /api/auth/2fa/*` — TOTP setup/verify/enable/disable

## Фичи: статус

| Фича | Dir | % | Что не доделано |
|------|-----|---|-----------------|
| auth | `features/auth/` | 90% | WhatsApp, password reset |
| chat | `features/chat/` | 95% | — |
| artifacts | `features/artifacts/` | 85% | `<sanbao-edit>` apply, syntax highlighting |
| agents | `features/agents/` | 90% | — |
| skills | `features/skills/` | 85% | — |
| tools | `features/tools/` | 80% | test tool execution |
| plugins | `features/plugins/` | 75% | marketplace |
| mcp | `features/mcp/` | 80% | test connection |
| memory | `features/memory/` | 90% | — |
| tasks | `features/tasks/` | 85% | cancel, retry |
| knowledge | `features/knowledge/` | 85% | — |
| billing | `features/billing/` | 70% | **Stripe/Freedom Pay** |
| profile | `features/profile/` | 90% | — |
| settings | `features/settings/` | 95% | — |
| notifications | `features/notifications/` | 80% | **FCM push** |
| image_gen | `features/image_gen/` | 75% | history |
| code_fix | `features/code_fix/` | 70% | diff view |
| legal | `features/legal/` | 85% | — |
| onboarding | `features/onboarding/` | 90% | — |

## Что НЕ реализовано (vs веб)

### Критично (P0)
- `<sanbao-edit>` — auto apply search/replace в артефактах (парсинг есть, применение нет)
- Stripe/Freedom Pay — платежи (UI готов, интеграция нет)
- FCM push notifications (polling работает)

### Важно (P1)
- `<sanbao-task>` — чеклисты из стрима
- Password reset flow
- WhatsApp auth
- Syntax highlighting для CODE артефактов
- MCP test connection
- IMAGE артефакты (base64 рендеринг)

### Низкий приоритет (P2)
- Plugin marketplace
- Tool testing
- Task cancel/retry
- Code execution в preview (WebView)
- Image generation history
- Voice output (TTS)

## Веб → Мобайл различия

| Аспект | Веб (React) | Мобайл (Flutter) |
|--------|-------------|------------------|
| Артефакт panel | Side panel (resizable) | Fullscreen push route |
| State mgmt | Zustand stores | Riverpod providers |
| Streaming | fetch + ReadableStream | Dio postStream + StreamController |
| Rich editor | Tiptap v3 | Custom markdown toolbar |
| Code execution | iframe (React/Python) | Только просмотр кода |
| Auth | NextAuth (cookie) | JWT Bearer (secure_storage) |
| Notifications | HTTP polling | HTTP polling (FCM нужен) |
| Export PDF | html2canvas + jsPDF | `printing` package (native) |
| Billing | Stripe Checkout (redirect) | Нужна мобильная интеграция |

## Окружение

| Переменная | Default | Описание |
|-----------|---------|---------|
| `API_BASE_URL` | `https://www.sanbao.ai` | API бэкенда |
| `GOOGLE_CLIENT_ID` | — | Mobile OAuth Client ID |
| `SENTRY_DSN` | — | Мобильные краши |
| `ENV` | `development` | dev / staging / prod |

| Платформенный конфиг | Статус |
|---------------------|--------|
| `ios/Runner/GoogleService-Info.plist` | ✅ Есть |
| `android/app/google-services.json` | ❌ Нужно |
| iOS Signing (Team MCMQHQ6XT9) | ✅ Настроен |
| Bundle ID | `com.sanbao.mobile.sanbaoFlutter` |

## Паттерны

- **Env**: `Env.apiBaseUrl` через `--dart-define`, никогда хардкод
- **Provider overrides**: SharedPreferences + LocalDatabase init в main()
- **Только портрет** на телефонах
- **Firebase init** в try-catch (не блокирует запуск)
- **Error zone**: `ErrorHandler.initialize()` → Sentry + Flutter zones
- **Offline**: `LocalDatabase` кэш бесед/сообщений
- **JWT**: auto-refresh через interceptor, retry 3x
- **Sealed classes**: ChatEvent, Failure — для type-safe pattern matching
