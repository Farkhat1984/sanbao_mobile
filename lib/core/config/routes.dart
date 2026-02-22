/// GoRouter configuration with auth guard, onboarding guard, deep links,
/// and MainLayout shell.
///
/// Route structure:
/// - / (redirect to /chat)
/// - /splash
/// - /onboarding
/// - /login
/// - /register
/// - ShellRoute (MainLayout with sidebar drawer):
///   - /chat (new conversation)
///   - /chat/:id (existing conversation)
/// - /profile
/// - /profile/edit
/// - /settings
/// - /settings/2fa (2FA setup wizard)
/// - /agents
/// - /agents/new
/// - /agents/:id
/// - /agents/:id/edit
/// - /skills
/// - /skills/new
/// - /skills/:id
/// - /skills/:id/edit
/// - /artifacts/:id
/// - /tools
/// - /tools/new
/// - /tools/:id/edit
/// - /plugins
/// - /plugins/new
/// - /mcp-servers
/// - /mcp-servers/new
/// - /mcp-servers/:id/edit
/// - /memory
/// - /tasks
/// - /knowledge
/// - /knowledge/:id
/// - /billing
/// - /billing/plans
/// - /billing/success
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/storage/preferences.dart';
import 'package:sanbao_flutter/features/agents/domain/entities/agent.dart';
import 'package:sanbao_flutter/features/agents/presentation/screens/agent_detail_screen.dart';
import 'package:sanbao_flutter/features/agents/presentation/screens/agent_form_screen.dart';
import 'package:sanbao_flutter/features/agents/presentation/screens/agent_list_screen.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/screens/artifact_view_screen.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:sanbao_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:sanbao_flutter/features/auth/presentation/screens/register_screen.dart';
import 'package:sanbao_flutter/features/auth/presentation/screens/two_factor_setup_screen.dart';
import 'package:sanbao_flutter/features/billing/presentation/screens/billing_screen.dart';
import 'package:sanbao_flutter/features/billing/presentation/screens/payment_success_screen.dart';
import 'package:sanbao_flutter/features/billing/presentation/screens/plans_screen.dart';
import 'package:sanbao_flutter/features/chat/presentation/screens/chat_screen.dart';
import 'package:sanbao_flutter/features/chat/presentation/screens/main_layout.dart';
import 'package:sanbao_flutter/features/image_gen/presentation/screens/image_gen_full_screen.dart';
import 'package:sanbao_flutter/features/knowledge/presentation/screens/knowledge_detail_screen.dart';
import 'package:sanbao_flutter/features/knowledge/presentation/screens/knowledge_list_screen.dart';
import 'package:sanbao_flutter/features/mcp/domain/entities/mcp_server.dart';
import 'package:sanbao_flutter/features/mcp/presentation/screens/mcp_form_screen.dart';
import 'package:sanbao_flutter/features/mcp/presentation/screens/mcp_list_screen.dart';
import 'package:sanbao_flutter/features/memory/presentation/screens/memory_list_screen.dart';
import 'package:sanbao_flutter/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:sanbao_flutter/features/plugins/presentation/screens/plugin_form_screen.dart';
import 'package:sanbao_flutter/features/plugins/presentation/screens/plugin_list_screen.dart';
import 'package:sanbao_flutter/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:sanbao_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:sanbao_flutter/features/settings/presentation/screens/settings_screen.dart';
import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';
import 'package:sanbao_flutter/features/skills/presentation/screens/skill_detail_screen.dart';
import 'package:sanbao_flutter/features/skills/presentation/screens/skill_form_screen.dart';
import 'package:sanbao_flutter/features/skills/presentation/screens/skill_list_screen.dart';
import 'package:sanbao_flutter/features/tasks/presentation/screens/task_list_screen.dart';
import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';
import 'package:sanbao_flutter/features/tools/presentation/screens/tool_form_screen.dart';
import 'package:sanbao_flutter/features/tools/presentation/screens/tool_list_screen.dart';

