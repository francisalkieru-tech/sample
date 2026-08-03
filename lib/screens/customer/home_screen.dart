import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import 'repair_request_screen.dart';
import 'repair_history_screen.dart';

// Placeholder contact details ng repair shop — palitan na lang sa
// actual number/FB page pag ready na.
const String _kShopSmsNumber = '+639171234567';
const String _kShopFacebookUrl = 'https://facebook.com/yourrepairshop';

/// Home tab content — ito yung unang tab ng MainNavScreen.
/// Hiwalay na ito sa bottom nav shell mismo (tingnan ang
/// main_nav_screen.dart) para malinaw na "home content lang ito",
/// hindi ang buong Scaffold+nav.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToRepairTab;

  const HomeScreen({
    super.key,
    this.onGoToRepairTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting header — dark card gaya ng mockup
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F2937), Color(0xFF111827)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, "${user?.email ?? 'Customer'}"',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Welcome to the RepairTrack',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white54, width: 1.5),
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 26),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Repair Summary — stats row
              const Text(
                'Your Repair Summary:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('repairRequests')
                    .where('customerId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  int inProcess = 0;
                  int complete = 0;

                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'];
                    if (status == 'Completed') {
                      complete++;
                    } else if (status != 'Declined') {
                      // Lahat ng hindi pa Completed/Declined ay
                      // itinuturing na "In Process" para sa stats.
                      inProcess++;
                    }
                  }

                  final total = docs.length;

                  return Row(
                    children: [
                      Expanded(
                        child: _SummaryStatCard(
                          value: inProcess,
                          label: 'In Process',
                          onTap: widget.onGoToRepairTab,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryStatCard(
                          value: complete,
                          label: 'Complete',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RepairHistoryScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryStatCard(
                          value: total,
                          label: 'Total',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RepairHistoryScreen()),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              const Text(
                'What do you need?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Repair Request
              _MenuCard(
                backgroundColor: Colors.black,
                icon: Icons.build_circle_outlined,
                iconColor: Colors.white,
                title: 'Submit Your Repair Request',
                subtitle:
                    'Fill out a form and we\'ll guide you through basic troubleshooting before submitting repair request .',
                titleColor: Colors.white,
                subtitleColor: Colors.white70,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RepairRequestScreen()),
                ),
              ),
              const SizedBox(height: 12),

              // Active Repair — nagba-navigate papunta sa Repair tab
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('repairRequests')
                    .where('customerId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  final activeCount = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'];
                    return status != 'Completed' && status != 'Declined';
                  }).length;

                  return _MenuCard(
                    backgroundColor: const Color(0xFF6B7280),
                    icon: Icons.access_time,
                    iconColor: Colors.white,
                    title: 'Active Repair ($activeCount)',
                    subtitle: 'Click to view your repair progress',
                    titleColor: Colors.white,
                    subtitleColor: Colors.white70,
                    onTap: widget.onGoToRepairTab,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Repair History
              _MenuCard(
                backgroundColor: const Color(0xFF9CA3AF),
                icon: Icons.assignment_turned_in_outlined,
                iconColor: Colors.white,
                title: 'Repair History',
                subtitle: 'View your completed repairs and service record.',
                titleColor: Colors.white,
                subtitleColor: Colors.white70,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RepairHistoryScreen()),
                ),
              ),
              const SizedBox(height: 20),

              // Need help? — support link/footer
              Center(
                child: GestureDetector(
                  onTap: () => _showHelpSheet(context),
                  child: const Text(
                    'Need Help?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Need help?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Reach out to us through any of these options.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),

                // Option 1: Message via SMS
                _HelpOptionTile(
                  icon: Icons.sms_outlined,
                  label: 'Message via SMS',
                  subtitle: _kShopSmsNumber,
                  onTap: () async {
                    Navigator.pop(context);
                    await _launchSms(context, _kShopSmsNumber);
                  },
                ),
                const SizedBox(height: 10),

                // Option 2: Visit Facebook Page
                _HelpOptionTile(
                  icon: Icons.facebook_outlined,
                  label: 'Visit our Facebook Page',
                  subtitle: 'Message us on Facebook',
                  onTap: () async {
                    Navigator.pop(context);
                    await _launchFacebook(context, _kShopFacebookUrl);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchSms(BuildContext context, String number) async {
    final uri = Uri(scheme: 'sms', path: number);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      _showLaunchError(context, 'Hindi mabuksan ang SMS app.');
    }
  }

  Future<void> _launchFacebook(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showLaunchError(context, 'Hindi mabuksan ang Facebook.');
    }
  }

  void _showLaunchError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Isang stat card sa "Your Repair Summary" row (In Process / Complete / Total).
class _SummaryStatCard extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _SummaryStatCard({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF111827), width: 1.2),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Color? backgroundColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback? onTap;

  const _MenuCard({
    this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: titleColor),
          ],
        ),
      ),
    );
  }
}

class _HelpOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}