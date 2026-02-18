// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Sanbao';

  @override
  String get appDescription => 'AI-платформа для профессионалов';

  @override
  String get loginTitle => 'Вход';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Пароль';

  @override
  String get loginButton => 'Войти';

  @override
  String get loginWithGoogle => 'Войти через Google';

  @override
  String get loginForgotPassword => 'Забыли пароль?';

  @override
  String get loginNoAccount => 'Нет аккаунта?';

  @override
  String get loginSignUp => 'Зарегистрироваться';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get registerName => 'Имя';

  @override
  String get registerEmail => 'Email';

  @override
  String get registerPassword => 'Пароль';

  @override
  String get registerConfirmPassword => 'Подтвердите пароль';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get registerHasAccount => 'Уже есть аккаунт?';

  @override
  String get registerSignIn => 'Войти';

  @override
  String get chatTitle => 'Диалоги';

  @override
  String get chatNewChat => 'Новый диалог';

  @override
  String get chatInputPlaceholder => 'Введите сообщение...';

  @override
  String get chatSend => 'Отправить';

  @override
  String get chatThinking => 'Думает...';

  @override
  String get chatSearching => 'Ищет в интернете...';

  @override
  String get chatUsingTool => 'Использует инструмент...';

  @override
  String get chatEmpty => 'Начните новый диалог';

  @override
  String get chatEmptyDescription =>
      'Задайте вопрос или выберите агента для начала работы';

  @override
  String get chatDeleteConfirm => 'Удалить диалог?';

  @override
  String get chatDeleteMessage => 'Это действие нельзя отменить';

  @override
  String get chatPinned => 'Закреплённые';

  @override
  String get chatArchived => 'Архив';

  @override
  String get groupToday => 'Сегодня';

  @override
  String get groupYesterday => 'Вчера';

  @override
  String get groupThisWeek => 'Эта неделя';

  @override
  String get groupEarlier => 'Ранее';

  @override
  String get agentsTitle => 'Агенты';

  @override
  String get agentsEmpty => 'Нет доступных агентов';

  @override
  String get agentsCreate => 'Создать агента';

  @override
  String get skillsTitle => 'Скиллы';

  @override
  String get skillsEmpty => 'Нет доступных скиллов';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileLogout => 'Выйти';

  @override
  String get profileLogoutConfirm => 'Выйти из аккаунта?';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsHapticFeedback => 'Вибрация';

  @override
  String get settingsBiometric => 'Биометрическая аутентификация';

  @override
  String get settingsTextScale => 'Размер текста';

  @override
  String get settingsThinkingMode => 'Режим рассуждений';

  @override
  String get settingsWebSearch => 'Веб-поиск';

  @override
  String get settingsPlanningMode => 'Режим планирования';

  @override
  String get billingTitle => 'Тариф';

  @override
  String get billingCurrentPlan => 'Текущий тариф';

  @override
  String get billingUpgrade => 'Улучшить тариф';

  @override
  String get billingUsage => 'Использование';

  @override
  String get billingMessages => 'Сообщений сегодня';

  @override
  String get billingTokens => 'Токенов в месяц';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonConfirm => 'Подтвердить';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonEdit => 'Редактировать';

  @override
  String get commonCopy => 'Копировать';

  @override
  String get commonShare => 'Поделиться';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonLoading => 'Загрузка...';

  @override
  String get commonError => 'Ошибка';

  @override
  String get commonSuccess => 'Успешно';

  @override
  String get commonSearch => 'Поиск';

  @override
  String get commonMore => 'Ещё';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonNext => 'Далее';

  @override
  String get commonDone => 'Готово';

  @override
  String get commonAll => 'Все';

  @override
  String get commonNone => 'Нет';

  @override
  String get errorNetwork => 'Нет подключения к интернету';

  @override
  String get errorServer => 'Ошибка сервера. Попробуйте позже';

  @override
  String get errorTimeout => 'Превышено время ожидания';

  @override
  String get errorAuth => 'Сессия истекла. Войдите снова';

  @override
  String get errorPermission => 'Доступ запрещён';

  @override
  String get errorNotFound => 'Ресурс не найден';

  @override
  String get errorRateLimit => 'Слишком много запросов. Подождите';

  @override
  String get errorUnknown => 'Произошла неизвестная ошибка';

  @override
  String get errorValidation => 'Проверьте введённые данные';

  @override
  String get fileAttach => 'Прикрепить файл';

  @override
  String get fileImage => 'Фото';

  @override
  String get fileDocument => 'Документ';

  @override
  String get fileCamera => 'Камера';

  @override
  String fileSizeLimit(String size) {
    return 'Максимальный размер файла: $size';
  }

  @override
  String get voiceRecord => 'Запись голоса';

  @override
  String get voiceListening => 'Слушаю...';

  @override
  String get voiceStop => 'Остановить';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get shareVia => 'Поделиться через';

  @override
  String get artifactContract => 'Договор';

  @override
  String get artifactClaim => 'Исковое заявление';

  @override
  String get artifactComplaint => 'Жалоба';

  @override
  String get artifactDocument => 'Документ';

  @override
  String get artifactCode => 'Код';

  @override
  String get artifactAnalysis => 'Правовой анализ';

  @override
  String get artifactImage => 'Изображение';

  @override
  String nMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщений',
      few: '$count сообщения',
      one: '1 сообщение',
    );
    return '$_temp0';
  }

  @override
  String nDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней назад',
      few: '$count дня назад',
      one: '1 день назад',
    );
    return '$_temp0';
  }
}
