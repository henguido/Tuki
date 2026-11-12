import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../chapters/catalog.dart';
import 'adult_gate.dart';
import 'entitlements.dart';

/// Abre «Aventuras» solo tras superar el control de adultos. Es la única
/// entrada a la pantalla comercial.
Future<void> openAdventures(BuildContext context) async {
  final nav = Navigator.of(context);
  if (!await showAdultGate(context)) return;
  await nav.push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'adventures'),
      builder: (_) => const AdventuresScreen(),
    ),
  );
}

/// Capítulos del catálogo y su estado de acceso. Refleja el estado real: sin
/// tienda configurada no ofrece compras ni precios.
class AdventuresScreen extends StatefulWidget {
  const AdventuresScreen({super.key});

  @override
  State<AdventuresScreen> createState() => _AdventuresScreenState();
}

class _AdventuresScreenState extends State<AdventuresScreen> {
  String? _message;

  Future<void> _buy(String productId) async {
    final l = AppLocalizations.of(context);
    final result = await AppScope.of(context).entitlements.buy(productId);
    if (!mounted) return;
    setState(() {
      _message = switch (result) {
        PurchaseResult.purchased => l.purchaseDone,
        PurchaseResult.canceled => l.purchaseCanceled,
        PurchaseResult.unavailable => l.storeUnavailable,
        PurchaseResult.failed => l.purchaseFailed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final deps = AppScope.of(context);
    final lang = contentLanguage(context);
    final entitlements = deps.entitlements;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListenableBuilder(
              listenable: entitlements,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TukiBackHeader(backLabel: l.back, caption: l.adultsTitle),
                  const SizedBox(height: 14),
                  Semantics(
                    header: true,
                    child: Text(l.adventures, style: tukiText(30, weight: 700)),
                  ),
                  const SizedBox(height: 6),
                  Text(l.noAds, style: tukiText(16)),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _message!,
                        key: const ValueKey('store-message'),
                        style: tukiText(
                          17,
                          weight: 600,
                          color: TukiColors.turquoise,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  for (final chapter in deps.catalog.chapters) ...[
                    _ChapterRow(
                      chapter: chapter,
                      title: chapter.title.of(lang),
                      unlocked: entitlements.isUnlocked(chapter),
                      storeAvailable: entitlements.storeAvailable,
                      bundles: [
                        for (final b in entitlements.bundlesFor(chapter))
                          (
                            b.productId,
                            [
                              for (final id in b.chapterIds)
                                deps.catalog.chapterById(id)!.title.of(lang),
                            ].join(', '),
                          ),
                      ],
                      onBuy: _buy,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.title,
    required this.unlocked,
    required this.storeAvailable,
    required this.bundles,
    required this.onBuy,
  });

  final Chapter chapter;
  final String title;
  final bool unlocked;
  final bool storeAvailable;

  /// (producto, capítulos incluidos) de cada paquete que contiene el capítulo.
  final List<(String, String)> bundles;
  final ValueChanged<String> onBuy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = chapter.pages.length + chapter.plannedPages.length;
    final status = chapter.access.isFree
        ? l.chapterFree
        : unlocked
        ? l.chapterOwned
        : l.chapterLocked;
    return TukiCard(
      key: ValueKey('adventure-${chapter.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: tukiText(22, weight: 700)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                size: 20,
                color: TukiColors.turquoise,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status,
                  key: ValueKey('adventure-status-${chapter.id}'),
                  style: tukiText(17, weight: 600, color: TukiColors.turquoise),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l.pagesAvailable(chapter.pages.length, total),
            style: tukiText(16),
          ),
          if (!unlocked) ...[
            const SizedBox(height: 8),
            if (!storeAvailable)
              Text(l.storeUnavailable, style: tukiText(16))
            else ...[
              TukiPrimaryButton(
                key: ValueKey('buy-${chapter.access.productId}'),
                compact: true,
                label: l.buy,
                onPressed: () => onBuy(chapter.access.productId!),
              ),
              for (final (product, included) in bundles) ...[
                const SizedBox(height: 8),
                Text(l.bundleIncludes(included), style: tukiText(15)),
                const SizedBox(height: 4),
                OutlinedButton(
                  key: ValueKey('buy-$product'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                    foregroundColor: TukiColors.turquoise,
                  ),
                  onPressed: () => onBuy(product),
                  child: Text(
                    l.buy,
                    style: tukiText(
                      18,
                      weight: 700,
                      color: TukiColors.turquoise,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
