import 'package:math/app_exports.dart';

class AppRouter {
  final AuthService authService;
  late final GoRouter router;

  AppRouter({required this.authService}) {
    router = _createRouter();
  }

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

        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: homePath,
                  builder: (context, state) => const NewHomeScreen(),
                  routes: [],
                ),
              ],
            ),

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: allLessonsPath,
                  builder: (context, state) => const AllLessonsScreen(),
                ),
              ],
            ),

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: feedPath,
                  builder: (context, state) => const FeedScreen(),
                ),
              ],
            ),

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: notificationPath,
                  builder: (context, state) => const NotificationsScreen(),
                ),
              ],
            ),

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

        if (authStatus == AuthStatus.uninitialized) {
          if (location == splashPath) {
            return null; // Stay at splash
          }
          return null;
        }

        if (authStatus == AuthStatus.authenticated) {
          if (location == splashPath || location == welcomePath) {
            return homePath;
          }
          if (location == onboardingPath || location == loginPath) {
            return homePath;
          }
        } else {
          if (location == splashPath || location == homePath) {
            return onboardingComplete ? loginPath : welcomePath;
          }
        }

        return null;
      },
    );
  }
}
