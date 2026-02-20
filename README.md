# Sanbao Flutter — Mobile AI Platform Client

Мобильный клиент (iOS/Android) для AI-платформы **Sanbao**. Является мобильной версией [веб-приложения Sanbao](../sanbao/) — реализует весь пользовательский функционал без административных функций.

## Что это

Flutter-приложение, которое подключается к тому же бэкенду (`sanbao/`), использует тот же API, стриминг-протокол (NDJSON) и дизайн-систему, что и веб-версия. Мобильная версия предназначена **только для конечных пользователей** — панель администратора, управление пользователями, настройки системы и прочие admin-функции **не реализуются**.

## Архитектура

Clean Architecture с разделением на слои:

```
lib/
├── core/           # Конфигурация, сеть, хранилище, тема, UI-kit, утилиты
├── features/       # Фичи: auth, chat, artifacts, agents, skills
│   └── <feature>/
│       ├── domain/         # Entities, repositories (абстракции), use cases
│       ├── data/           # Models (Freezed), datasources (Dio), repo implementations
│       └── presentation/   # Screens, widgets, Riverpod providers
└── main.dart       # Точка входа
```

## Стек

| Категория | Технологии |
|-----------|-----------|
| Фреймворк | Flutter 3.24+, Dart 3.5+ |
| Стейт | Riverpod 2.6.1 + riverpod_generator |
| Навигация | GoRouter 14.6.2 |
| Сеть | Dio 5.7 + NDJSON стриминг |
| Кодогенерация | Freezed + json_serializable + build_runner |
| Хранилище | flutter_secure_storage, SharedPreferences, file-based cache |
| Локализация | intl 0.20.2 (ru, en) |
| Ошибки | Sentry Flutter 9.0 |
| OAuth | Google Sign-In 6.2 |

## Быстрый старт

```bash
# Установка зависимостей
flutter pub get

# Кодогенерация (Freezed, Riverpod, JSON)
flutter pub run build_runner build --delete-conflicting-outputs

# Запуск
flutter run -d <device>

# Запуск с кастомным API URL
flutter run --dart-define=API_BASE_URL=https://api.sanbao.ai
```

## Сборка

```bash
flutter build apk          # Android APK
flutter build appbundle     # Android App Bundle
flutter build ios           # iOS
```

## Тестирование

```bash
flutter test                # Юнит-тесты
flutter analyze             # Статический анализ
```

## Дизайн-система

«Soft Corporate Minimalism» — идентична веб-версии. Полный гайд: [`../sanbao/docs/STYLEGUIDE.md`](../sanbao/docs/STYLEGUIDE.md).

- Фон: #FAFBFD (light) / #0F1219 (dark) — никогда чистый белый/черный
- Акцент: #4F6EF7 (light) / #6B8AFF (dark)
- Шрифты: Inter (основной), JetBrains Mono (код)
- Радиусы: 12px кнопки, 16px карточки, 32px чат-инпут
- Анимации: spring (damping 25, stiffness 300)
- Glassmorphism: backdrop-filter blur 16px

## Связь с веб-проектом

- **API-бэкенд** (`sanbao/`) — единый для веб и мобайл
- **Стриминг:** `POST /api/chat` → NDJSON `{t, v}` (типы: c, r, p, s, x, e)
- **Авторизация:** JWT + Credentials + Google OAuth + 2FA TOTP
- **Веб-проект** — источник правды для функционала и дизайна; мобайл повторяет его UX
