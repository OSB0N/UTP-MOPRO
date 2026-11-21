import 'package:flutter/material.dart';

import '../models/game.dart';
import '../services/api_service.dart';
import '../state/backlog_store.dart';
import '../theme.dart';
import '../widgets/app_chip.dart';
import '../widgets/game_card.dart';
import '../widgets/state_views.dart';
import '../widgets/toast.dart';
import 'detail_screen.dart';

const _categories = <(String, String?)>[
  ('Semua', null),
  ('MMORPG', 'mmorpg'),
  ('Shooter', 'shooter'),
  ('Strategi', 'strategy'),
  ('MOBA', 'moba'),
  ('Battle Royale', 'battle-royale'),
  ('Racing', 'racing'),
  ('Olahraga', 'sports'),
  ('Sandbox', 'sandbox'),
  ('Survival', 'survival'),
  ('Kartu', 'card'),
  ('Fantasi', 'fantasy'),
  ('Anime', 'anime'),
  ('Fighting', 'fighting'),
  ('Horor', 'horror'),
];

/// Halaman 1: katalog game gratis dari FreeToGame API.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _api = FreeToGameApi();
  final _store = BacklogStore.instance;
  final _searchCtrl = TextEditingController();

  String _platform = 'all';
  String? _category;
  String _query = '';

  bool _loading = true;
  String? _error;
  List<Game> _games = const [];
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Ambil ulang data dengan indikator loading penuh (ganti filter, coba lagi).
  void _reload() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _fetch();
  }

  /// Ambil data dari API. Jika [silent], daftar lama tetap tampil (pull to refresh).
  Future<void> _fetch({bool silent = false}) async {
    final id = ++_requestId;
    try {
      final games = await _api.fetchGames(
        platform: _platform,
        category: _category,
        limit: FreeToGameApi.popularLimit,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _games = games;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      if (silent && _games.isNotEmpty) {
        showToast(context, e.message);
      } else {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = 'Terjadi kesalahan saat membaca data game.';
        _loading = false;
      });
    }
  }

  List<Game> get _visibleGames {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _games;
    return _games.where((g) => g.title.toLowerCase().contains(q)).toList();
  }

  void _openDetail(Game game) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(game: game)),
    );
  }

  Future<void> _quickAdd(Game game) async {
    await _store.add(game);
    if (!mounted) return;
    showToast(
      context,
      '${game.title} masuk ke backlog',
      actionLabel: 'Batal',
      onAction: () => _store.remove(game.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleGames;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surfaceHigh,
        onRefresh: () => _fetch(silent: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(visible.length)),
            ..._buildBody(visible),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int shown) {
    final subtitle = _loading
        ? 'Memuat daftar game...'
        : _error != null
            ? 'Daftar game belum tersedia'
            : '$shown game paling banyak diminati';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game gratis terpopuler',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppColors.textDim)),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: fieldDecoration(
              hint: 'Cari judul game',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              style: segmentedStyle(),
              segments: const [
                ButtonSegment(value: 'all', label: Text('Semua')),
                ButtonSegment(
                  value: 'pc',
                  label: Text('PC'),
                  icon: Icon(Icons.computer_rounded, size: 18),
                ),
                ButtonSegment(
                  value: 'browser',
                  label: Text('Browser'),
                  icon: Icon(Icons.public_rounded, size: 18),
                ),
              ],
              selected: {_platform},
              onSelectionChanged: (selection) {
                setState(() => _platform = selection.first);
                _reload();
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (label, value) = _categories[i];
                return AppChip(
                  label: label,
                  selected: _category == value,
                  onTap: () {
                    setState(() => _category = value);
                    _reload();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  List<Widget> _buildBody(List<Game> visible) {
    if (_loading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList.separated(
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, __) => const _SkeletonCard(),
          ),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(message: _error!, onRetry: _reload),
        ),
      ];
    }

    if (visible.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.search_off_rounded,
            title: 'Game tidak ditemukan',
            message: _query.trim().isEmpty
                ? 'Belum ada game untuk filter ini. Coba ganti genre atau platform.'
                : 'Tidak ada judul yang cocok dengan "$_query".',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        sliver: SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final game = visible[i];
            return ListenableBuilder(
              listenable: _store,
              builder: (context, _) => GameCard(
                game: game,
                rank: _games.indexOf(game) + 1,
                backlogItem: _store.find(game.id),
                onTap: () => _openDetail(game),
                onAdd: () => _quickAdd(game),
              ),
            );
          },
        ),
      ),
    ];
  }
}

/// Kerangka kartu yang tampil saat data sedang dimuat.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  Widget _bar(double width) => Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(color: AppColors.surfaceHigh),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(160),
                const SizedBox(height: 10),
                _bar(90),
                const SizedBox(height: 12),
                _bar(240),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
