import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.location});

  final String location;

  static const _tabs = [
    ('/home', Icons.home_rounded, 'Home'),
    ('/clubs', Icons.groups_rounded, 'Clubs'),
    ('/events', Icons.event_rounded, 'Events'),
    ('/search', Icons.search_rounded, 'Search'),
    ('/profile', Icons.person_rounded, 'Profile'),
  ];

  int get _currentIndex {
    final index = _tabs.indexWhere((tab) => location.startsWith(tab.$1));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      destinations: _tabs
          .map(
            (tab) => NavigationDestination(icon: Icon(tab.$2), label: tab.$3),
          )
          .toList(growable: false),
      onDestinationSelected: (index) => context.go(_tabs[index].$1),
    );
  }
}