/// Named route paths for type-safe navigation.
abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String chat = '/chat';
  static const String chatDetail = '/chat/:id';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String twoFactorSetup = '/settings/2fa';
  static const String agents = '/agents';
  static const String agentNew = '/agents/new';
  static const String agentDetail = '/agents/:id';
  static const String agentEdit = '/agents/:id/edit';
  static const String skills = '/skills';
  static const String skillNew = '/skills/new';
  static const String skillDetail = '/skills/:id';
  static const String skillEdit = '/skills/:id/edit';
  static const String artifactView = '/artifacts/:id';
  static const String billing = '/billing';
  static const String billingPlans = '/billing/plans';
  static const String billingSuccess = '/billing/success';
  static const String mcpServers = '/mcp-servers';
  static const String mcpServerNew = '/mcp-servers/new';
  static const String mcpServerEdit = '/mcp-servers/:id/edit';
  static const String tools = '/tools';
  static const String toolNew = '/tools/new';
  static const String toolEdit = '/tools/:id/edit';
  static const String plugins = '/plugins';
  static const String pluginNew = '/plugins/new';
  static const String memory = '/memory';
  static const String tasks = '/tasks';
  static const String knowledge = '/knowledge';
  static const String knowledgeDetail = '/knowledge/:id';
  static const String imageGen = '/image-gen';
}

/// Named routes for programmatic navigation.
abstract final class RouteNames {
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String chat = 'chat';
  static const String chatDetail = 'chatDetail';
  static const String profile = 'profile';
  static const String editProfile = 'editProfile';
  static const String settings = 'settings';
  static const String twoFactorSetup = 'twoFactorSetup';
  static const String agents = 'agents';
  static const String agentNew = 'agentNew';
  static const String agentDetail = 'agentDetail';
  static const String agentEdit = 'agentEdit';
  static const String skills = 'skills';
  static const String skillNew = 'skillNew';
  static const String skillDetail = 'skillDetail';
  static const String skillEdit = 'skillEdit';
  static const String artifactView = 'artifactView';
  static const String billing = 'billing';
  static const String billingPlans = 'billingPlans';
  static const String billingSuccess = 'billingSuccess';
  static const String mcpServers = 'mcpServers';
  static const String mcpServerNew = 'mcpServerNew';
  static const String mcpServerEdit = 'mcpServerEdit';
  static const String tools = 'tools';
  static const String toolNew = 'toolNew';
  static const String toolEdit = 'toolEdit';
  static const String plugins = 'plugins';
  static const String pluginNew = 'pluginNew';
  static const String memory = 'memory';
  static const String tasks = 'tasks';
  static const String knowledge = 'knowledge';
  static const String knowledgeDetail = 'knowledgeDetail';
  static const String imageGen = 'imageGen';
}

