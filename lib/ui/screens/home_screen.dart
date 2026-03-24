import 'package:flutter/material.dart';

import 'catalog_screen.dart';
import 'downloads_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = <String>[
    'Discover',
    'Global Search',
    'Downloads',
    'Settings',
  ];

  static const _subtitles = <String>[
    'Trending and curated picks',
    'Search across every configured media source',
    'Manage queue, progress, and offline playback',
    'Configure APIs, source providers, and paths',
  ];

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const CatalogScreen(),
      const SearchScreen(),
      const DownloadsScreen(),
      const _SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titles[_index]),
            Text(
              _subtitles[_index],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Catalog'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.download), label: 'Downloads'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Control Center', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        _SettingCard(
          title: 'API Configuration',
          content: 'Run with --dart-define=TMDB_API_KEY=your_key to enable TMDB integration.',
          icon: Icons.vpn_key,
        ),
        SizedBox(height: 10),
        _SettingCard(
          title: 'Universal Source Search',
          content: 'Register additional JSON providers in providers.dart to search every medium from one box.',
          icon: Icons.hub,
        ),
        SizedBox(height: 10),
        _SettingCard(
          title: 'Storage Paths',
          content: 'Downloads are saved under app documents/media in movies and shows folders.',
          icon: Icons.folder_open,
        ),
        SizedBox(height: 10),
        _SettingCard(
          title: 'Launcher Icon',
          content: 'Run flutter pub run flutter_launcher_icons after Flutter is installed to apply icon on Android and iOS.',
          icon: Icons.image,
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  final String title;
  final String content;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0x3321D4FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(content, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
