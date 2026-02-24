# React → Flutter: Маппинг Sanbao Web → Mobile

## Общая картина

| Веб (React/Next.js) | Мобайл (Flutter) | Аналог |
|---------------------|------------------|--------|
| Zustand stores | Riverpod providers | 1:1 по фичам |
| React components | StatelessWidget / ConsumerWidget | 1:1 |
| fetch + ReadableStream | Dio postStream + StreamController | Реализовано |
| `react-markdown` | `flutter_markdown` | Реализовано |
| Tiptap v3 editor | Custom markdown toolbar | Реализовано |
| iframe code exec | Только просмотр (без exec) | Мобильная специфика |
| NextAuth (cookie) | JWT Bearer (secure_storage) | Реализовано |
| GoRouter (Next.js) | GoRouter (Flutter) | Реализовано |
| Tailwind CSS | SanbaoTheme (colors, typography) | Реализовано |
| html2canvas + jsPDF | `printing` package | Нужна интеграция |
| Stripe Checkout redirect | Нужна мобильная SDK | Не реализовано |

---

## 1. ЧАТСИСТЕМА

### Стриминг

| Веб | Flutter | Файл Flutter |
|-----|---------|-------------|
| `MessageInput.tsx` fetch → NDJSON | Dio `postStream` → `ndjson_parser.dart` | `chat_remote_datasource.dart` |
| chatStore phases | `StreamingPhase` enum | `chat_provider.dart` |
| Content events → append | `ContentEvent` → `updateLastAssistantMessage` | `chat_provider.dart:250` |
| Reasoning events | `ReasoningEvent` → appendReasoning | `chat_provider.dart:258` |
| Plan events | `PlanEvent` → appendPlan | `chat_provider.dart:264` |
| Status events (searching, using_tool) | `StatusEvent` → phase update | `chat_provider.dart:270` |
| Context events | `ContextEvent` → contextUsageProvider | `chat_provider.dart:280` |
| Error events | `ErrorEvent` → setError + finish | `chat_provider.dart:283` |

**Статус: 95% ✅** — Полная реализация стриминга.

### Парсинг тегов

| Веб (MessageBubble.tsx) | Flutter | Статус |
|------------------------|---------|--------|
| `ARTIFACT_REGEX` → parseContentWithArtifacts() | `SanbaoTagParser.extractArtifacts()` | ✅ |
| `CLARIFY_REGEX` → extractClarifyQuestions() | `SanbaoTagParser.extractClarifyQuestions()` | ✅ |
| `EDIT_REGEX` + `REPLACE_REGEX` → applyEdits() | **Не реализовано** | ❌ P0 |
| `<sanbao-plan>` → PlanBlock | planContent есть, UI блок не выделен | ⚠️ P1 |
| `<sanbao-task>` → TaskItem | **Не реализовано** | ❌ P1 |

### Message Bubble

| Веб | Flutter | Статус |
|-----|---------|--------|
| User bubble (right, blue) | `_UserBubble` в `message_bubble.dart` | ✅ |
| Assistant bubble (left, border) | `_AssistantBubble` | ✅ |
| Reasoning section (collapsible) | `_buildReasoningSection()` с AnimatedCrossFade | ✅ |
| Artifact inline cards | `ArtifactCard` виджет с анимацией | ✅ |
| Edit cards (auto-apply) | **Не реализовано** | ❌ |
| Legal reference badges | Реализовано | ✅ |
| Streaming cursor | Реализовано | ✅ |
| Copy / Regenerate actions | Реализовано | ✅ |
| File attachment preview | Реализовано | ✅ |

---

## 2. СИСТЕМА АРТЕФАКТОВ

### Модель данных

| Веб (Prisma) | Flutter (Entity) | Статус |
|--------------|------------------|--------|
| `Artifact { id, conversationId, messageId, type, title, content, version, metadata }` | `Artifact { id, type, title, content, language }` | ✅ (упрощена) |
| `ArtifactType` enum (7 типов) | `ArtifactType` enum (7 типов) | ✅ |
| `ArtifactVersion { version, content, timestamp }` | `ArtifactVersionModel` | ✅ |

### Store → Provider

