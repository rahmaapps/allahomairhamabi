import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'dua_repository.dart';
import 'models/dua.dart';
import 'user_prefs.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repo = DuaRepository();
  final _controller = TextEditingController();

  List<Dua> _all = [];
  List<Dua> _results = [];
  Timer? _debounce;
  Set<int> _favoriteIds = {}; // cache local des favoris

  @override
  void initState() {
    super.initState();
    _initData();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final all = await _repo.getAllDuas();                        // List<Dua>
    final favIds = await UserPrefs.instance.getFavoriteIds();    // List<int>
    setState(() {
      _all = all;
      _results = all;             // Par défaut on montre tout
      _favoriteIds = favIds.toSet();
    });
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      final q = _controller.text.trim();
      if (q.isEmpty) {
        setState(() => _results = _all);
        return;
      }
      final res = _all.where((d) => _containsArabic(d.text, q)).toList();
      setState(() => _results = res);
    });
  }

  bool _containsArabic(String haystack, String needle) {
    // Recherche simple “contains” (insensible à la casse basique)
    return haystack.contains(needle);
  }

  Future<void> _toggleFavorite(Dua d) async {
    await UserPrefs.instance.toggleFavorite(d.id);
    HapticFeedback.lightImpact();
    setState(() {
      if (_favoriteIds.contains(d.id)) {
        _favoriteIds.remove(d.id);
      } else {
        _favoriteIds.add(d.id);
      }
    });
  }

  Future<void> _copyText(Dua d) async {
    await Clipboard.setData(ClipboardData(text: d.text));
    HapticFeedback.selectionClick();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ الدعاء')),
      );
    }
  }

  Future<void> _shareText(Dua d) async {
    await Share.share(d.text, subject: 'دعاء');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث'),
      ),
      body: Column(
        children: [
          // Champ de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'ابحث عن دعاء...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: (_controller.text.isEmpty)
                    ? null
                    : IconButton(
                  tooltip: 'مسح',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ),
          ),

          // Résultats
          Expanded(
            child: _results.isEmpty
                ? const _EmptyResults()
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = _results[index];
                final isFav = _favoriteIds.contains(d.id);
                return _SearchResultCard(
                  dua: d,
                  isFavorite: isFav,
                  onToggleFavorite: () => _toggleFavorite(d),
                  onCopy: () => _copyText(d),
                  onShare: () => _shareText(d),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Dua dua;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _SearchResultCard({
    required this.dua,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onCopy,
    required this.onShare,
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

            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                dua.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lateef',
                  fontSize: 24,
                  height: 1.6,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  tooltip: 'مفضلة',
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_outline,
                    color: isFavorite ? Colors.red : theme.colorScheme.onSurface,
                  ),
                  onPressed: onToggleFavorite,
                ),
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

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('لا توجد نتائج'),
      ),
    );
  }
}