/// Creates the application router with auth guard, onboarding guard,
/// and MainLayout shell.
///
/// The [isAuthenticated] callback is checked on every navigation
/// to enforce login requirements. The [isAuthLoading] callback
/// prevents premature redirects during the initial session check.
/// The [isOnboardingCompleted] callback determines whether to
/// show the onboarding flow for first-time users.
///
/// Authenticated chat routes are wrapped in a [ShellRoute] that
/// provides the [MainLayout] scaffold with drawer/side panel.
GoRouter createRouter({
  required bool Function() isAuthenticated,
  required bool Function() isAuthLoading,
  required bool Function() isOnboardingCompleted,
  String? initialLocation,
}) =>
    GoRouter(
      initialLocation: initialLocation ?? RoutePaths.splash,
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final loading = isAuthLoading();
        final loggedIn = isAuthenticated();
        final onboarded = isOnboardingCompleted();
        final currentPath = state.matchedLocation;

        final isOnAuthPage = currentPath == RoutePaths.login ||
            currentPath == RoutePaths.register;
        final isOnSplash = currentPath == RoutePaths.splash;
        final isOnOnboarding = currentPath == RoutePaths.onboarding;

        // While auth state is loading, stay on splash / current page
        if (loading) {
          if (isOnSplash) return null;
          return RoutePaths.splash;
        }

        // Splash redirects based on auth + onboarding state
        if (isOnSplash) {
          if (!loggedIn) return RoutePaths.login;
          if (!onboarded) return RoutePaths.onboarding;
          return RoutePaths.chat;
        }

        // Not logged in: allow auth pages and onboarding only
        if (!loggedIn) {
          if (isOnAuthPage || isOnOnboarding) return null;
          return RoutePaths.login;
        }

        // Logged in but hasn't completed onboarding
        if (!onboarded && !isOnOnboarding) {
          return RoutePaths.onboarding;
        }

        // Logged in + onboarded but on auth page -> chat
        if (loggedIn && isOnAuthPage) return RoutePaths.chat;

        return null;
      },
      routes: [
        // Root redirect
        GoRoute(
          path: '/',
          redirect: (_, __) => RoutePaths.chat,
        ),

        // Splash
        GoRoute(
          path: RoutePaths.splash,
          name: RouteNames.splash,
          builder: (context, state) => const _SplashScreen(),
        ),

        // Onboarding (shown once for first-time users)
        GoRoute(
          path: RoutePaths.onboarding,
          name: RouteNames.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),

        // Auth routes
        GoRoute(
          path: RoutePaths.login,
          name: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RoutePaths.register,
          name: RouteNames.register,
          builder: (context, state) => const RegisterScreen(),
        ),

        // ---- Authenticated routes ----

        // Chat routes wrapped in MainLayout shell (sidebar drawer)
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: RoutePaths.chat,
              name: RouteNames.chat,
              builder: (context, state) => const ChatScreen(),
              routes: [
                // Deep link: /chat/:id loads a specific conversation
                GoRoute(
                  path: ':id',
                  name: RouteNames.chatDetail,
                  builder: (context, state) => const ChatScreen(),
                ),
              ],
            ),
          ],
        ),

        // Profile routes
        GoRoute(
          path: RoutePaths.profile,
          name: RouteNames.profile,
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              name: RouteNames.editProfile,
              builder: (context, state) => const EditProfileScreen(),
            ),
          ],
        ),

        // Settings
        GoRoute(
          path: RoutePaths.settings,
          name: RouteNames.settings,
          builder: (context, state) => const SettingsScreen(),
          routes: [
            // 2FA setup wizard
            GoRoute(
              path: '2fa',
              name: RouteNames.twoFactorSetup,
              builder: (context, state) => const TwoFactorSetupScreen(),
            ),
          ],
        ),

        // Agents routes
        GoRoute(
          path: RoutePaths.agents,
          name: RouteNames.agents,
          builder: (context, state) => const AgentListScreen(),
          routes: [
            // New agent (must come before :id to avoid conflict)
            GoRoute(
              path: 'new',
              name: RouteNames.agentNew,
              builder: (context, state) => const AgentFormScreen(),
            ),
            // Agent detail
            GoRoute(
              path: ':id',
              name: RouteNames.agentDetail,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return AgentDetailScreen(agentId: id);
              },
              routes: [
                // Edit agent
                GoRoute(
                  path: 'edit',
                  name: RouteNames.agentEdit,
                  builder: (context, state) {
                    // The agent data is passed via extra; the form screen
                    // loads it from the provider if extra is null.
                    final agent = state.extra as Agent?;
                    return AgentFormScreen(existingAgent: agent);
                  },
                ),
              ],
            ),
          ],
        ),

        // Skills routes
        GoRoute(
          path: RoutePaths.skills,
          name: RouteNames.skills,
          builder: (context, state) => const SkillListScreen(),
          routes: [
            // New skill
            GoRoute(
              path: 'new',
              name: RouteNames.skillNew,
              builder: (context, state) => const SkillFormScreen(),
            ),
            // Skill detail
            GoRoute(
              path: ':id',
              name: RouteNames.skillDetail,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return SkillDetailScreen(skillId: id);
              },
              routes: [
                // Edit skill
                GoRoute(
                  path: 'edit',
                  name: RouteNames.skillEdit,
                  builder: (context, state) {
                    final skill = state.extra as Skill?;
                    return SkillFormScreen(existingSkill: skill);
                  },
                ),
              ],
            ),
          ],
        ),

        // Artifacts route (full-screen viewer for tablet)
        GoRoute(
          path: RoutePaths.artifactView,
          name: RouteNames.artifactView,
          builder: (context, state) => const ArtifactViewScreen(),
        ),

        // Tools routes
        GoRoute(
          path: RoutePaths.tools,
          name: RouteNames.tools,
          builder: (context, state) => const ToolListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              name: RouteNames.toolNew,
              builder: (context, state) => const ToolFormScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              name: RouteNames.toolEdit,
              builder: (context, state) {
                final tool = state.extra as Tool?;
                return ToolFormScreen(tool: tool);
              },
            ),
          ],
        ),

        // Plugins routes
        GoRoute(
          path: RoutePaths.plugins,
          name: RouteNames.plugins,
          builder: (context, state) => const PluginListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              name: RouteNames.pluginNew,
              builder: (context, state) => const PluginFormScreen(),
            ),
          ],
        ),

        // MCP Servers routes
        GoRoute(
          path: RoutePaths.mcpServers,
          name: RouteNames.mcpServers,
          builder: (context, state) => const McpListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              name: RouteNames.mcpServerNew,
              builder: (context, state) => const McpFormScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              name: RouteNames.mcpServerEdit,
              builder: (context, state) {
                final server = state.extra as McpServer?;
                return McpFormScreen(server: server);
              },
            ),
          ],
        ),

        // Memory
        GoRoute(
          path: RoutePaths.memory,
          name: RouteNames.memory,
          builder: (context, state) => const MemoryListScreen(),
        ),

        // Tasks
        GoRoute(
          path: RoutePaths.tasks,
          name: RouteNames.tasks,
          builder: (context, state) => const TaskListScreen(),
        ),

        // Knowledge base (user files)
        GoRoute(
          path: RoutePaths.knowledge,
          name: RouteNames.knowledge,
          builder: (context, state) => const KnowledgeListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: RouteNames.knowledgeDetail,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return KnowledgeDetailScreen(fileId: id);
              },
            ),
          ],
        ),

        // Image generation
        GoRoute(
          path: RoutePaths.imageGen,
          name: RouteNames.imageGen,
          builder: (context, state) => const ImageGenFullScreen(),
        ),

        // Billing routes
        GoRoute(
          path: RoutePaths.billing,
          name: RouteNames.billing,
          builder: (context, state) => const BillingScreen(),
          routes: [
            GoRoute(
              path: 'plans',
              name: RouteNames.billingPlans,
              builder: (context, state) => const PlansScreen(),
            ),
            GoRoute(
              path: 'success',
              name: RouteNames.billingSuccess,
              builder: (context, state) => const PaymentSuccessScreen(),
            ),
          ],
        ),
      ],

      // Error page for unknown routes
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Страница не найдена',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  state.error?.toString() ?? 'Неизвестная ошибка',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(RoutePaths.chat),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Перейти к чату'),
              ),
            ],
          ),
        ),
      ),
    );

