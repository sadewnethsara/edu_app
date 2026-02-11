import 'package:flutter/material.dart'; // 🚀 ADDED for error Scaffolds
import 'package:go_router/go_router.dart';
import 'package:math/data/models/content_model.dart'; // 🚀 ADDED for ContentItem
import 'package:math/features/social/feed/models/post_model.dart'; // 🚀 ADDED for PostModel
import 'package:math/screens/all_lessons_screen.dart';
import 'package:math/screens/app_usage_screen.dart';
import 'package:math/features/social/community/screens/community_screen.dart';
import 'package:math/features/social/create_post/screens/create_post_screen.dart';
import 'package:math/features/social/feed/screens/feed_screen.dart';
import 'package:math/features/social/feed/screens/favorites_screen.dart';
import 'package:math/screens/language_selection_screen.dart';
import 'package:math/screens/leaderboard_screen.dart';
import 'package:math/screens/curriculum/lesson_content_screen.dart';
import 'package:math/screens/curriculum/lessons_screen.dart';
import 'package:math/screens/login_screen.dart';
import 'package:math/screens/new_home_screen.dart';
import 'package:math/screens/notifications_screen.dart';
import 'package:math/screens/past_papers_screen.dart';
import 'package:math/features/social/feed/screens/post_detail_screen.dart';
import 'package:math/features/social/feed/screens/tag_posts_screen.dart';
import 'package:math/features/social/feed/screens/filtered_posts_screen.dart'; // 🚀 ADDED
import 'package:math/screens/profile_screen.dart';
import 'package:math/screens/settings_screen.dart';
import 'package:math/screens/splash_screen.dart';
import 'package:math/screens/streak_screen.dart';
import 'package:math/screens/curriculum/subjects_screen.dart';
import 'package:math/screens/curriculum/subtopics_screen.dart';
import 'package:math/screens/curriculum/subtopic_content_screen.dart';
import 'package:math/screens/welcome_screen.dart';
import 'package:math/screens/global_search_screen.dart';
import 'package:math/screens/lesson_search_screen.dart';
import 'package:math/screens/clear_cache_screen.dart';
import 'package:math/screens/user_list_screen.dart';
import 'package:math/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/onboarding/app_onboarding_screen.dart';

// 🚀 ADDED: Import your new viewer screens
import 'package:math/features/social/community/screens/communities_list_screen.dart'; // 🚀 ADDED
import 'package:math/features/social/community/screens/create_community_screen.dart';
import 'package:math/features/social/community/screens/community_settings_screen.dart';
import 'package:math/features/social/community/screens/community_selection_screen.dart';
import 'package:math/features/social/community/screens/community_members_screen.dart';
import 'package:math/features/social/community/screens/community_posts_review_screen.dart';
import 'package:math/features/social/community/screens/edit_community_screen.dart';
// (Make sure these paths match your project structure)
import 'package:math/screens/video_player_screen.dart' hide logger;
import 'package:math/screens/note_viewer_screen.dart' hide logger;
import 'package:math/screens/pdf_viewer_screen.dart' hide logger;
import 'package:math/screens/past_paper_pdf_viewer_screen.dart';
import 'package:math/widgets/main_scaffold.dart';

class AppRouter {
  final AuthService authService;
  late final GoRouter router;

  AppRouter({required this.authService}) {
    router = _createRouter();
  }

  // --- Define Route Paths ---
  static const String splashPath = '/'; // Splash is the new root
  static const String welcomePath = '/welcome';
  static const String onboardingPath = '/onboarding';
  static const String loginPath = '/login';
  static const String languageSelectionPath = '/language-selection';
  static const String homePath = '/home';
  static const String oldHomePath = '/old-home';
  static const String settingsPath = '/settings';
  static const String allLessonsPath = '/lessons';
  static const String subjectsPath = '/subjects/:gradeId';
  static const String lessonsPath = '/subjects/:gradeId/:subjectId';
  static const String lessonContentPath =
      '/subjects/:gradeId/:subjectId/lessons/:lessonId';
  static const String subtopicsPath =
      '/subjects/:gradeId/:subjectId/lessons/:lessonId/subtopics';
  static const String pastPapersPath = '/past-papers';

