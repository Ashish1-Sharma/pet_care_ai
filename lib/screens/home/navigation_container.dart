import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import 'scan_tab.dart';
import '../history/history_tab.dart';
import '../profile/profile_tab.dart';
import '../chat/vet_chat_screen.dart';

/// Bottom padding scroll views add so items clear the floating FAB.
const double kFloatingNavHeight = 80;

/// Violet used exclusively for the vet-chat FAB.
const Color kVetFabColor = Color(0xFF7C3AED);

class NavigationContainer extends StatefulWidget {
  const NavigationContainer({super.key});

  @override
  State<NavigationContainer> createState() => NavigationContainerState();
}

class NavigationContainerState extends State<NavigationContainer> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const ScanTab(),
    const HistoryTab(),
    const ProfileTab(),
  ];

  void jumpToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VetChatScreen()),
        ),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            // color: kVetFabColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kVetFabColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset('assets/doctor.png', fit: BoxFit.contain),
        ),
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.surfaceElevated,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.center_focus_strong_rounded),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