| Веб (artifactStore.ts) | Flutter | Файл |
|------------------------|---------|------|
| `activeArtifact` | `currentArtifactProvider` | `artifact_provider.dart` |
| `activeTab` | `artifactViewTabProvider` | `artifact_provider.dart` |
| `artifacts[]` | В `messagesProvider` (per-message) | `chat_provider.dart` |
| `openArtifact()` | `CurrentArtifactNotifier.open()` | ✅ |
| `trackArtifact()` (title dedup) | `finishStreaming()` → extractArtifacts | ✅ (без dedup) |
| `findByTitle()` | **Не реализовано** | ❌ P1 |
| `applyEdits()` (search/replace) | **Не реализовано** | ❌ P0 |
| `restoreVersion()` | `restoreVersion()` через API | ✅ |
| `downloadFormat` | `ExportFormat` enum | ✅ |

### UI Components

| Веб | Flutter | Статус |
|-----|---------|--------|
| `UnifiedPanel.tsx` (side panel) | `ArtifactViewScreen` (fullscreen) | ✅ мобильная адаптация |
| `ArtifactContent.tsx` (router) | Встроен в `ArtifactViewScreen` | ✅ |
| `ArtifactTabs.tsx` | Tab bar в view screen | ✅ |
| `PanelTabBar.tsx` (multi-tab) | Одиночный артефакт (no tabs) | Мобильная специфика |
| `DocumentPreview.tsx` (A4 layout) | `document_preview.dart` | ✅ |
| `DocumentEditor.tsx` (Tiptap) | `document_editor.dart` (markdown toolbar) | ✅ |
| `CodePreview.tsx` (iframe exec) | `code_preview.dart` (view only) | ⚠️ |
| `EditorToolbar.tsx` | Встроен в editor | ✅ |
| Export (DOCX/PDF/TXT/XLSX/HTML/MD) | `export_menu.dart` + API | ✅ |
| Version selector dropdown | `version_selector.dart` | ✅ |

### Мобильные отличия
- **Нет side panel** → полноэкранный viewer (bottom sheet на mobile, route на tablet)
- **Нет multi-tab** → один артефакт за раз
- **Нет code execution** → только просмотр кода
- **Export PDF** → через `printing` package (native) вместо html2canvas

### Что доделать (приоритет)

#### P0 — `<sanbao-edit>` auto-apply
```dart
// Нужно добавить в SanbaoTagParser:
static final RegExp editPattern = RegExp(
  r'<sanbao-edit\s+target="([^"]*)">([\s\S]*?)</sanbao-edit>',
);
static final RegExp replacePattern = RegExp(
  r'<replace>\s*<old>([\s\S]*?)</old>\s*<new>([\s\S]*?)</new>\s*</replace>',
);

// В chat_provider.dart → finishStreaming():
// 1. Извлечь edit-теги
// 2. Найти артефакт по title в текущих сообщениях
// 3. Применить search/replace к content
// 4. Увеличить version
```

#### P1 — Title-based дедупликация
Веб делает: если артефакт с тем же title → обновить content + version++.
Нужно в `finishStreaming()` или отдельном store.

#### P1 — `<sanbao-task>` парсинг
```dart
static final RegExp taskPattern = RegExp(
  r'<sanbao-task\s+title="([^"]*)">([\s\S]*?)</sanbao-task>',
);
```

#### P2 — Syntax highlighting
Пакет `flutter_highlight` или `highlight` для CODE артефактов.

---

## 3. АВТОРИЗАЦИЯ

| Веб | Flutter | Статус |
|-----|---------|--------|
| NextAuth v5 (cookie-based) | JWT Bearer (flutter_secure_storage) | ✅ |
| Google OAuth (web redirect) | google_sign_in (native mobile) | ✅ |
| Apple Sign In | sign_in_with_apple | ✅ |
| 2FA TOTP (otplib) | QR setup + verify screen | ✅ |
| Credentials (bcrypt) | Email/password login | ✅ |
| WhatsApp auth | **Нет** | ❌ P2 |
| Password reset | **Нет** | ❌ P1 |
| Session refresh | Auto-refresh через interceptor | ✅ |

---

## 4. АГЕНТЫ

| Веб | Flutter | Статус |
|-----|---------|--------|
| AgentCard + AgentForm | `agent_list/detail/form_screen.dart` | ✅ 90% |
| IconPicker, AvatarUpload | В form screen | ✅ |
| SkillPicker, ToolPicker, McpPicker | В form screen | ✅ |
| AgentFileUpload (context files) | В form screen | ✅ |
| AI generation (`/agents/generate`) | Generation sheet | ✅ |
| System agents display | System agent cards | ✅ |

---

