import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('gu'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileCenter.
  ///
  /// In en, this message translates to:
  /// **'Profile Center'**
  String get profileCenter;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @studyPreferences.
  ///
  /// In en, this message translates to:
  /// **'Study Preferences'**
  String get studyPreferences;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearance;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @studentDashboard.
  ///
  /// In en, this message translates to:
  /// **'Student Dashboard'**
  String get studentDashboard;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @dailyOverviewReady.
  ///
  /// In en, this message translates to:
  /// **'Your daily overview is ready.'**
  String get dailyOverviewReady;

  /// No description provided for @learningDNA.
  ///
  /// In en, this message translates to:
  /// **'Learning DNA'**
  String get learningDNA;

  /// No description provided for @seeStrengthsDeveloping.
  ///
  /// In en, this message translates to:
  /// **'See how your strengths are developing.'**
  String get seeStrengthsDeveloping;

  /// No description provided for @openProgress.
  ///
  /// In en, this message translates to:
  /// **'Open Progress'**
  String get openProgress;

  /// No description provided for @performanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Performance Summary'**
  String get performanceSummary;

  /// No description provided for @academicAssignmentProgress.
  ///
  /// In en, this message translates to:
  /// **'Academic and assignment progress from recent activity.'**
  String get academicAssignmentProgress;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @pendingWork.
  ///
  /// In en, this message translates to:
  /// **'Pending Work'**
  String get pendingWork;

  /// No description provided for @assignmentsNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'Assignments that still need your attention.'**
  String get assignmentsNeedAttention;

  /// No description provided for @viewAssignments.
  ///
  /// In en, this message translates to:
  /// **'View Assignments'**
  String get viewAssignments;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @xp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @quizAverage.
  ///
  /// In en, this message translates to:
  /// **'Quiz average'**
  String get quizAverage;

  /// No description provided for @assignmentsProgress.
  ///
  /// In en, this message translates to:
  /// **'Assignments progress'**
  String get assignmentsProgress;

  /// No description provided for @caughtUp.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up for now.'**
  String get caughtUp;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @teacherDashboard.
  ///
  /// In en, this message translates to:
  /// **'Teacher Dashboard'**
  String get teacherDashboard;

  /// No description provided for @parentDashboard.
  ///
  /// In en, this message translates to:
  /// **'Parent Dashboard'**
  String get parentDashboard;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @todayAtGlance.
  ///
  /// In en, this message translates to:
  /// **'Today at a Glance'**
  String get todayAtGlance;

  /// No description provided for @classPerformance.
  ///
  /// In en, this message translates to:
  /// **'Class Performance'**
  String get classPerformance;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @createAssignment.
  ///
  /// In en, this message translates to:
  /// **'Create Assignment'**
  String get createAssignment;

  /// No description provided for @createQuiz.
  ///
  /// In en, this message translates to:
  /// **'Create Quiz'**
  String get createQuiz;

  /// No description provided for @uploadNotes.
  ///
  /// In en, this message translates to:
  /// **'Upload Notes'**
  String get uploadNotes;

  /// No description provided for @resourceManagement.
  ///
  /// In en, this message translates to:
  /// **'Resource Management'**
  String get resourceManagement;

  /// No description provided for @childPerformance.
  ///
  /// In en, this message translates to:
  /// **'Child Performance'**
  String get childPerformance;

  /// No description provided for @recentGrades.
  ///
  /// In en, this message translates to:
  /// **'Recent Grades'**
  String get recentGrades;

  /// No description provided for @attendanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Attendance Overview'**
  String get attendanceOverview;

  /// No description provided for @teacherFeedback.
  ///
  /// In en, this message translates to:
  /// **'Teacher Feedback'**
  String get teacherFeedback;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @systemAnalytics.
  ///
  /// In en, this message translates to:
  /// **'System Analytics'**
  String get systemAnalytics;

  /// No description provided for @schoolSettings.
  ///
  /// In en, this message translates to:
  /// **'School Settings'**
  String get schoolSettings;

  /// No description provided for @broadcastAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Announcement'**
  String get broadcastAnnouncement;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @classSubject.
  ///
  /// In en, this message translates to:
  /// **'Class & Subject'**
  String get classSubject;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// No description provided for @guardianName.
  ///
  /// In en, this message translates to:
  /// **'Guardian Name'**
  String get guardianName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @homeAddress.
  ///
  /// In en, this message translates to:
  /// **'Home Address'**
  String get homeAddress;

  /// No description provided for @editProfileInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile Information'**
  String get editProfileInfo;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @schoolInformation.
  ///
  /// In en, this message translates to:
  /// **'School Information'**
  String get schoolInformation;

  /// No description provided for @academicSettings.
  ///
  /// In en, this message translates to:
  /// **'Academic Settings'**
  String get academicSettings;

  /// No description provided for @timetableManager.
  ///
  /// In en, this message translates to:
  /// **'Timetable Manager'**
  String get timetableManager;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @rolesPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get rolesPermissions;

  /// No description provided for @systemReports.
  ///
  /// In en, this message translates to:
  /// **'System & Reports'**
  String get systemReports;

  /// No description provided for @schoolReports.
  ///
  /// In en, this message translates to:
  /// **'School Reports'**
  String get schoolReports;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @logoutCommandCenter.
  ///
  /// In en, this message translates to:
  /// **'Logout Command Center'**
  String get logoutCommandCenter;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @syncingLearningDNA.
  ///
  /// In en, this message translates to:
  /// **'Syncing Learning DNA...'**
  String get syncingLearningDNA;

  /// No description provided for @syncDnaFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Sync DNA from history'**
  String get syncDnaFromHistory;

  /// No description provided for @loadingYourLearningDNA.
  ///
  /// In en, this message translates to:
  /// **'Loading your Learning DNA...'**
  String get loadingYourLearningDNA;

  /// No description provided for @academicCalendar.
  ///
  /// In en, this message translates to:
  /// **'Academic Calendar'**
  String get academicCalendar;

  /// No description provided for @viewAllAssignmentsQuizzesNotesByDate.
  ///
  /// In en, this message translates to:
  /// **'View all assignments, quizzes & notes by date'**
  String get viewAllAssignmentsQuizzesNotesByDate;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @assignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignment;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @mastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get mastered;

  /// No description provided for @learning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learning;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @yourLearningDNAIsForming.
  ///
  /// In en, this message translates to:
  /// **'Your Learning DNA is forming...'**
  String get yourLearningDNAIsForming;

  /// No description provided for @completeAssignmentsAndQuizzesToBuild.
  ///
  /// In en, this message translates to:
  /// **'Complete assignments and quizzes\\nto build your knowledge profile.'**
  String get completeAssignmentsAndQuizzesToBuild;

  /// No description provided for @performanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Performance Overview'**
  String get performanceOverview;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @mathematics.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get mathematics;

  /// No description provided for @science.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get science;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @computer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get computer;

  /// No description provided for @noPerformanceDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No performance data available.'**
  String get noPerformanceDataAvailable;

  /// No description provided for @learningVelocityOverall.
  ///
  /// In en, this message translates to:
  /// **'Learning Velocity (Overall)'**
  String get learningVelocityOverall;

  /// No description provided for @learningTrend.
  ///
  /// In en, this message translates to:
  /// **'Learning Trend'**
  String get learningTrend;

  /// No description provided for @subjectBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Subject Breakdown'**
  String get subjectBreakdown;

  /// No description provided for @masteryGoals.
  ///
  /// In en, this message translates to:
  /// **'Mastery Goals'**
  String get masteryGoals;

  /// No description provided for @averageScore.
  ///
  /// In en, this message translates to:
  /// **'Average Score'**
  String get averageScore;

  /// No description provided for @completeMoreQuizzesToSeeTrend.
  ///
  /// In en, this message translates to:
  /// **'Complete more quizzes to see trend!'**
  String get completeMoreQuizzesToSeeTrend;

  /// No description provided for @q.
  ///
  /// In en, this message translates to:
  /// **'Q'**
  String get q;

  /// No description provided for @noSubjectDataAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No subject data available yet.'**
  String get noSubjectDataAvailableYet;

  /// No description provided for @mastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get mastery;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @keepPracticingToImproveYourScore.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing to improve your score!'**
  String get keepPracticingToImproveYourScore;
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
      <String>['en', 'gu', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
