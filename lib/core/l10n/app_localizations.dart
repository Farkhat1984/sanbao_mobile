import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'Sanbao'**
  String get appName;

  /// No description provided for @appDescription.
  ///
  /// In ru, this message translates to:
  /// **'AI-платформа для профессионалов'**
  String get appDescription;

  /// No description provided for @loginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get loginTitle;

  /// No description provided for @loginEmail.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get loginPassword;

  /// No description provided for @loginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginButton;

  /// No description provided for @loginWithGoogle.
  ///
  /// In ru, this message translates to:
  /// **'Войти через Google'**
  String get loginWithGoogle;

  /// No description provided for @loginForgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get loginForgotPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In ru, this message translates to:
  /// **'Нет аккаунта?'**
  String get loginNoAccount;

  /// No description provided for @loginSignUp.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get loginSignUp;

  /// No description provided for @registerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get registerTitle;

  /// No description provided for @registerName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get registerName;

  /// No description provided for @registerEmail.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get registerEmail;

  /// No description provided for @registerPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get registerPassword;

  /// No description provided for @registerConfirmPassword.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите пароль'**
  String get registerConfirmPassword;

  /// No description provided for @registerButton.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get registerButton;

  /// No description provided for @registerHasAccount.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт?'**
  String get registerHasAccount;

  /// No description provided for @registerSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get registerSignIn;

  /// No description provided for @chatTitle.
  ///
  /// In ru, this message translates to:
  /// **'Диалоги'**
  String get chatTitle;

  /// No description provided for @chatNewChat.
  ///
  /// In ru, this message translates to:
  /// **'Новый диалог'**
  String get chatNewChat;

  /// No description provided for @chatInputPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Введите сообщение...'**
  String get chatInputPlaceholder;

  /// No description provided for @chatSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get chatSend;

  /// No description provided for @chatThinking.
  ///
  /// In ru, this message translates to:
  /// **'Думает...'**
  String get chatThinking;

  /// No description provided for @chatSearching.
  ///
  /// In ru, this message translates to:
  /// **'Ищет в интернете...'**
  String get chatSearching;

  /// No description provided for @chatUsingTool.
  ///
  /// In ru, this message translates to:
  /// **'Использует инструмент...'**
  String get chatUsingTool;

  /// No description provided for @chatEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Начните новый диалог'**
  String get chatEmpty;

  /// No description provided for @chatEmptyDescription.
  ///
  /// In ru, this message translates to:
  /// **'Задайте вопрос или выберите агента для начала работы'**
  String get chatEmptyDescription;

  /// No description provided for @chatDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить диалог?'**
  String get chatDeleteConfirm;

  /// No description provided for @chatDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'Это действие нельзя отменить'**
  String get chatDeleteMessage;

  /// No description provided for @chatPinned.
  ///
  /// In ru, this message translates to:
  /// **'Закреплённые'**
  String get chatPinned;

  /// No description provided for @chatArchived.
  ///
  /// In ru, this message translates to:
  /// **'Архив'**
  String get chatArchived;

  /// No description provided for @groupToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get groupToday;

  /// No description provided for @groupYesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get groupYesterday;

  /// No description provided for @groupThisWeek.
  ///
  /// In ru, this message translates to:
  /// **'Эта неделя'**
  String get groupThisWeek;

  /// No description provided for @groupEarlier.
  ///
  /// In ru, this message translates to:
  /// **'Ранее'**
  String get groupEarlier;

  /// No description provided for @agentsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Агенты'**
  String get agentsTitle;

  /// No description provided for @agentsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных агентов'**
  String get agentsEmpty;

  /// No description provided for @agentsCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создать агента'**
  String get agentsCreate;

  /// No description provided for @skillsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Скиллы'**
  String get skillsTitle;

  /// No description provided for @skillsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных скиллов'**
  String get skillsEmpty;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @profileLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта?'**
  String get profileLogoutConfirm;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Системная'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingsLanguage;

  /// No description provided for @settingsNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get settingsNotifications;

  /// No description provided for @settingsHapticFeedback.
  ///
  /// In ru, this message translates to:
  /// **'Вибрация'**
  String get settingsHapticFeedback;

  /// No description provided for @settingsBiometric.
  ///
  /// In ru, this message translates to:
  /// **'Биометрическая аутентификация'**
  String get settingsBiometric;

  /// No description provided for @settingsTextScale.
  ///
  /// In ru, this message translates to:
  /// **'Размер текста'**
  String get settingsTextScale;

  /// No description provided for @settingsThinkingMode.
  ///
  /// In ru, this message translates to:
  /// **'Режим рассуждений'**
  String get settingsThinkingMode;

  /// No description provided for @settingsWebSearch.
  ///
  /// In ru, this message translates to:
  /// **'Веб-поиск'**
  String get settingsWebSearch;

  /// No description provided for @settingsPlanningMode.
  ///
  /// In ru, this message translates to:
  /// **'Режим планирования'**
  String get settingsPlanningMode;

  /// No description provided for @billingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тариф'**
  String get billingTitle;

  /// No description provided for @billingCurrentPlan.
  ///
  /// In ru, this message translates to:
  /// **'Текущий тариф'**
  String get billingCurrentPlan;

  /// No description provided for @billingUpgrade.
  ///
  /// In ru, this message translates to:
  /// **'Улучшить тариф'**
  String get billingUpgrade;

  /// No description provided for @billingUsage.
  ///
  /// In ru, this message translates to:
  /// **'Использование'**
  String get billingUsage;

  /// No description provided for @billingMessages.
  ///
  /// In ru, this message translates to:
  /// **'Сообщений сегодня'**
  String get billingMessages;

  /// No description provided for @billingTokens.
  ///
  /// In ru, this message translates to:
  /// **'Токенов в месяц'**
  String get billingTokens;

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get commonEdit;

  /// No description provided for @commonCopy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get commonCopy;

  /// No description provided for @commonShare.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get commonShare;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Успешно'**
  String get commonSuccess;

  /// No description provided for @commonSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get commonSearch;

  /// No description provided for @commonMore.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get commonMore;

  /// No description provided for @commonClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get commonNext;

  /// No description provided for @commonDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get commonDone;

  /// No description provided for @commonAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get commonAll;

  /// No description provided for @commonNone.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get commonNone;

  /// No description provided for @errorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Нет подключения к интернету'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера. Попробуйте позже'**
  String get errorServer;

  /// No description provided for @errorTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Превышено время ожидания'**
  String get errorTimeout;

  /// No description provided for @errorAuth.
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла. Войдите снова'**
  String get errorAuth;

  /// No description provided for @errorPermission.
  ///
  /// In ru, this message translates to:
  /// **'Доступ запрещён'**
  String get errorPermission;

  /// No description provided for @errorNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Ресурс не найден'**
  String get errorNotFound;

  /// No description provided for @errorRateLimit.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много запросов. Подождите'**
  String get errorRateLimit;

  /// No description provided for @errorUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Произошла неизвестная ошибка'**
  String get errorUnknown;

  /// No description provided for @errorValidation.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте введённые данные'**
  String get errorValidation;

  /// No description provided for @fileAttach.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить файл'**
  String get fileAttach;

  /// No description provided for @fileImage.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get fileImage;

  /// No description provided for @fileDocument.
  ///
  /// In ru, this message translates to:
  /// **'Документ'**
  String get fileDocument;

  /// No description provided for @fileCamera.
  ///
  /// In ru, this message translates to:
  /// **'Камера'**
  String get fileCamera;

  /// No description provided for @fileSizeLimit.
  ///
  /// In ru, this message translates to:
  /// **'Максимальный размер файла: {size}'**
  String fileSizeLimit(String size);

  /// No description provided for @voiceRecord.
  ///
  /// In ru, this message translates to:
  /// **'Запись голоса'**
  String get voiceRecord;

  /// No description provided for @voiceListening.
  ///
  /// In ru, this message translates to:
  /// **'Слушаю...'**
  String get voiceListening;

  /// No description provided for @voiceStop.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get voiceStop;

  /// No description provided for @copiedToClipboard.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано в буфер обмена'**
  String get copiedToClipboard;

  /// No description provided for @shareVia.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться через'**
  String get shareVia;

  /// No description provided for @artifactContract.
  ///
  /// In ru, this message translates to:
  /// **'Договор'**
  String get artifactContract;

  /// No description provided for @artifactClaim.
  ///
  /// In ru, this message translates to:
  /// **'Исковое заявление'**
  String get artifactClaim;

  /// No description provided for @artifactComplaint.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба'**
  String get artifactComplaint;

  /// No description provided for @artifactDocument.
  ///
  /// In ru, this message translates to:
  /// **'Документ'**
  String get artifactDocument;

  /// No description provided for @artifactCode.
  ///
  /// In ru, this message translates to:
  /// **'Код'**
  String get artifactCode;

  /// No description provided for @artifactAnalysis.
  ///
  /// In ru, this message translates to:
  /// **'Правовой анализ'**
  String get artifactAnalysis;

  /// No description provided for @artifactImage.
  ///
  /// In ru, this message translates to:
  /// **'Изображение'**
  String get artifactImage;

  /// No description provided for @nMessages.
  ///
  /// In ru, this message translates to:
  /// **'{count,plural, =1{1 сообщение} few{{count} сообщения} other{{count} сообщений}}'**
  String nMessages(int count);

  /// No description provided for @nDaysAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count,plural, =1{1 день назад} few{{count} дня назад} other{{count} дней назад}}'**
  String nDaysAgo(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
