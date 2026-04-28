import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_theme.dart';
import '../../settings/profile_screen.dart';
import '../user_management_screen.dart';
import '../permissions_screen.dart';
import '../system_settings_screen.dart';
import '../reports_screen.dart';
import '../school_analytics_screen.dart';
import '../timetable_manager_screen.dart';
import '../data_management_screen.dart';

class AdminProfileView extends StatelessWidget {
  const AdminProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, user),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle(AppLocalizations.of(context)!.general),
                _buildListTile(context, Icons.school_rounded, AppLocalizations.of(context)!.schoolInformation, const SchoolAnalyticsScreen()),
                _buildListTile(context, Icons.settings_suggest_rounded, AppLocalizations.of(context)!.academicSettings, const SystemSettingsScreen()),
                _buildListTile(context, Icons.calendar_month_rounded, AppLocalizations.of(context)!.timetableManager, const TimetableManagerScreen()),
                
                const SizedBox(height: 24),
                _buildSectionTitle(AppLocalizations.of(context)!.userManagement),
                _buildListTile(context, Icons.admin_panel_settings_rounded, AppLocalizations.of(context)!.manageUsers, const UserManagementScreen()),
                _buildListTile(context, Icons.security_rounded, AppLocalizations.of(context)!.rolesPermissions, const PermissionsScreen()),
                
                const SizedBox(height: 24),
                _buildSectionTitle(AppLocalizations.of(context)!.systemReports),
                _buildListTile(context, Icons.analytics_rounded, AppLocalizations.of(context)!.schoolReports, const ReportsScreen()),
                _buildListTile(context, Icons.storage_rounded, AppLocalizations.of(context)!.dataManagement, const DataManagementScreen()),
                
                const SizedBox(height: 32),
                _buildLogoutTile(context),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        ),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.profileCenter, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                  child: user?.avatarUrl == null 
                    ? const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 40)
                    : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Super Admin', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Email not available',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
                          child: Text(AppLocalizations.of(context)!.editProfile, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF94A3B8))),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, Widget destination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0F172A), size: 20),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF0F172A))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return InkWell(
      onTap: () => context.read<AuthProvider>().logout(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.1))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.logoutCommandCenter, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
