import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// Pregunta del control de adultos: una multiplicación de dos cifras
/// sencillas, fuera del alcance de un niño pequeño.
class AdultChallenge {
  AdultChallenge(Random random)
    : a = 6 + random.nextInt(4),
      b = 6 + random.nextInt(4);

  final int a;
  final int b;
  int get answer => a * b;
}

/// Muestra el control de adultos. Devuelve `true` solo con la respuesta
/// correcta. Toda pantalla comercial, compra o enlace externo debe pasar por
/// aquí antes de abrirse.
Future<bool> showAdultGate(BuildContext context, {Random? random}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _AdultGateDialog(AdultChallenge(random ?? Random())),
  );
  return ok == true;
}

class _AdultGateDialog extends StatefulWidget {
  const _AdultGateDialog(this.challenge);
  final AdultChallenge challenge;

  @override
  State<_AdultGateDialog> createState() => _AdultGateDialogState();
}

class _AdultGateDialogState extends State<_AdultGateDialog> {
  final _input = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    if (int.tryParse(_input.text.trim()) == widget.challenge.answer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrong = true);
      _input.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.challenge;
    return AlertDialog(
      title: Text(l.adultGateTitle, style: tukiText(22, weight: 700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.adultGateQuestion(c.a, c.b), style: tukiText(18)),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('adult-gate-input'),
              controller: _input,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              style: tukiText(22, weight: 600),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l.adultGateAnswer,
                errorText: _wrong ? l.adultGateWrong : null,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('adult-gate-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel, style: tukiText(17, weight: 600)),
        ),
        FilledButton(
          key: const ValueKey('adult-gate-ok'),
          onPressed: _submit,
          child: Text(
            l.continueLabel,
            style: tukiText(17, weight: 600, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
