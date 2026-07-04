import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/screens/diagnosis_screen.dart';
import 'package:flutter_application_55555/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_application_55555/features/library/presentation/screen/library_screen.dart';
import 'package:flutter_application_55555/features/profile/presentation/screens/profile_screen.dart';

const int _mainNavTabCount = 4;

int _safeMainTabIndex(int index) {
  return index.clamp(0, _mainNavTabCount - 1).toInt();
}

/// Shared controller used by screens that need to switch the active main tab.
class MainNavController extends ChangeNotifier {
  MainNavController({int initialIndex = 0})
    : _index = _safeMainTabIndex(initialIndex);

  int _index;

  int get index => _index;

  void jumpToTab(int index) {
    final next = _safeMainTabIndex(index);
    if (_index == next) return;
    _index = next;
    notifyListeners();
  }
}

final MainNavController mainNavController = MainNavController(initialIndex: 0);

int homeTabIndexForDirection(TextDirection direction) =>
    direction == TextDirection.rtl ? 3 : 0;

void resetMainNavigationToHome(TextDirection direction) {
  final homeIndex = homeTabIndexForDirection(direction);
  if (mainNavController.index != homeIndex) {
    mainNavController.jumpToTab(homeIndex);
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final MainNavController _controller;

  @override
  void initState() {
    super.initState();
    _controller = mainNavController;
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      resetMainNavigationToHome(Directionality.of(context));
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onTabSelected(int index) {
    _controller.jumpToTab(index);
  }

  List<Widget> _buildScreens(BuildContext context) {
    const list = [
      HomeScreen(),
      DiagnosisScreen(),
      LibraryScreen(),
      ProfileScreen(),
    ];
    if (Directionality.of(context) == TextDirection.rtl) {
      return list.reversed.toList();
    }
    return list;
  }

  List<TabItem> _navBarItems(BuildContext context) {
    const items = [
      TabItem(icon: Icons.home, title: 'الرئيسية'),
      TabItem(icon: Icons.camera_alt, title: 'التشخيص'),
      TabItem(icon: Icons.library_books, title: 'المكتبة'),
      TabItem(icon: Icons.person, title: 'الملف الشخصي'),
    ];

    if (Directionality.of(context) == TextDirection.rtl) {
      return items.reversed.toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color.fromARGB(255, 124, 236, 156);
    const inactiveColor = Colors.grey;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        body: IndexedStack(
          index: _controller.index,
          children: _buildScreens(context),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: ConvexAppBar(
            key: ValueKey<int>(_controller.index),
            initialActiveIndex: _controller.index,
            items: _navBarItems(context),
            onTap: _onTabSelected,
            height: 50,
            style: TabStyle.react,
            backgroundColor: Colors.white,
            color: inactiveColor,
            activeColor: activeColor,
          ),
        ),
      ),
    );
  }
}
