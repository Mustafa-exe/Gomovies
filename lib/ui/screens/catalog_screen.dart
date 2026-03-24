import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/media_item.dart';
import '../../state/providers.dart';
import 'detail_screen.dart';
import '../widgets/media_card.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final List<MediaItem> _items = <MediaItem>[];
  int _page = 1;
  bool _loading = false;
  bool _done = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _done = false;
        _items.clear();
        _error = null;
      }
    });

    try {
      final repo = ref.read(repositoryProvider);
      final res = await repo.fetchCatalog(page: _page);
      setState(() {
        _items.addAll(res.items);
        if (_page >= res.totalPages || res.items.isEmpty) {
          _done = true;
        } else {
          _page += 1;
        }
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
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty && _error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load catalog\n$_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _load(reset: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final columns = width > 1100 ? 6 : width > 800 ? 4 : width > 580 ? 3 : 2;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 18),
              SizedBox(width: 8),
              Text('Curated Catalog', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 && !_done) {
                _load();
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _items.length + (_done ? 0 : 1),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
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
          ),
        ),
      ],
    );
  }
}