/// Splash screen shown during initial auth state resolution.
///
/// Displays the Sanbao logo with a loading indicator while
/// the auth provider checks for a valid stored session.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4F6EF7), Color(0xFF7C3AED)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sanbao',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
}

/// Provider that supplies the GoRouter instance.
///
/// Watches [authStateProvider] and [onboardingCompletedProvider] to
/// trigger route re-evaluation when authentication or onboarding state
/// changes. The router's [redirect] callback reads these states on
/// every navigation event.
///
/// Also watches [authNotificationBridgeProvider] to keep the
/// notification polling lifecycle in sync with auth state.
final routerProvider = Provider<GoRouter>((ref) {
  // Watch the auth state so the router refreshes on changes
  final authState = ref.watch(authStateProvider);

  // Keep notification polling in sync with auth state
  ref.watch(authNotificationBridgeProvider);

  // Watch onboarding completion state
  // Import is available via transitive dependency through the provider.
  // We read directly from preferences to avoid circular deps.
  final prefs = ref.watch(preferencesProvider);

  return createRouter(
    isAuthenticated: () => authState is AuthAuthenticated,
    isAuthLoading: () =>
        authState is AuthInitial || authState is AuthLoading,
    isOnboardingCompleted: () => prefs.isOnboardingCompleted,
  );
});
