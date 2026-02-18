// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sanbao';

  @override
  String get appDescription => 'AI platform for professionals';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginSignUp => 'Sign Up';

  @override
  String get registerTitle => 'Sign Up';

  @override
  String get registerName => 'Name';

  @override
  String get registerEmail => 'Email';

  @override
  String get registerPassword => 'Password';

  @override
  String get registerConfirmPassword => 'Confirm Password';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get registerHasAccount => 'Already have an account?';

  @override
  String get registerSignIn => 'Sign In';

  @override
  String get chatTitle => 'Conversations';

  @override
  String get chatNewChat => 'New Chat';

  @override
  String get chatInputPlaceholder => 'Type a message...';

  @override
  String get chatSend => 'Send';

  @override
  String get chatThinking => 'Thinking...';

  @override
  String get chatSearching => 'Searching the web...';

  @override
  String get chatUsingTool => 'Using a tool...';

  @override
  String get chatEmpty => 'Start a new conversation';

  @override
  String get chatEmptyDescription =>
      'Ask a question or choose an agent to get started';

  @override
  String get chatDeleteConfirm => 'Delete conversation?';

  @override
  String get chatDeleteMessage => 'This action cannot be undone';

  @override
  String get chatPinned => 'Pinned';

  @override
  String get chatArchived => 'Archived';

  @override
  String get groupToday => 'Today';

  @override
  String get groupYesterday => 'Yesterday';

  @override
  String get groupThisWeek => 'This Week';

  @override
  String get groupEarlier => 'Earlier';

  @override
  String get agentsTitle => 'Agents';

  @override
  String get agentsEmpty => 'No agents available';

  @override
  String get agentsCreate => 'Create Agent';

  @override
  String get skillsTitle => 'Skills';

  @override
  String get skillsEmpty => 'No skills available';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLogout => 'Log Out';

  @override
  String get profileLogoutConfirm => 'Log out of your account?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsHapticFeedback => 'Haptic Feedback';

  @override
  String get settingsBiometric => 'Biometric Authentication';

  @override
  String get settingsTextScale => 'Text Size';

  @override
  String get settingsThinkingMode => 'Reasoning Mode';

  @override
  String get settingsWebSearch => 'Web Search';

  @override
  String get settingsPlanningMode => 'Planning Mode';

  @override
  String get billingTitle => 'Plan';

  @override
  String get billingCurrentPlan => 'Current Plan';

  @override
  String get billingUpgrade => 'Upgrade Plan';

  @override
  String get billingUsage => 'Usage';

  @override
  String get billingMessages => 'Messages today';

  @override
  String get billingTokens => 'Tokens this month';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonShare => 'Share';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Error';

  @override
  String get commonSuccess => 'Success';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonMore => 'More';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonDone => 'Done';

  @override
  String get commonAll => 'All';

  @override
  String get commonNone => 'None';

  @override
  String get errorNetwork => 'No internet connection';

  @override
  String get errorServer => 'Server error. Try again later';

  @override
  String get errorTimeout => 'Request timed out';

  @override
  String get errorAuth => 'Session expired. Please sign in again';

  @override
  String get errorPermission => 'Access denied';

  @override
  String get errorNotFound => 'Resource not found';

  @override
  String get errorRateLimit => 'Too many requests. Please wait';

  @override
  String get errorUnknown => 'An unknown error occurred';

  @override
  String get errorValidation => 'Please check your input';

  @override
  String get fileAttach => 'Attach File';

  @override
  String get fileImage => 'Photo';

  @override
  String get fileDocument => 'Document';

  @override
  String get fileCamera => 'Camera';

  @override
  String fileSizeLimit(String size) {
    return 'Maximum file size: $size';
  }

  @override
  String get voiceRecord => 'Voice Recording';

  @override
  String get voiceListening => 'Listening...';

  @override
  String get voiceStop => 'Stop';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get shareVia => 'Share via';

  @override
  String get artifactContract => 'Contract';

  @override
  String get artifactClaim => 'Claim';

  @override
  String get artifactComplaint => 'Complaint';

  @override
  String get artifactDocument => 'Document';

  @override
  String get artifactCode => 'Code';

  @override
  String get artifactAnalysis => 'Legal Analysis';

  @override
  String get artifactImage => 'Image';

  @override
  String nMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String nDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }
}
