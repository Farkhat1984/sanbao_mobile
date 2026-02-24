# Полный аудит Sanbao Mobile vs Sanbao Web — Февраль 2026

## Общая готовность: 85%

246 Dart-файлов, 19 фич-модулей, 32 экрана, 20 provider-файлов (4750 строк).
Проект НЕ scaffold — большинство фич полностью реализованы с API-интеграцией.

---

## Веб: полный список пользовательских фич

### Модели данных (Prisma)
- User, Conversation, Message, Artifact, LegalReference, Attachment
- Agent, Skill, Tool, Plugin, McpServer
- Task, UserMemory, UserFile, Scratchpad
- ConversationSummary, ConversationPlan
- Plan, Subscription, DailyUsage, Payment, PromoCode
- Notification, FileUpload

### API эндпоинты (пользовательские)
```
POST   /api/chat                         ← NDJSON streaming
GET    /api/conversations                 GET/POST/PUT/DELETE CRUD
GET    /api/conversations/[id]/messages   Paginated messages

GET/POST       /api/agents               CRUD
GET/PUT/DELETE /api/agents/[id]
GET/POST/DELETE /api/agents/[id]/files    Agent context files
POST           /api/agents/generate       AI-generate agent

GET/POST       /api/skills               CRUD
GET/PUT/DELETE /api/skills/[id]
POST           /api/skills/[id]/clone     Clone public skill
POST           /api/skills/generate       AI-generate skill

GET/POST       /api/tools                CRUD
GET/PUT/DELETE /api/tools/[id]
GET/POST       /api/plugins              CRUD
GET/PUT/DELETE /api/plugins/[id]

GET/POST       /api/mcp                  CRUD
GET/PUT/DELETE /api/mcp/[id]
POST           /api/mcp/[id]/connect     Connect + discover tools
POST           /api/mcp/[id]/disconnect

GET/POST       /api/tasks                CRUD
GET/PUT/DELETE /api/tasks/[id]

GET/POST       /api/memory               CRUD
GET/PUT/DELETE /api/memory/[id]

GET/POST       /api/user-files           Knowledge base (max 20, 100KB)
GET/PUT/DELETE /api/user-files/[id]

GET    /api/billing/plans                Available plans
GET    /api/billing/current              Current subscription + usage
POST   /api/billing/checkout             Stripe checkout session
POST   /api/billing/webhook              Stripe webhook
POST   /api/billing/apply-promo          Promo code
POST   /api/billing/freedom/checkout     Freedom Pay
POST   /api/billing/freedom/webhook      Freedom Pay webhook

POST   /api/image-generate               Image from prompt (5/min limit)
POST   /api/image-edit                   Edit image with mask
POST   /api/fix-code                     AI code fix

GET/PUT /api/notifications               Fetch + mark read
PUT    /api/user/avatar                  Upload avatar
PUT    /api/user/locale                  Set locale
POST   /api/files/parse                  Extract text (PDF, DOCX, XLSX)
POST   /api/reports                      Report content

POST   /api/auth/login                   Email/password
POST   /api/auth/register                Signup
POST   /api/auth/apple                   Apple Sign In
POST   /api/auth/mobile/google           Google OAuth mobile
POST   /api/auth/2fa                     2FA TOTP setup/verify
GET    /api/auth/me                      Current user
```

### Стриминг протокол
- NDJSON `{t, v}`: c (content), r (reasoning), p (plan), s (status), x (context), e (error)
- Status phases: thinking → searching → using_tool → planning → answering
- Priority system: higher phase can't downgrade

### 14 Native Tools (серверные, вызываются AI)
http_request, get_current_time, get_user_info, get_conversation_context,
create_task, save_memory, send_notification, write_scratchpad, read_scratchpad,
calculate, analyze_csv, read_knowledge, search_knowledge, generate_chart_data

### Artifact Types
CONTRACT, CLAIM, COMPLAINT, DOCUMENT, CODE, ANALYSIS, IMAGE

### Sanbao-теги (в системном промпте)
```html
<sanbao-doc type="TYPE" title="Title">content</sanbao-doc>
<sanbao-edit target="Title"><replace><old>...</old><new>...</new></replace></sanbao-edit>
<sanbao-plan>plan content</sanbao-plan>
<sanbao-task title="Task">- [ ] Step</sanbao-task>
<sanbao-clarify>[{questions JSON}]</sanbao-clarify>
```

### Billing
- Plans с лимитами: messagesPerDay, tokensPerMonth, requestsPerMinute, contextWindowSize
- Feature flags: canUseAdvancedTools, canUseReasoning, canUseRag, canChooseProvider
- Stripe + Freedom Pay checkout
- PromoCode system
- DailyUsage tracking

---

