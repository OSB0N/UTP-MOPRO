import 'package:flutter/material.dart';

import '../models/backlog_item.dart';
import '../state/backlog_store.dart';
import '../theme.dart';
import '../widgets/app_chip.dart';
import '../widgets/game_image.dart';
import '../widgets/rating_stars.dart';
import '../widgets/state_views.dart';
import '../widgets/status_pill.dart';
import '../widgets/toast.dart';
import 'detail_screen.dart';

/// Halaman 3: backlog pribadi yang dibaca dari penyimpanan lokal.
class BacklogScreen extends StatefulWidget {
  const BacklogScreen({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen> {
  final _store = BacklogStore.instance;
  BacklogStatus? _filter; // null = semua

  void _openDetail(BacklogItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(game: item.toGame())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            scrolledUnderElevation: 0,
            title: const Text(
              'Backlog saya',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (!_store.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final all = _store.items;
    if (all.isEmpty) {
      return EmptyView(
        icon: Icons.videogame_asset_outlined,
        title: 'Backlog masih kosong',
        message: 'Cari game di Katalog, lalu tambahkan ke sini.',
        actionLabel: 'Jelajahi katalog',
        onAction: widget.onExplore,
      );
    }

    final shown = _filter == null
        ? all
        : all.where((i) => i.status == _filter).toList();

    return Column(
      children: [
        _StatsCard(store: _store),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              AppChip(
                label: 'Semua ${all.length}',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              for (final s in BacklogStatus.values) ...[
                const SizedBox(width: 8),
                AppChip(
                  label: '${s.label} ${_store.count(s)}',
                  selected: _filter == s,
                  color: s.color,
                  onTap: () => setState(() => _filter = s),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: shown.isEmpty
              ? EmptyView(
                  icon: _filter!.icon,
                  title: 'Belum ada game berstatus ${_filter!.label}',
                  message: 'Ubah status game lewat menu titik tiga di kartu, atau di halaman detail.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = shown[i];
                    return Dismissible(
                      key: ValueKey(item.gameId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withAlpha(50),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                      ),
                      onDismissed: (_) {
                        _store.remove(item.gameId);
                        showToast(
                          context,
                          '${item.title} dihapus dari backlog',
                          actionLabel: 'Batal',
                          onAction: () => _store.save(item),
                        );
                      },
                      child: _BacklogTile(
                        item: item,
                        onTap: () => _openDetail(item),
                        onStatusChanged: (s) => _store.save(item.copyWith(status: s)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Ringkasan: jumlah game dan proporsi status dalam satu bar.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.store});

  final BacklogStore store;

  @override
  Widget build(BuildContext context) {
    final total = store.items.length;
    final done = store.count(BacklogStatus.tamat);
    final int percent = total == 0 ? 0 : (done * 100 / total).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$total game', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('$percent% tamat', style: const TextStyle(color: AppColors.textDim)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (final s in BacklogStatus.values)
                    if (store.count(s) > 0)
                      Expanded(
                        flex: store.count(s),
                        child: ColoredBox(color: s.color),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final s in BacklogStatus.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.label} ${store.count(s)}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textDim),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BacklogTile extends StatelessWidget {
  const _BacklogTile({
    required this.item,
    required this.onTap,
    required this.onStatusChanged,
  });

  final BacklogItem item;
  final VoidCallback onTap;
  final ValueChanged<BacklogStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 112,
                  height: 80,
                  child: GameImage(url: item.thumbnail, label: item.title),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusPill(status: item.status),
                        if (item.rating > 0) ...[
                          const SizedBox(width: 8),
                          RatingStars(rating: item.rating, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.note.isNotEmpty ? item.note : item.genre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: AppColors.textDim,
                        fontStyle: item.note.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<BacklogStatus>(
                tooltip: 'Ubah status',
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textDim),
                color: AppColors.surfaceHigh,
                onSelected: onStatusChanged,
                itemBuilder: (_) => [
                  for (final s in BacklogStatus.values)
                    PopupMenuItem<BacklogStatus>(
                      value: s,
                      enabled: s != item.status,
                      child: Row(
                        children: [
                          Icon(s.icon, color: s.color, size: 18),
                          const SizedBox(width: 10),
                          Text('Pindah ke ${s.label}'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
