import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/backlog_item.dart';
import '../models/game.dart';
import '../services/api_service.dart';
import '../state/backlog_store.dart';
import '../theme.dart';
import '../widgets/game_image.dart';
import '../widgets/rating_stars.dart';
import '../widgets/toast.dart';

const _requirementLabels = <String, String>{
  'os': 'Sistem operasi',
  'processor': 'Prosesor',
  'memory': 'Memori',
  'graphics': 'Grafis',
  'storage': 'Penyimpanan',
};

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _formatDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// Halaman 2: detail game dari endpoint /game?id=... plus panel backlog.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.game});

  final Game game;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _api = FreeToGameApi();

  GameDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final detail = await _api.fetchGameDetail(widget.game.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan saat membaca detail game.';
        _loading = false;
      });
    }
  }

  Future<void> _openSite() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(widget.game.gameUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      showToast(context, 'Tautan game tidak bisa dibuka.');
    }
  }

  void _showScreenshot(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final detail = _detail;
    final releaseDate = (detail?.releaseDate.isNotEmpty ?? false)
        ? detail!.releaseDate
        : game.releaseDate;
    final publisher = (detail?.publisher.isNotEmpty ?? false) ? detail!.publisher : game.publisher;
    final developer = (detail?.developer.isNotEmpty ?? false) ? detail!.developer : game.developer;
    final description = (detail != null && detail.description.trim().isNotEmpty)
        ? detail.description.trim()
        : game.shortDescription;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: AppColors.bg,
            foregroundColor: AppColors.text,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  GameImage(url: game.thumbnail, label: game.title),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66000000), Color(0x00000000), AppColors.bg],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  game.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(Icons.category_outlined, game.genre),
                    _MetaChip(game.platformIcon, game.platformShort),
                    if (releaseDate.isNotEmpty)
                      _MetaChip(Icons.event_outlined, _formatDate(releaseDate)),
                  ],
                ),
                const SizedBox(height: 16),
                _BacklogPanel(game: game),
                const _SectionTitle('Tentang game'),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textDim, height: 1.5),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                if (_error != null)
                  _InlineError(message: _error!, onRetry: _retry),
                if (detail != null && detail.screenshots.isNotEmpty) ...[
                  const _SectionTitle('Screenshot'),
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.screenshots.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final url = detail.screenshots[i];
                        return GestureDetector(
                          onTap: () => _showScreenshot(url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: GameImage(url: url),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (detail != null && detail.requirements.isNotEmpty) ...[
                  const _SectionTitle('Spesifikasi minimum'),
                  _InfoCard(
                    children: [
                      for (final entry in _requirementLabels.entries)
                        if (detail.requirements.containsKey(entry.key))
                          _InfoRow(entry.value, detail.requirements[entry.key]!),
                    ],
                  ),
                ],
                const _SectionTitle('Informasi'),
                _InfoCard(
                  children: [
                    if (publisher.isNotEmpty) _InfoRow('Publisher', publisher),
                    if (developer.isNotEmpty) _InfoRow('Developer', developer),
                    _InfoRow('Platform', game.platform),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openSite,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Buka halaman game'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.outline),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel untuk menambah game ke backlog, lalu mengatur status, rating, dan catatan.
class _BacklogPanel extends StatefulWidget {
  const _BacklogPanel({required this.game});

  final Game game;

  @override
  State<_BacklogPanel> createState() => _BacklogPanelState();
}

class _BacklogPanelState extends State<_BacklogPanel> {
  final _store = BacklogStore.instance;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: _store.find(widget.game.id)?.note ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    await _store.add(widget.game);
    if (!mounted) return;
    showToast(context, 'Game masuk ke backlog');
  }

  void _saveNote(BacklogItem item) {
    FocusScope.of(context).unfocus();
    _store.save(item.copyWith(note: _noteCtrl.text.trim()));
    showToast(context, 'Catatan disimpan');
  }

  void _remove(BacklogItem item) {
    _store.remove(item.gameId);
    _noteCtrl.clear();
    showToast(
      context,
      'Game dihapus dari backlog',
      actionLabel: 'Batal',
      onAction: () {
        _store.save(item);
        _noteCtrl.text = item.note;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final item = _store.find(widget.game.id);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          child: item == null ? _buildAdd() : _buildEdit(item),
        );
      },
    );
  }

  Widget _buildAdd() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Belum ada di backlog',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Simpan game ini, lalu atur status, rating, dan catatanmu.',
          style: TextStyle(color: AppColors.textDim, height: 1.4),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah ke backlog'),
          ),
        ),
      ],
    );
  }

  Widget _buildEdit(BacklogItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bookmark_rounded, size: 18, color: AppColors.accent),
            SizedBox(width: 6),
            Text('Ada di backlogmu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<BacklogStatus>(
            showSelectedIcon: false,
            style: segmentedStyle(),
            segments: [
              for (final s in BacklogStatus.values)
                ButtonSegment(
                  value: s,
                  label: Text(s.label),
                  icon: Icon(s.icon, size: 18),
                ),
            ],
            selected: {item.status},
            onSelectionChanged: (selection) =>
                _store.save(item.copyWith(status: selection.first)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text('Rating', style: TextStyle(color: AppColors.textDim)),
            const Spacer(),
            RatingStars(
              rating: item.rating,
              size: 30,
              onChanged: (r) => _store.save(item.copyWith(rating: r)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteCtrl,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: fieldDecoration(
            hint: 'Catatan pribadi, misalnya mau main bareng teman',
          ).copyWith(fillColor: AppColors.surfaceHigh),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _remove(item),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Hapus'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: () => _saveNote(item),
              child: const Text('Simpan catatan'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textDim),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textDim)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13, height: 1.3))),
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