## Мобайл: что реализовано

### Полностью работает (90-95%)

| Фича | Ключевые файлы | Детали |
|------|----------------|--------|
| **NDJSON стриминг** | `ndjson_parser.dart`, `chat_remote_datasource.dart` | Sealed classes, CancelToken, partial chunk buffering |
| **Парсинг sanbao-doc** | `chat_event_model.dart` → `SanbaoTagParser` | Regex extraction, language detection, clarify questions |
| **Message bubble** | `message_bubble.dart` | Reasoning collapse, artifact cards, copy, regenerate |
| **Artifact cards** | `artifact_card.dart` | Animated inline cards с type icons |
| **Artifact viewer** | `artifact_view_screen.dart` | 3 tabs: Preview/Editor/Source |
| **Document editor** | `document_editor.dart` | Markdown toolbar, undo/redo, auto-save |
| **Code preview** | `code_preview.dart` | Line numbers, language badge, copy |
| **Auth** | `auth_provider.dart`, screens | JWT, Google, Apple, 2FA, biometrics |
| **Agents** | `agent_list/detail/form_screen.dart` | CRUD + AI generation |
| **Chat controller** | `chat_provider.dart` (406 строк) | Stream events, phase tracking, artifact extraction |
| **Navigation** | `routes.dart` | 28 маршрутов, auth guard, onboarding guard |
| **Preferences** | `preferences.dart`, `settings_screen.dart` | Theme, locale, biometrics, text scale |
| **Profile** | `profile_screen.dart`, `edit_profile_screen.dart` | Avatar, edit, delete account |
| **Memory** | `memory_list_screen.dart` | CRUD + category filters |
| **Onboarding** | `onboarding_screen.dart` | 4 steps |

### Работает, нужна доработка (75-85%)

| Фича | Что есть | Что доделать |
|------|----------|-------------|
| **Skills** | CRUD + marketplace tabs | Marketplace API может быть неполным |
| **Tools** | CRUD по 4 типам | Test execution |
| **Plugins** | Базовый CRUD | Marketplace |
| **MCP** | CRUD + status badge | Test connection, health polling |
| **Tasks** | List + progress + steps | Cancel, retry |
| **Knowledge** | Files CRUD | Batch operations |
| **Notifications** | Bell + polling | FCM push |
| **Image gen** | Prompt + styles + result | History, save to gallery |
| **Code fix** | Basic flow | Diff view |
| **Legal** | 19 кодексов, inline refs | Search |
| **Export** | Menu + API calls | PDF native (printing pkg) |

### Критичные пробелы (0-70%)

| Фича | Веб | Мобайл | Приоритет |
|------|-----|--------|-----------|
| **`<sanbao-edit>` apply** | Auto search/replace в артефактах | Парсинг нет, применение нет | P0 |
| **Stripe/Freedom Pay** | Checkout + webhook | UI тарифов есть, платежи нет | P0 |
| **FCM Push** | HTTP polling | Только polling | P1 |
| **`<sanbao-task>` parsing** | Чеклисты в стриме | Не парсится | P1 |
| **`<sanbao-plan>` display** | PlanBlock (collapsible) | planContent есть, UI не выделен | P1 |
| **Password reset** | Есть | Нет | P1 |
| **WhatsApp auth** | Есть | Нет | P2 |
| **Code execution** | iframe (React/Python/Pyodide) | Только просмотр | P2 |
| **Syntax highlighting** | Да | Нет (plain monospace) | P2 |
| **Context compaction** | Auto-summarization | Нет (бэкенд делает) | Не нужно |
| **Scratchpad** | Server-side native tool | Не нужно на клиенте | Не нужно |

---

## Инфраструктура мобайл

### Dio HTTP Client
- Timeouts: connect 15s, receive 60s, send 30s
- Interceptors: Auth (JWT + refresh), Retry (3x exponential), CorrelationId, Logging
- Streaming: `postStream()` для NDJSON

### App Config
- 24 API endpoint определения
- File limits: max 10MB, max 20 attachments
- AI defaults: temp 0.6, max_tokens 4096, context 128K
- 13 allowed MIME types

### Тесты
9 файлов: sanbao_tag_parser, image_gen, knowledge, legal, report, promo_code, widget

---

## Версия

| Поле | Значение |
|------|---------|
| Версия | 1.0.0 build 4 |
| Bundle ID | com.sanbao.mobile.sanbaoFlutter |
| Team ID | MCMQHQ6XT9 |
| API | https://www.sanbao.ai |
| Flutter | >=3.24.0, Dart >=3.5.0 |
| TestFlight | Загружен 24 фев 2026 |
| iOS Firebase | GoogleService-Info.plist ✅ |
| Android Firebase | google-services.json ❌ |
