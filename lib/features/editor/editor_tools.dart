import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'editor_controller.dart';
import 'palette.dart';

/// Herramientas, grosor y paleta. Horizontal bajo el lienzo en teléfono;
/// vertical en el panel lateral de tableta.
class EditorToolPanel extends StatefulWidget {
  const EditorToolPanel({
    super.key,
    required this.controller,
    required this.vertical,
    this.starterPalette = false,
  });

  final EditorController controller;
  final bool vertical;

  /// Empieza con la paleta corta y un botón «Más colores». Ninguna
  /// herramienta ni color deja de estar disponible.
  final bool starterPalette;

  @override
  State<EditorToolPanel> createState() => _EditorToolPanelState();
}

class _EditorToolPanelState extends State<EditorToolPanel> {
  bool _expanded = false;

  EditorController get controller => widget.controller;
  bool get vertical => widget.vertical;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tools = [
          for (final (tool, label, icon) in [
            (EditorTool.fill, l.toolFill, Icons.format_color_fill_rounded),
            (EditorTool.brush, l.toolBrush, Icons.brush_rounded),
            (EditorTool.eraser, l.toolEraser, null),
          ])
            _ToolButton(
              key: ValueKey('tool-${tool.name}'),
              label: label,
              icon: icon,
              selected: controller.tool == tool,
              horizontalContent: vertical,
              onTap: () => controller.tool = tool,
            ),
        ];
        // El grosor solo aplica a pincel y borrador. Su espacio se reserva
        // siempre para que el lienzo no salte al cambiar de herramienta.
        final sizes = Visibility(
          visible: controller.tool != EditorTool.fill,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _SizeSelector(controller: controller),
        );
        // Un color fuera de la paleta corta (obra retomada) la amplía.
        final short =
            widget.starterPalette &&
            !_expanded &&
            kStarterPalette.any((c) => c.rgb == controller.color);
        final swatches = <Widget>[
          for (final c in short ? kStarterPalette : kPalette)
            _Swatch(
              key: ValueKey('color-${c.rgb.toRadixString(16)}'),
              rgb: c.rgb,
              name: c.name(l),
              selected: controller.color == c.rgb,
              onTap: () => controller.color = c.rgb,
            ),
          if (short)
            _MoreColors(
              label: l.moreColors,
              onTap: () => setState(() => _expanded = true),
            ),
        ];

        if (vertical) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.tools, style: tukiText(18, weight: 700)),
              const SizedBox(height: 8),
              for (final t in tools) ...[t, const SizedBox(height: 8)],
              sizes,
              const SizedBox(height: 8),
              const Divider(color: TukiColors.divider),
              Row(
                children: [
                  Expanded(
                    child: Text(l.colors, style: tukiText(18, weight: 700)),
                  ),
                  Text(
                    paletteName(l, controller.color),
                    style: tukiText(15, color: TukiColors.turquoise),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(spacing: 4, runSpacing: 4, children: swatches),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                for (var i = 0; i < tools.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: tools[i]),
                ],
              ],
            ),
            const SizedBox(height: 4),
            sizes,
            const SizedBox(height: 6),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: swatches,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.horizontalContent,
    required this.onTap,
  });

  final String label;

  /// `null` dibuja el icono propio del borrador.
  final IconData? icon;
  final bool selected;
  final bool horizontalContent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : TukiColors.turquoise;
    final glyph = icon != null
        ? Icon(icon, color: foreground, size: 30)
        : SizedBox(
            width: 30,
            height: 30,
            child: CustomPaint(painter: _EraserIcon(foreground)),
          );
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: tukiText(18, weight: 700, color: foreground),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? TukiColors.turquoise : TukiColors.surface,
        elevation: selected ? 3 : 1,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          // La selección se marca con color, borde e indicador.
          side: BorderSide(
            color: selected ? TukiColors.ink : TukiColors.divider,
            width: selected ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: horizontalContent
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        glyph,
                        const SizedBox(width: 10),
                        Flexible(child: text),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [glyph, text],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EraserIcon extends CustomPainter {
  _EraserIcon(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.6);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.95,
        height: size.height * 0.5,
      ),
      Radius.circular(size.height * 0.12),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..color = color;
    canvas.save();
    canvas.clipRRect(rect);
    canvas.drawRect(
      Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.left + rect.width * 0.4,
        rect.bottom,
      ),
      Paint()..color = color,
    );
    canvas.restore();
    canvas.drawRRect(rect, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EraserIcon old) => old.color != color;
}

class _SizeSelector extends StatelessWidget {
  const _SizeSelector({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            l.strokeSize,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tukiText(16, weight: 600),
          ),
        ),
        const SizedBox(width: 8),
        for (final (size, name, dot) in [
          (StrokeSize.small, l.sizeSmall, 8.0),
          (StrokeSize.medium, l.sizeMedium, 16.0),
          (StrokeSize.large, l.sizeLarge, 26.0),
        ])
          Semantics(
            button: true,
            selected: controller.strokeSize == size,
            label: '${l.strokeSize}: $name',
            excludeSemantics: true,
            child: InkResponse(
              key: ValueKey('size-${size.name}'),
              onTap: () => controller.strokeSize = size,
              radius: 28,
              child: Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: controller.strokeSize == size
                      ? TukiColors.selectedTint
                      : Colors.transparent,
                  border: Border.all(
                    color: controller.strokeSize == size
                        ? TukiColors.turquoise
                        : TukiColors.divider,
                    width: controller.strokeSize == size ? 3 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: const BoxDecoration(
                    color: TukiColors.ink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MoreColors extends StatelessWidget {
  const _MoreColors({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkResponse(
          key: const ValueKey('palette-more'),
          onTap: onTap,
          radius: 28,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TukiColors.surface,
                  border: Border.all(color: TukiColors.turquoise, width: 2),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: TukiColors.turquoise,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.rgb,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final int rgb;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(0xFF000000 | rgb);
    final onColor = color.computeLuminance() > 0.5
        ? TukiColors.ink
        : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: Container(
              width: selected ? 48 : 40,
              height: selected ? 48 : 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                // Selección: anillo oscuro + marca, además del color.
                border: Border.all(
                  color: TukiColors.ink,
                  width: selected ? 4 : 1.5,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: onColor, size: 26)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