## 5. НАВЫКИ

| Веб | Flutter | Статус |
|-----|---------|--------|
| SkillForm + SkillCard | `skill_list/detail/form_screen.dart` | ✅ 85% |
| Marketplace (browse public) | Tab "Маркетплейс" | ✅ UI |
| Clone skill (`/skills/[id]/clone`) | Clone button | ✅ |
| AI generation | Generation sheet | ✅ |

---

## 6. БИЛЛИНГ

| Веб | Flutter | Статус |
|-----|---------|--------|
| Plan list с features | `plans_screen.dart` + `plan_card.dart` | ✅ |
| Usage bars (messages, tokens) | `usage_indicator.dart` | ✅ |
| Subscription badge | `subscription_badge.dart` | ✅ |
| Stripe Checkout | **Нет** | ❌ P0 |
| Freedom Pay | **Нет** | ❌ P0 |
| Promo code | Provider реализован | ✅ |
| Payment history | **UI минимален** | ⚠️ |

### Как интегрировать платежи (мобайл)
1. **Stripe**: `flutter_stripe` package → `presentPaymentSheet()`
2. **Freedom Pay**: WebView с redirect URL
3. **Apple Pay / Google Pay**: Через flutter_stripe

---

## 7. MCP СЕРВЕРЫ

| Веб | Flutter | Статус |
|-----|---------|--------|
| McpServer CRUD | `mcp_list/form_screen.dart` | ✅ |
| Connect/Disconnect | **Нет кнопки** | ❌ P1 |
| Status badge (connected/error) | `mcp_status_badge.dart` | ✅ |
| Tool discovery | **Нет** | ❌ P2 |
| Health polling | **Нет** | ❌ P2 |

---

## 8. УВЕДОМЛЕНИЯ

| Веб | Flutter | Статус |
|-----|---------|--------|
| HTTP polling | `notification_polling_service.dart` | ✅ |
| Bell + unread count | `notification_bell.dart` | ✅ |
| Mark as read | API call | ✅ |
| FCM Push | **Нет** | ❌ P1 |

### Как добавить FCM
1. `firebase_messaging` package
2. Request permission → get FCM token
3. `POST /api/notifications/push` — зарегистрировать токен (бэкенд тоже нужен)
4. Handle foreground/background messages

---

## 9. ГЕНЕРАЦИЯ ИЗОБРАЖЕНИЙ

| Веб | Flutter | Статус |
|-----|---------|--------|
| ImageGenerateModal | `image_gen_screen.dart` | ✅ |
| Style/size selectors | `image_gen_option_selector.dart` | ✅ |
| Result display | `image_gen_result_view.dart` | ✅ |
| Image edit (mask) | **Нет** | ❌ P2 |
| Save as IMAGE artifact | **Нет** | ❌ P1 |

---

## 10. КОНТЕКСТ И ПЛАНИРОВАНИЕ

| Веб | Flutter | Статус |
|-----|---------|--------|
| Context compaction (auto-summarize) | Бэкенд делает | Не нужно на клиенте |
| ConversationPlan display | `planContent` в message | ✅ данные есть |
| PlanBlock UI (collapsible) | **Не выделен отдельно** | ⚠️ P1 |
| Context indicator (%) | `ContextEvent` в provider | ✅ данные, нет UI |
| Scratchpad (server-side) | Не нужно на клиенте | N/A |

---

## ПРИОРИТЕТЫ РЕАЛИЗАЦИИ

### Sprint 1 — Артефакты + критичное
- [ ] `<sanbao-edit>` парсинг + auto-apply в chat provider
- [ ] Title-based дедупликация артефактов
- [ ] Plan block UI (выделенный блок для `planContent`)
- [ ] Context usage indicator в чате

### Sprint 2 — Платежи + push
- [ ] Stripe integration (`flutter_stripe`)
- [ ] FCM push notifications
- [ ] `google-services.json` для Android

### Sprint 3 — Улучшения
- [ ] `<sanbao-task>` парсинг → inline чеклисты
- [ ] Syntax highlighting для CODE
- [ ] IMAGE artifact rendering (base64)
- [ ] MCP connect/disconnect buttons
- [ ] Password reset flow

### Sprint 4 — Polish
- [ ] Image edit (mask)
- [ ] Image generation history
- [ ] Plugin marketplace
- [ ] Tool test execution
- [ ] Task cancel/retry
- [ ] WhatsApp auth
- [ ] Больше тестов
