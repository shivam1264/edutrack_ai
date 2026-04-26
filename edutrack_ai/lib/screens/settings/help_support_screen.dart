import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactCard(),
            const SizedBox(height: 32),
            _buildSectionTitle('FREQUENTLY ASKED QUESTIONS'),
            const SizedBox(height: 16),
            _buildFAQItem('How does AI Tutor work?', 'Our AI analyzes your textbook and class notes to provide context-aware help.'),
            _buildFAQItem('Can I use the app offline?', 'Yes, downloaded notes and certain flashcards work offline.'),
            _buildFAQItem('How do I join a Live Battle?', 'Go to Missions > AI Battle and wait for a lobby to open.'),
            const SizedBox(height: 32),
            _buildSectionTitle('LEGAL'),
            const SizedBox(height: 16),
            _buildActionTile(Icons.description_outlined, 'Privacy Policy'),
            _buildActionTile(Icons.gavel_outlined, 'Terms of Service'),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'Made with ❤️ by EduTrack AI Team',
                style: TextStyle(color: AppTheme.textHint, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: AppTheme.textHint));
  }

  Widget _buildContactCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded, size: 48, color: AppTheme.primary),
          const SizedBox(height: 16),
          const Text('Need Help?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Our support team is available 24/7 to assist you with any issues.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Email Us'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Live Chat'),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primary), foregroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: ListTile(
          leading: Icon(icon, color: AppTheme.textSecondary, size: 20),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () {},
        ),
      ),
    );
  }
}