  // 🚀 ADDED: Paths for new content viewers
  static const String videoPlayerPath = '/video-player';
  static const String noteViewerPath = '/note-viewer';
  static const String pdfViewerPath = '/pdf-viewer';
  static const String pastPaperPdfViewerPath = '/past-paper-viewer';
  static const String appUsagePath = '/app-usage';
  static const String leaderboardPath = '/leaderboard';
  static const String streakPath = '/streak';
  static const String profilePath = '/profile';
  static const String feedPath = '/feed';
  static const String createPostPath = '/create-post';
  static const String postDetailPath = '/post/:postId';
  static const String notificationPath = '/notification';
  static const String searchUsersPath = '/search-users';
  static const String tagPostsPath = '/tags/:tag';
  static const String filteredPostsPath = '/filter/:type/:value';
  static const String filteredPostsName = 'filtered-posts';
  static const String favoritesPath = '/feed/favorites';
  static const String clearCachePath = '/clear-cache';
  static const String mutedAccountsPath = '/muted-accounts';
  static const String blockedAccountsPath = '/blocked-accounts';

  static const String lessonSearchPath = '/lesson-search';
  static const String communitiesPath = '/communities';
  static const String createCommunityPath = '/create-community';
  static const String communityPath = '/community/:communityId';
  static const String communitySettingsPath =
      '/community/:communityId/settings';
  static const String editCommunityPath = '/community/:communityId/edit';
  static const String communityMembersPath = '/community/:communityId/members';
  static const String communityReviewPath = '/community/:communityId/review';
  static const String communitySelectionPath = '/select-community';

