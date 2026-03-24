import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/download_task.dart';
import '../../state/providers.dart';
import 'player_screen.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(downloadTasksProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load downloads: $e')),
      data: (tasks) {
        if (kIsWeb) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Web mode supports streaming and search. Offline downloads are available on mobile/desktop builds.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (tasks.isEmpty) {
          return const Center(child: Text('No downloads yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.itemTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(task.label),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: task.progress),
                    const SizedBox(height: 6),
                    Text(_meta(task)),
                    if (task.error != null) ...[
                      const SizedBox(height: 4),
                      Text(task.error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (task.status == DownloadStatus.downloading)
                          OutlinedButton(
                            onPressed: () => ref.read(downloadManagerProvider).pause(task.id),
                            child: const Text('Pause'),
                          ),
                        if (task.status == DownloadStatus.paused ||
                            task.status == DownloadStatus.failed)
                          FilledButton.tonal(
                            onPressed: () => ref.read(downloadManagerProvider).resume(task.id),
                            child: const Text('Resume'),
                          ),
                        if (task.status != DownloadStatus.completed &&
                            task.status != DownloadStatus.canceled)
                          OutlinedButton(
                            onPressed: () => ref.read(downloadManagerProvider).cancel(task.id),
                            child: const Text('Cancel'),
                          ),
                        if (task.status == DownloadStatus.completed)
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PlayerScreen(
                                    title: task.label,
                                    source: task.finalPath,
                                    isLocal: true,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play Offline'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _meta(DownloadTask task) {
    final pct = (task.progress * 100).toStringAsFixed(1);
    final received = (task.receivedBytes / (1024 * 1024)).toStringAsFixed(2);
    final total = task.totalBytes <= 0
        ? '?'
        : (task.totalBytes / (1024 * 1024)).toStringAsFixed(2);
    return '${task.status.name} • $pct% • $received/$total MB';
  }
}
