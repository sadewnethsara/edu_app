import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  String get chooseYourAppLanguage;

  String get languagePageSubtitle;

  String get pleaseSelectLanguage;

  String get settings;

  String get accountSettings;

  String get learningPreferences;

  String get personalInformation;

  String get saveAllChanges;

  String get appLanguage;

  String get selectAppLanguage;

  String get learningMedium;

  String get selectLearningMedium;

  String get yourGrades;

  String get noGradesAvailable;

  String get settingsSavedSuccessfully;

  String get failedToSaveSettings;

  String get cancel;

  String get fullName;

  String get province;

  String get district;

  String get city;

  String get gender;

  String get notSet;

  String get noName;

  String get noEmail;

  String get loading;

  String get save;

  String get close;

  String get done;

  String get next;

  String get previous;

  String get finish;

  String get continueButton;

  String get skip;

  String get ok;

  String get yes;

  String get no;

  String get error;

  String get success;

  String get retry;

  String get refresh;

  String get home;

  String get subjects;

  String get lessons;

  String get pastPapers;

  String get leaderboard;

  String get profile;

  String get welcome;

  String get signIn;

  String get signOut;

  String get signUp;

  String get login;

  String get logout;

  String get email;

  String get password;

  String get forgotPassword;

  String get dontHaveAccount;

  String get alreadyHaveAccount;

  String get signInWithGoogle;

  String get signInWithEmail;

  String get welcomeBack;

  String get yourLearningJourney;

  String get continueWhere;

  String get exploreSubjects;

  String get recentActivity;

  String get noRecentActivity;

  String get dailyStreak;

  String get daysStreak;

  String get keepItUp;

  String get allSubjects;

  String get noSubjectsAvailable;

  String get selectSubject;

  String get mathematics;

  String get science;

  String get language;

  String get allLessons;

  String get noLessonsAvailable;

  String get lessonContent;

  String get startLesson;

  String get continueLesson;

  String get completedLessons;

  String get inProgress;

  String get notStarted;

  String get locked;

  String get unlocked;

  String get subtopics;

  String get noSubtopicsAvailable;

  String get videos;

  String get notes;

  String get pdfs;

  String get resources;

  String get noVideosAvailable;

  String get noNotesAvailable;

  String get noPdfsAvailable;

  String get noResourcesAvailable;

  String get playVideo;

  String get openNote;

  String get openPdf;

  String get openInExternalApp;

  String get download;

  String get videoPlayer;

  String get upNext;

  String get downloadFeatureNotImplemented;

  String get searchPastPapers;

  String get noPastPapersAvailable;

  String get filterByYear;

  String get filterBySubject;

  String get filterByGrade;

  String get allYears;

  String get year;

  String get term;

  String get viewPaper;

  String get viewAnswers;

  String get answers;

  String get myProfile;

  String get editProfile;

  String get accountInfo;

  String get preferences;

  String get statistics;

  String get achievements;

  String get noAchievements;

  String get topPerformers;

  String get yourRank;

  String get points;

  String get rank;

  String get noLeaderboardData;

  String get changeTheme;

  String get lightMode;

  String get darkMode;

  String get systemDefault;

  String get pullToRefresh;

  String get refreshing;

  String get grades;

  String get selectYourGrades;

  String get grade;

  String get english;

  String get sinhala;

  String get tamil;

  String get somethingWentWrong;

  String get tryAgainLater;

  String get noInternetConnection;

  String get checkConnection;

  String get failedToLoad;

  String get errorLoadingData;

  String get errorOccurred;

  String get noDataAvailable;

  String get nothingToShow;

  String get comeBackLater;

  String get startExploring;

  String get errorCouldNotLoadVideo;

  String get videoCouldNotBePlayed;

  String get untitledVideo;

  String get downloadVideoTooltip;

  String get pdfDocument;

  String get failedToLoadPdf;

  String get markAsCompleted;

  String markedAsCompleted(String name);

  String get failedToLoadContent;

  String get streakDialog;

  String get congratulations;

  String get keepLearning;

  String get allYourLessons;

  String get organizedByGrade;

  String get tapToExpand;

  String get noContentAvailable;
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
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
