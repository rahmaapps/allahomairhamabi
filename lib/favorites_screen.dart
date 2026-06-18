import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard, Haptics
import 'package:share_plus/share_plus.dart';

import 'dua_repository.dart';
import 'models/dua.dart';
import 'user_prefs.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _repo = DuaRepository();

  late Future<List<Dua>> _futureFavs;
  List<Dua> _favs = [];

  // --- Signature ajoutée lors du copier/partager ---
  static const String _ATTR_SUFFIX_AR = '\n\n— من تطبيق اللَّهُمَّ ارْحَمْ أَبِي —';

  @override
  void initState() {
    super.initState();
    _futureFavs = _loadFavorites();
  }

  Future<List<Dua>> _loadFavorites() async {
    final ids = await UserPrefs.instance.getFavoriteIds();
    final all = await _repo.getAllDuas();

    final List<Dua> result = [];

    for (var d in all) {
      if (ids.contains(d.id)) {
        final savedText = await UserPrefs.getFavoriteText(d.id);

        if (savedText != null && savedText.isNotEmpty) {
          // ✅ utiliser texte personnalisé
          result.add(
            Dua(
              id: d.id,
              category: d.category,
              length: d.length,
              text: savedText,
            ),
          );
        } else {
          // ✅ fallback ancien comportement
          result.add(d);
        }
      }
    }

    _favs = result;
    return result;
  }

  Future<void> _refresh() async {
    final newList = await _loadFavorites();
    setState(() {
      _futureFavs = Future.value(newList);
    });
  }

  Future<void> _removeFromFavorites(Dua d) async {
    await UserPrefs.instance.toggleFavorite(d.id);
    HapticFeedback.lightImpact();
    setState(() {
      _favs.removeWhere((e) => e.id == d.id);
      _futureFavs = Future.value(List<Dua>.from(_favs));
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إزالة الدعاء من المفضلة')),
      );
    }
  }

  Future<void> _copyText(Dua d) async {
    final textToCopy = '${d.text}$_ATTR_SUFFIX_AR';

    await Clipboard.setData(ClipboardData(text: textToCopy));
    HapticFeedback.selectionClick();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ الدعاء')),
      );
    }
  }


  Future<void> _shareText(Dua d) async {
    final textToShare = '${d.text}$_ATTR_SUFFIX_AR';
    await Share.share(textToShare, subject: 'دعاء');
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Dua>>(
        future: _futureFavs,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final favs = snap.data ?? const <Dua>[];
          if (favs.isEmpty) {
            return _EmptyState(onBackHome: () => Navigator.pop(context));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = favs[index];
                return _DuaCard(
                  dua: d,
                  onCopy: () => _copyText(d),
                  onShare: () => _shareText(d),
                  onRemove: () => _removeFromFavorites(d),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final Dua dua;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onRemove;

  const _DuaCard({
    required this.dua,
    required this.onCopy,
    required this.onShare,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0,6))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meta (category + length)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _Chip(text: _categoryLabel(dua.category)),
                _Chip(text: _lengthLabel(dua.length)),
              ],
            ),
            const SizedBox(height: 8),

            // Texte
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                dua.text,
                textAlign: TextAlign.center,

                // ✅ AJOUT ICI
                maxLines: 6,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontFamily: 'Lateef',
                  fontSize: 26,
                  height: 1.6,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  tooltip: 'نسخ',
                  icon: const Icon(Icons.copy),
                  onPressed: onCopy,
                ),
                IconButton(
                  tooltip: 'مشاركة',
                  icon: const Icon(Icons.share),
                  onPressed: onShare,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('حذف من المفضلة', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String c) {
    switch (c.trim().toLowerCase()) {
      case 'friday':
        return 'الجمعة';
      case 'ramadan':
        return 'رمضان';
      default:
        return 'عام';
    }
  }

  String _lengthLabel(String l) {
    // Ton JSON : "قصيرة" | "طويلة"
    if (l.trim() == 'طويلة') return 'طويلة';
    return 'قصيرة';
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? Colors.white10
        : Colors.black12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.8),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBackHome;
  const _EmptyState({required this.onBackHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 64),
            const SizedBox(height: 16),
            const Text('لا توجد أدعية مفضلة بعد'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onBackHome,
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }
}