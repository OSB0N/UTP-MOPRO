import 'package:flutter/material.dart';

import '../state/backlog_store.dart';
import '../theme.dart';
import 'backlog_screen.dart';
import 'catalog_screen.dart';

/// Kerangka utama: dua tab (Katalog dan Backlog) dengan navigasi di bawah.
/// Halaman ketiga, Detail Game, dibuka dari kedua tab lewat Navigator.push.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _store = BacklogStore.instance;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const CatalogScreen(),
          BacklogScreen(onExplore: () => setState(() => _index = 0)),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final count = _store.items.length;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded, color: AppColors.onAccent),
                label: 'Katalog',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.bookmarks_outlined),
                ),
                selectedIcon: const Icon(Icons.bookmarks_rounded, color: AppColors.onAccent),
                label: 'Backlog',
              ),
            ],
          );
        },
      ),
    );
  }
}
