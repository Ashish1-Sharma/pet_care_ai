import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';
import '../chat/vet_chat_screen.dart';
import '../history/history_tab.dart';
import '../payment/paywall_screen.dart';
import '../profile/profile_tab.dart';
import '../recovery/recovery_screen.dart';
import '../reminders/reminders_screen.dart';
import '../scan/scan_screen.dart';
import 'home_tab.dart';

/// Bottom padding scroll views add so items clear the bottom bar.
const double kFloatingNavHeight = 88;

/// Violet used for anything that talks to the AI Vet.
const Color kVetFabColor = Color(0xFF6D35D8);

/// Home · History · [Scan] · Ask Vet · Profile.
class NavigationContainer extends StatefulWidget {
  const NavigationContainer({super.key});

  @override
  State<NavigationContainer> createState() => NavigationContainerState();
}

class NavigationContainerState extends State<NavigationContainer> {
  static const int homeTab = 0;
  static const int historyTab = 1;
  static const int chatTab = 2;
  static const int profileTab = 3;

  int _currentIndex = homeTab;
  StreamSubscription<String>? _tapSub;

  final List<Widget> _tabs = const [
    HomeTab(),
    HistoryTab(),
    VetChatScreen(embedded: true),
    ProfileTab(),
  ];

  void jumpToTab(int index) => setState(() => _currentIndex = index);

  @override
  void initState() {
    super.initState();
    final notifications = NotificationService.instance;
    _tapSub = notifications.taps.listen(_openFromNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final launch = notifications.launchPayload;
      if (launch != null) {
        notifications.launchPayload = null;
        _openFromNotification(launch);
      }
    });
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  void _openFromNotification(String payload) {
    if (!mounted) return;
    if (payload.startsWith('recovery:')) {
      final seriesId = payload.substring('recovery:'.length);
      Navigator.push(context, AppRoutes.sharedAxis(RecoveryScreen(seriesId: seriesId)));
    } else if (payload == 'reminders') {
      Navigator.push(context, AppRoutes.sharedAxis(const RemindersScreen()));
    } else if (payload == 'scan') {
      openScan(context);
    } else if (payload == 'paywall') {
      PaywallScreen.open(context, source: 'notification');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: _BottomBar(
        currentIndex: _currentIndex,
        onTab: jumpToTab,
        onScan: () => openScan(context),
      ),
    );
  }
}

/// Opens a new scan for the selected pet. Shared by the centre button, Home
/// and notifications.
void openScan(BuildContext context, {String? recoveryOf}) {
  final provider = Provider.of<AppProvider>(context, listen: false);
  Navigator.push(
    context,
    AppRoutes.sharedAxis(
      ScanScreen(pet: provider.selectedPet, recoveryOf: recoveryOf),
    ),
  );
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onScan;

  const _BottomBar({
    required this.currentIndex,
    required this.onTab,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.alpha(AppColors.border, 0.9))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: currentIndex == NavigationContainerState.homeTab,
                onTap: () => onTab(NavigationContainerState.homeTab),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                selected: currentIndex == NavigationContainerState.historyTab,
                onTap: () => onTab(NavigationContainerState.historyTab),
              ),
              Expanded(
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'New scan',
                    child: GestureDetector(
                      onTap: onScan,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.glow(AppColors.teal, opacity: 0.35),
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Ask Vet',
                selected: currentIndex == NavigationContainerState.chatTab,
                selectedColor: kVetFabColor,
                onTap: () => onTab(NavigationContainerState.chatTab),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: currentIndex == NavigationContainerState.profileTab,
                onTap: () => onTab(NavigationContainerState.profileTab),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = AppColors.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
