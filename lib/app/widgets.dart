import 'package:flutter/material.dart';

import 'theme.dart';

/// Botón redondo blanco con icono (Volver, Deshacer, Ajustes). 52 × 52 dp.
class TukiRoundButton extends StatelessWidget {
  const TukiRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;

  /// Etiqueta para lector de pantalla y tooltip.
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: TukiColors.surface,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black26,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                icon,
                size: 30,
                color: enabled
                    ? TukiColors.turquoise
                    : TukiColors.turquoise.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Acción principal: naranja, texto grande y en negrita (contraste AA para
/// texto grande sobre #E64E24).
class TukiPrimaryButton extends StatelessWidget {
  const TukiPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: TukiColors.orange,
        foregroundColor: Colors.white,
        disabledBackgroundColor: TukiColors.orange.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white,
        minimumSize: Size(64, compact ? 52 : 60),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 26,
          vertical: 10,
        ),
        shape: const StadiumBorder(),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 24 : 28),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: tukiText(
                compact ? 20 : 24,
                weight: 700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título sobre fondo turquesa redondeado.
class TukiTitleBadge extends StatelessWidget {
  const TukiTitleBadge(this.text, {super.key, this.size = 26});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: TukiColors.turquoise,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tukiText(size, weight: 700, color: Colors.white, height: 1.1),
        ),
      ),
    );
  }
}

/// Tarjeta blanca redondeada.
class TukiCard extends StatelessWidget {
  const TukiCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TukiColors.surface,
      elevation: 1.5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? TukiColors.turquoise : TukiColors.divider,
          width: selected ? 3 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Cabecera de pantalla secundaria: Volver + texto.
class TukiBackHeader extends StatelessWidget {
  const TukiBackHeader({super.key, required this.backLabel, this.caption});

  final String backLabel;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TukiRoundButton(
          icon: Icons.arrow_back_rounded,
          label: backLabel,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        if (caption != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tukiText(18, weight: 600),
            ),
          ),
        ],
      ],
    );
  }
}
