/// Main layout scaffold with responsive drawer/side panel.
///
/// On mobile (< 600px): Hamburger menu opens a glassmorphism drawer.
/// On tablet (>= 600px): Persistent side panel with the conversation list.
/// The drawer is 280px wide with glassmorphism background, matching the
/// web sidebar layout.
///
/// Includes an [OfflineIndicator] banner that animates into view when
/// the device loses internet connectivity.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/config/routes.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/offline_indicator.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/app_drawer.dart';

/// Width of the sidebar / drawer panel.
const double _kDrawerWidth = 280.0;

/// Breakpoint at which the sidebar becomes persistent (tablet+).
const double _kTabletBreakpoint = 600.0;

/// Main layout scaffold providing navigation structure for the app.
///
/// Responsibilities:
/// - Renders the AppDrawer as a Drawer (mobile) or persistent side panel (tablet+)
/// - Provides the hamburger menu button for mobile
/// - Routes conversation selection and new chat events
/// - Wraps the [child] route from GoRouter's ShellRoute
/// - Displays an [OfflineIndicator] when connectivity is lost
class MainLayout extends StatefulWidget {
  const MainLayout({
    required this.child,
    super.key,
  });

  /// The current route's widget, provided by GoRouter's ShellRoute.
  final Widget child;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Handles conversation selection from the drawer.
  void _onConversationSelected(String conversationId) {
    // Close the drawer on mobile after selection
    if (_isMobile) {
      _scaffoldKey.currentState?.closeDrawer();
    }

    // Navigate to the conversation
    context.go('${RoutePaths.chat}/$conversationId');
  }

  /// Handles new chat creation from the drawer.
  void _onNewChat() {
    // Close the drawer on mobile
    if (_isMobile) {
      _scaffoldKey.currentState?.closeDrawer();
    }

    // Navigate to the base chat route (new conversation)
    context.go(RoutePaths.chat);
  }

  /// Handles settings navigation.
  void _onSettingsTap() {
    if (_isMobile) {
      _scaffoldKey.currentState?.closeDrawer();
    }
    context.push(RoutePaths.settings);
  }

  /// Handles profile navigation.
  void _onProfileTap() {
    if (_isMobile) {
      _scaffoldKey.currentState?.closeDrawer();
    }
    context.push(RoutePaths.profile);
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < _kTabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile;

    // Build the drawer content (shared between mobile drawer and tablet panel)
    final drawerContent = AppDrawer(
      onConversationSelected: _onConversationSelected,
      onNewChat: _onNewChat,
      onSettingsTap: _onSettingsTap,
      onProfileTap: _onProfileTap,
      onClose: isMobile
          ? () => _scaffoldKey.currentState?.closeDrawer()
          : null,
    );

    if (isMobile) {
      return _MobileLayout(
        scaffoldKey: _scaffoldKey,
        drawerContent: drawerContent,
        child: widget.child,
      );
    }

    return _TabletLayout(
      drawerContent: drawerContent,
      child: widget.child,
    );
  }
}

/// Mobile layout with a swipeable Drawer.
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.scaffoldKey,
    required this.drawerContent,
    required this.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget drawerContent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        key: scaffoldKey,
        drawer: Drawer(
          width: _kDrawerWidth,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: drawerContent,
        ),
        drawerScrimColor: SanbaoColors.mobileOverlay,
        drawerEdgeDragWidth: 40,
        body: Column(
          children: [
            // Offline indicator slides in from top when connectivity is lost
            const OfflineIndicator(),

            // Main content
            Expanded(child: child),
          ],
        ),
      );
}

/// Tablet/desktop layout with a persistent side panel.
class _TabletLayout extends StatelessWidget {
  const _TabletLayout({
    required this.drawerContent,
    required this.child,
  });

  final Widget drawerContent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Column(
      children: [
        // Offline indicator spans the full width above both sidebar and content
        const OfflineIndicator(),

        // Main row with sidebar and content
        Expanded(
          child: Row(
            children: [
              // Persistent sidebar
              SizedBox(
                width: _kDrawerWidth,
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: colors.border,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: drawerContent,
                  ),
                ),
              ),

              // Main content area
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

/// Extension to provide a method for opening the drawer from child routes.
///
/// Used by the ChatScreen's app bar hamburger menu button on mobile.
extension MainLayoutScaffold on BuildContext {
  /// Opens the main layout's drawer. Returns false if no drawer is available
  /// (e.g., on tablet where the panel is persistent).
  bool openMainDrawer() {
    final scaffold = Scaffold.maybeOf(this);
    if (scaffold != null && scaffold.hasDrawer) {
      scaffold.openDrawer();
      HapticFeedback.lightImpact();
      return true;
    }
    return false;
  }
}
