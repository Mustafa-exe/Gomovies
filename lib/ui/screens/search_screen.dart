import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/media_item.dart';
import '../../state/providers.dart';
import '../widgets/media_card.dart';
import 'detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<MediaItem> _items = <MediaItem>[];
  Timer? _debounce;
  bool _loading = false;
  Object? _error;
  static const List<String> _quick = <String>[
    'Action',
    'Comedy',
    'Drama',
    'Sci-Fi',
    'Documentary',
  ];

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _items.clear();
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(repositoryProvider);
      final result = await repo.search(query: query, page: 1);
      setState(() {
        _items
          ..clear()
          ..addAll(result.items);
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search movies, shows, anime, documentaries...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  _search('');
                },
              ),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () {
                _search(value);
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quick.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final term = _quick[index];
                return ActionChip(
                  label: Text(term),
                  onPressed: () {
                    _controller.text = term;
                    _search(term);
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Search error: $_error'),
          ),
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('Type to search across all configured sources'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return MediaCard(
                      item: item,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DetailScreen(itemId: item.id),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
