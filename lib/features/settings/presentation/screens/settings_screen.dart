import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/models/language_model.dart';
import 'package:math/l10n/app_localizations.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/services/language_service.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:math/core/services/theme_service.dart';
import 'package:math/core/services/zen_mode_service.dart';
import 'package:math/core/widgets/grade_selection_sheet.dart';
import 'package:math/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:math/features/settings/presentation/screens/help_feedback_screen.dart';
import 'package:math/features/settings/presentation/screens/terms_screen.dart';
import 'package:math/features/settings/presentation/screens/media_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:math/features/settings/presentation/screens/social_settings_screen.dart';
import 'package:math/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:math/features/profile/presentation/screens/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String? _selectedLanguage;
  String? _selectedMedium;
  String? _selectedGradeId;
  String? _selectedGradeName;

  List<LanguageModel> _availableMediums = [];
  bool _isLoading = true;

  final List<Map<String, String>> _appLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇬🇧'},
    {'code': 'si', 'name': 'Sinhala', 'nativeName': 'සිංහල', 'flag': '🇱🇰'},
    {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்', 'flag': '🇱🇰'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          _selectedLanguage = data['appLanguage'] as String?;
          _selectedMedium = data['learningMedium'] as String?;

          if (data['grades'] != null && (data['grades'] as List).isNotEmpty) {
            _selectedGradeId = (data['grades'] as List).first as String?;
          }
          _selectedGradeName =
              data['gradeName'] as String? ??
              (_selectedGradeId != null
                  ? "Grade ${_selectedGradeId!.split('_').last}"
                  : null);
        }
      }
      _availableMediums = await _apiService.getLanguages();
      setState(() => _isLoading = false);
    } catch (e) {
      logger.e('Error loading settings', error: e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final Map<String, dynamic> updateData = {
          if (_selectedLanguage != null) 'appLanguage': _selectedLanguage,
          if (_selectedMedium != null) 'learningMedium': _selectedMedium,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updateData, SetOptions(merge: true));

        if (!mounted) return;
        if (_selectedLanguage != null) {
          await context.read<LanguageService>().setLocale(_selectedLanguage!);
        }
      }
    } catch (e) {
      logger.e('Error saving settings', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final user = Provider.of<AuthService>(context).user;

    final String displayName = user?.displayName ?? 'Math Student';
    final String? photoUrl = user?.photoURL;
    final String bio = "Deep Focus in progress...";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          l10n.settings,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search settings...",
                prefixIcon: const Icon(Iconsax.search_normal_outline),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: _buildFilteredSettings(
                theme,
                l10n,
                displayName,
                bio,
                photoUrl,
              ),
            ),
    );
  }

  List<Widget> _buildFilteredSettings(
    ThemeData theme,
    AppLocalizations l10n,
    String name,
    String bio,
    String? photoUrl,
  ) {
    final sections = [
      _buildProfileSection(theme, name, bio, photoUrl),
      _buildFocusSection(theme),
      _buildAccountSection(theme, l10n),
      _buildEducationSection(theme, l10n),
      _buildSystemSection(theme, l10n),
      _buildSupportSection(theme),
      _buildSignOutSection(theme),
    ];

    if (_searchQuery.isEmpty) return sections;

    return sections.where((section) {
      return section.toString().toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Widget _buildProfileSection(
    ThemeData theme,
    String name,
    String bio,
    String? photoUrl,
  ) {
    return Column(
      children: [
        Card(
          elevation: 0,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.w),
            leading: CircleAvatar(
              radius: 30.r,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Iconsax.user_outline, color: theme.primaryColor)
                  : null,
            ),
            title: Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              bio,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            trailing: const Icon(Iconsax.arrow_right_3_outline),
            onTap: () => context.push('/profile'),
          ),
        ),
        SizedBox(height: 16.h),
        _buildListTile(
          theme,
          title: "Personal Information",
          subtitle: "Update name, bio, and location",
          icon: Iconsax.user_edit_outline,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildFocusSection(ThemeData theme) {
    final zenService = Provider.of<ZenModeService>(context);
    return _buildSection(theme, "Deep Focus", [
      _buildListTile(
        theme,
        title: "Zen Mode",
        subtitle: zenService.isEnabled
            ? "Active - ${zenService.formattedTime}"
            : "Distraction-free learning",
        icon: Iconsax.timer_1_outline,
        trailing: Switch(
          value: zenService.isEnabled,
          onChanged: (val) => zenService.toggleZenMode(),
        ),
      ),
      if (zenService.isEnabled)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFocusChip(theme, "25m", () => zenService.startSession(25)),
              _buildFocusChip(theme, "45m", () => zenService.startSession(45)),
              _buildFocusChip(theme, "60m", () => zenService.startSession(60)),
              IconButton(
                onPressed: () => zenService.stopSession(),
                icon: const Icon(Iconsax.stop_outline, color: Colors.red),
              ),
            ],
          ),
        ),
    ]);
  }

  Widget _buildFocusChip(ThemeData theme, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(ThemeData theme, AppLocalizations l10n) {
    return _buildSection(theme, "Social & Security", [
      _buildListTile(
        theme,
        title: "Privacy Firewall",
        subtitle: "Incognito mode, data control",
        icon: Iconsax.shield_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
        ),
      ),
      _buildListTile(
        theme,
        title: "Community Settings",
        subtitle: "Interactions, feed view",
        icon: Iconsax.messages_3_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SocialSettingsScreen()),
        ),
      ),
      _buildListTile(
        theme,
        title: "Notifications",
        subtitle: "Smart alerts, quality filter",
        icon: Iconsax.notification_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
        ),
      ),
      _buildListTile(
        theme,
        title: "Storage & Cache",
        subtitle: "Manage offline content and space",
        icon: Iconsax.box_outline,
        onTap: () => context.push(AppRouter.clearCachePath),
      ),
    ]);
  }

  Widget _buildEducationSection(ThemeData theme, AppLocalizations l10n) {
    return _buildSection(theme, "Learning", [
      _buildListTile(
        theme,
        title: "Academic Grade",
        subtitle: _selectedGradeName ?? "Not Set",
        icon: Iconsax.teacher_outline,
        onTap: _showGradeSelectionSheet,
      ),
      _buildListTile(
        theme,
        title: "Learning Medium",
        subtitle: _getMediumName(),
        icon: Iconsax.global_outline,
        onTap: _showMediumPicker,
      ),
    ]);
  }

  Widget _buildSystemSection(ThemeData theme, AppLocalizations l10n) {
    final themeService = Provider.of<ThemeService>(context);
    return _buildSection(theme, "System", [
      _buildListTile(
        theme,
        title: "App Language",
        subtitle: _getLanguageName(),
        icon: Iconsax.translate_outline,
        onTap: _showAppLanguagePicker,
      ),
      _buildListTile(
        theme,
        title: "Media Quality",
        subtitle: "Upload & download preferences",
        icon: Iconsax.video_vertical_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MediaSettingsScreen()),
        ),
      ),
      _buildListTile(
        theme,
        title: "Dark Mode",
        icon: themeService.themeMode == ThemeMode.dark
            ? Iconsax.moon_outline
            : Iconsax.sun_outline,
        trailing: Switch(
          value: themeService.themeMode == ThemeMode.dark,
          onChanged: (val) => themeService.toggleTheme(),
        ),
      ),
    ]);
  }

  Widget _buildSupportSection(ThemeData theme) {
    return _buildSection(theme, "Support", [
      _buildListTile(
        theme,
        title: "Help & Feedback",
        icon: Iconsax.message_question_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpFeedbackScreen()),
        ),
      ),
      _buildListTile(
        theme,
        title: "Terms & Conditions",
        icon: Iconsax.document_text_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TermsScreen()),
        ),
      ),
    ]);
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          ),
          child: Column(children: children),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildListTile(
    ThemeData theme, {
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.primaryColor),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null ? const Icon(Iconsax.arrow_right_3_outline) : null),
      onTap: onTap,
    );
  }

  Widget _buildSignOutSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 40.h),
      child: TextButton.icon(
        onPressed: () {
          Provider.of<AuthService>(context, listen: false).signOut();
          context.go('/welcome');
        },
        icon: const Icon(Iconsax.logout_outline, color: Colors.red),
        label: const Text("Sign Out", style: TextStyle(color: Colors.red)),
        style: TextButton.styleFrom(minimumSize: Size(double.infinity, 50.h)),
      ),
    );
  }

  String _getLanguageName() => _appLanguages.firstWhere(
    (l) => l['code'] == _selectedLanguage,
    orElse: () => {'nativeName': 'English'},
  )['nativeName']!;
  String _getMediumName() => _availableMediums
      .firstWhere(
        (m) => m.code == _selectedMedium,
        orElse: () => LanguageModel(
          code: '',
          label: '',
          nativeName: 'Not Set',
          order: 0,
          isActive: false,
        ),
      )
      .nativeName;

  void _showGradeSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GradeSelectionSheet(
        currentGradeId: _selectedGradeId,
        onGradeSelected: (grade) async {
          setState(() {
            _selectedGradeId = grade.id;
            _selectedGradeName = grade.name;
          });
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
                  'grades': [grade.id],
                  'gradeName': grade.name,
                }, SetOptions(merge: true));
          }
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showAppLanguagePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select App Language"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _appLanguages
                .map(
                  (lang) => ListTile(
                    leading: Text(
                      lang['flag']!,
                      style: TextStyle(fontSize: 24.sp),
                    ),
                    title: Text(lang['nativeName']!),
                    onTap: () async {
                      setState(() => _selectedLanguage = lang['code']);
                      await Provider.of<LanguageService>(
                        context,
                        listen: false,
                      ).setLocale(lang['code']!);
                      if (context.mounted) Navigator.pop(context);
                      _saveSettings();
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showMediumPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Learning Medium"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _availableMediums
                .map(
                  (m) => ListTile(
                    title: Text(m.nativeName),
                    onTap: () {
                      setState(() => _selectedMedium = m.code);
                      Navigator.pop(context);
                      _saveSettings();
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