  // Route Names
  static const String createPostName = 'create-post';
  static const String communityName = 'community';
  static const String communitiesListName = 'communities-list';
  static const String createCommunityName = 'create-community';
  static const String communitySettingsName = 'community-settings';
  static const String editCommunityName = 'edit-community';
  static const String communityMembersName = 'community-members';
  static const String communityReviewName = 'community-review';
  static const String communitySelectionName = 'community-selection';

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: splashPath,
      refreshListenable: authService,
      routes: [
        // --- OUTSIDE SHELL (Full Screen) ---
        GoRoute(
          path: splashPath,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: welcomePath,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: onboardingPath,
          builder: (context, state) => const AppOnboardingScreen(),
        ),
        GoRoute(
          path: loginPath,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: languageSelectionPath,
          builder: (context, state) => const LanguageSelectionScreen(),
        ),
        GoRoute(
          path: searchUsersPath,
          builder: (context, state) => const GlobalSearchScreen(),
        ),
        GoRoute(
          path: lessonSearchPath,
          builder: (context, state) => const LessonSearchScreen(),
        ),
        GoRoute(
          path: tagPostsPath,
          builder: (context, state) =>
              TagPostsScreen(tag: state.pathParameters['tag']!),
        ),
        GoRoute(
          path: filteredPostsPath,
          name: filteredPostsName,
          builder: (context, state) {
            final typeStr = state.pathParameters['type'] ?? 'tag';
            final value = state.pathParameters['value'] ?? '';
            // Make title optional in extra, fallback to value
            final titleRaw = state.extra;
            final String title = (titleRaw is String) ? titleRaw : value;

            FilterType type;
            switch (typeStr) {
              case 'tag':
                type = FilterType.tag;
                break;
              case 'category':
                type = FilterType.category;
                break;
              case 'subject':
                type = FilterType.subject;
                break;
              default:
                type = FilterType.tag;
            }

            return FilteredPostsScreen(
              title: title,
              filterType: type,
              filterValue: value,
            );
          },
        ),

        // --- INSIDE SHELL (Persistent Nav Bar) ---
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScaffold(navigationShell: navigationShell);
          },
          branches: [
            // 1. HOME
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: homePath,
                  builder: (context, state) => const NewHomeScreen(),
                  routes: [],
                ),
              ],
            ),

            // 2. COURSES (All Lessons)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: allLessonsPath,
                  builder: (context, state) => const AllLessonsScreen(),
                ),
              ],
            ),

            // 3. COMMUNITY (Feed)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: feedPath,
                  builder: (context, state) => const FeedScreen(),
                ),
              ],
            ),

            // 4. NOTIFICATION
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: notificationPath,
                  builder: (context, state) => const NotificationsScreen(),
                ),
              ],
            ),

            // 5. PROFILE
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: profilePath,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        // --- OTHER ROUTES (Fullscreen or Modals) ---
        // Duplicate routes if needed or keep ones that shouldn't have nav bar:
        GoRoute(
          path: settingsPath,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: clearCachePath,
          builder: (context, state) => const ClearCacheScreen(),
        ),
        GoRoute(
          path: mutedAccountsPath,
          builder: (context, state) =>
              const UserListScreen(type: UserListType.muted),
        ),
        GoRoute(
          path: blockedAccountsPath,
          builder: (context, state) =>
              const UserListScreen(type: UserListType.blocked),
        ),
        GoRoute(
          path: favoritesPath,
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: pastPapersPath,
          builder: (context, state) => const PastPapersScreen(),
        ),
        GoRoute(
          path: appUsagePath,
          builder: (context, state) => const AppUsageScreen(),
        ),
        GoRoute(
          path: leaderboardPath,
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: streakPath,
          builder: (context, state) => const StreakScreen(),
        ),
        GoRoute(
          path: createPostPath,
          name: createPostName,
          builder: (context, state) {
            final extra = state.extra;
            PostModel? quotedPost;
            String? communityId;
            String? communityName;
            String? communityIcon;

            if (extra is PostModel) {
              quotedPost = extra;
            } else if (extra is Map<String, dynamic>) {
              if (extra['quotedPost'] is PostModel) {
                quotedPost = extra['quotedPost'] as PostModel;
              }
              // Handle other map fields if needed, but primary use here is for community
              communityId = extra['communityId'] as String?;
              communityName = extra['communityName'] as String?;
              communityIcon = extra['communityIcon'] as String?;
            }

            return CreatePostScreen(
              quotedPost: quotedPost,
              communityId: communityId,
              communityName: communityName,
              communityIcon: communityIcon,
            );
          },
        ),
        GoRoute(
          path: postDetailPath,
          builder: (context, state) =>
              PostDetailScreen(postId: state.pathParameters['postId']!),
        ),
        GoRoute(
          path: communityPath,
          name: communityName,
          builder: (context, state) => CommunityScreen(
            communityId: state.pathParameters['communityId']!,
          ),
        ),
        GoRoute(
          path: communitiesPath,
          name: communitiesListName,
          builder: (context, state) => const CommunitiesListScreen(),
        ),
        GoRoute(
          path: createCommunityPath,
          name: createCommunityName,
          builder: (context, state) => const CreateCommunityScreen(),
        ),
        GoRoute(
          path: communitySettingsPath,
          name: communitySettingsName,
          builder: (context, state) => CommunitySettingsScreen(
            communityId: state.pathParameters['communityId']!,
          ),
        ),
        GoRoute(
          path: editCommunityPath,
          name: editCommunityName,
          builder: (context, state) => EditCommunityScreen(
            communityId: state.pathParameters['communityId']!,
          ),
        ),
        GoRoute(
          path: communityMembersPath,
          name: communityMembersName,
          builder: (context, state) => CommunityMembersScreen(
            communityId: state.pathParameters['communityId']!,
          ),
        ),
        GoRoute(
          path: communityReviewPath,
          name: communityReviewName,
          builder: (context, state) => CommunityPostsReviewScreen(
            communityId: state.pathParameters['communityId']!,
          ),
        ),
        GoRoute(
          path: communitySelectionPath,
          name: communitySelectionName,
          builder: (context, state) => const CommunitySelectionScreen(),
        ),

        // 🚀 FULL SCREEN: Subjects Flow
        GoRoute(
          path: '/subjects/:gradeId',
          builder: (context, state) =>
              SubjectsScreen(gradeId: state.pathParameters['gradeId']!),
          routes: [
            GoRoute(
              path: ':subjectId',
              builder: (context, state) => LessonsScreen(
                gradeId: state.pathParameters['gradeId']!,
                subjectId: state.pathParameters['subjectId']!,
              ),
              routes: [
                GoRoute(
                  path: 'lessons/:lessonId',
                  builder: (context, state) => LessonContentScreen(
                    gradeId: state.pathParameters['gradeId']!,
                    subjectId: state.pathParameters['subjectId']!,
                    lessonId: state.pathParameters['lessonId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'subtopics',
                      builder: (context, state) => SubtopicsScreen(
                        gradeId: state.pathParameters['gradeId']!,
                        subjectId: state.pathParameters['subjectId']!,
                        lessonId: state.pathParameters['lessonId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: ':subtopicId',
                          builder: (context, state) => SubtopicContentScreen(
                            gradeId: state.pathParameters['gradeId']!,
                            subjectId: state.pathParameters['subjectId']!,
                            lessonId: state.pathParameters['lessonId']!,
                            subtopicId: state.pathParameters['subtopicId']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Video/Viewers
        GoRoute(
          path: videoPlayerPath,
          builder: (context, state) {
            if (state.extra is Map<String, dynamic>) {
              final args = state.extra as Map<String, dynamic>;
              return VideoPlayerScreen(
                playlist: args['playlist'] as List<ContentItem>,
                startIndex: args['startIndex'] as int? ?? 0,
              );
            }
            return const Scaffold(body: Center(child: Text('Error')));
          },
        ),

        // ... (Other viewers kept as is, assuming they are fullscreen modal-like)
        GoRoute(
          path: noteViewerPath,
          builder: (context, state) {
            if (state.extra is Map<String, dynamic>) {
              final args = state.extra as Map<String, dynamic>;
              return NoteViewerScreen(
                itemList: args['itemList'] as List<ContentItem>,
                startIndex: args['startIndex'] as int? ?? 0,
              );
            }
            return const Scaffold(
              body: Center(child: Text('Error: Note data not provided')),
            );
          },
        ),

        GoRoute(
          path: pdfViewerPath,
          builder: (context, state) {
            if (state.extra is Map<String, dynamic>) {
              final args = state.extra as Map<String, dynamic>;
              return PdfViewerScreen(
                itemList: args['itemList'] as List<ContentItem>,
                startIndex: args['startIndex'] as int? ?? 0,
              );
            }
            return const Scaffold(
              body: Center(child: Text('Error: PDF data not provided')),
            );
          },
        ),

        GoRoute(
          path: pastPaperPdfViewerPath,
          builder: (context, state) {
            if (state.extra is Map<String, dynamic>) {
              final args = state.extra as Map<String, dynamic>;
              return PastPaperPdfViewerScreen(
                title: args['title'] as String,
                pdfUrl: args['pdfUrl'] as String,
              );
            }
            return const Scaffold(
              body: Center(child: Text('Error: PDF data not provided')),
            );
          },
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) async {
        final prefs = await SharedPreferences.getInstance();
        final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

        final authStatus = authService.status;
        final location = state.matchedLocation;

        logger.i(
          'Router Redirect: AuthStatus=$authStatus, Location=$location, Onboarding=$onboardingComplete',
        );

        // --- REDIRECT LOGIC ---

        // 1. While app is initializing, stay on current location (don't redirect during hot reload)
        if (authStatus == AuthStatus.uninitialized) {
          // Only redirect to splash if we're truly at the splash screen
          if (location == splashPath) {
            return null; // Stay at splash
          }
          // Otherwise, stay where we are (prevents hot reload redirects)
          return null;
        }

        // 2. If user is authenticated
        if (authStatus == AuthStatus.authenticated) {
          // If they are on splash or welcome, send them to home.
          if (location == splashPath || location == welcomePath) {
            return homePath;
          }
          // If they're trying to access onboarding or login while logged in, redirect to home
          if (location == onboardingPath || location == loginPath) {
            return homePath;
          }
        }
        // 3. If user is NOT authenticated
        else {
          // 3a. If they are on protected routes, send to target entry point
          if (location == splashPath || location == homePath) {
            // If onboarding is complete, they are likely a returning user -> Login
            // Otherwise, they are a new user -> Welcome
            return onboardingComplete ? loginPath : welcomePath;
          }

          // 3b. If they are anywhere else (onboardingPath, loginPath, welcomePath),
          // let them stay. No aggressive redirects from onboardingPath to loginPath.
        }

        // 4. No redirect needed
        return null;
      },
    );
  }
}
