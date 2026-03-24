import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/media_item.dart';
import '../../state/providers.dart';
import 'player_screen.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  String _preferredQuality = '720p';

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(detailsProvider(widget.itemId));

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (item) => _Body(
          item: item,
          preferredQuality: _preferredQuality,
          onQualityChanged: (v) => setState(() => _preferredQuality = v),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.item,
    required this.preferredQuality,
    required this.onQualityChanged,
  });

  final MediaItem item;
  final String preferredQuality;
  final ValueChanged<String> onQualityChanged;

  Future<void> _play(BuildContext context, String title, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid playback URL')),
      );
      return;
    }

    if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open external player')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(title: title, source: url),
      ),
    );
  }

  Future<void> _openWhereToWatch(BuildContext context, String title) async {
    final justWatch = Uri.https('www.justwatch.com', '/us/search', {'q': title});
    final opened = await launchUrl(justWatch, mode: LaunchMode.externalApplication);
    if (opened) return;

    final google = Uri.https('www.google.com', '/search', {'q': '$title where to watch'});
    final googleOpened = await launchUrl(google, mode: LaunchMode.externalApplication);
    if (!googleOpened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open watch providers.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variants = item.variants;
    final qualityOptions = variants.map((v) => v.qualityLabel).toSet().toList();
    final selectedQuality = qualityOptions.contains(preferredQuality)
        ? preferredQuality
        : (qualityOptions.isNotEmpty ? qualityOptions.first : null);

    final defaultVariant = variants.isNotEmpty
        ? variants.firstWhere(
            (v) => v.qualityLabel == preferredQuality,
            orElse: () => variants.first,
          )
        : null;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (item.backdropUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.backdropUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 12),
        Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('${item.mediaType.name.toUpperCase()} • ${item.releaseYear} • ${item.source}'),
        const SizedBox(height: 12),
        Text(item.overview),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (defaultVariant != null)
              FilledButton.icon(
                onPressed: () => _play(context, item.title, defaultVariant.url),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Stream'),
              ),
            if (defaultVariant != null)
              FilledButton.tonalIcon(
                onPressed: () async {
                  try {
                    await ref.read(downloadManagerProvider).queueMovie(
                          item: item,
                          variant: defaultVariant,
                        );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Download unavailable: $e')),
                    );
                    return;
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Movie queued for download')),
                    );
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Download Movie'),
              ),
            if (defaultVariant == null)
              FilledButton.tonalIcon(
                onPressed: () => _openWhereToWatch(context, item.title),
                icon: const Icon(Icons.travel_explore),
                label: const Text('Where To Watch'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (qualityOptions.isNotEmpty)
          Row(
            children: [
              const Text('Quality'),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedQuality,
                items: qualityOptions.map((quality) {
                  final sample = variants.firstWhere(
                    (v) => v.qualityLabel == quality,
                    orElse: () => variants.first,
                  );
                  return DropdownMenuItem<String>(
                    value: quality,
                    child: Text('$quality (${sample.bitrate} kbps)'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onQualityChanged(v);
                },
              ),
            ],
          ),
        const SizedBox(height: 12),
        if (item.seasons.isNotEmpty) ...[
          const Text('Seasons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...item.seasons.map((season) {
            final seasonHasPlayable =
                season.episodes.any((ep) => ep.variants.isNotEmpty) || item.variants.isNotEmpty;

            return ExpansionTile(
              title: Text('Season ${season.number}'),
              subtitle: Text('${season.episodes.length} episodes'),
              trailing: FilledButton.tonal(
                onPressed: season.episodes.isEmpty || !seasonHasPlayable
                    ? null
                    : () async {
                        List<String> ids;
                        try {
                          ids = await ref.read(downloadManagerProvider).queueSeason(
                                item: item,
                                season: season,
                                qualityLabel: preferredQuality,
                                fallbackVariants: item.variants,
                              );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Download unavailable: $e')),
                          );
                          return;
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ids.isEmpty
                                    ? 'No downloadable episode variants available.'
                                    : 'Season ${season.number} queued (${ids.length})',
                              ),
                            ),
                          );
                        }
                      },
                child: const Text('Download Season'),
              ),
              children: season.episodes.map((ep) {
                final candidates = ep.variants.isNotEmpty ? ep.variants : item.variants;
                final variant = candidates.isEmpty
                    ? null
                    : candidates.firstWhere(
                        (v) => v.qualityLabel == preferredQuality,
                        orElse: () => candidates.first,
                      );

                return ListTile(
                  title: Text('E${ep.number.toString().padLeft(2, '0')} • ${ep.title}'),
                  subtitle: Text(
                    variant == null
                        ? '${(ep.durationSec / 60).round()} min • No stream variants'
                        : '${(ep.durationSec / 60).round()} min • ${variant.qualityLabel}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: variant == null
                            ? null
                            : () => _play(context, '${item.title} - ${ep.title}', variant.url),
                        icon: const Icon(Icons.play_arrow),
                      ),
                      IconButton(
                        onPressed: variant == null
                            ? null
                            : () async {
                                try {
                                  await ref.read(downloadManagerProvider).queueEpisode(
                                        item: item,
                                        seasonNumber: season.number,
                                        episode: ep,
                                        variant: variant,
                                      );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Download unavailable: $e')),
                                  );
                                  return;
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Queued ${ep.title}')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.download),
                      ),
                      IconButton(
                        onPressed: () => _openWhereToWatch(context, '${item.title} ${ep.title}'),
                        icon: const Icon(Icons.travel_explore),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ],
    );
  }
}
