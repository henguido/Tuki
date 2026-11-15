import 'package:flutter/services.dart';

const privacyPolicyUrl = 'https://tuki.artwebcr.com/privacy';

/// Opens only TUKI's public privacy policy in the system browser.
///
/// Android validates the HTTPS host again before creating the browser intent.
class PrivacyService {
  const PrivacyService();

  static const _channel = MethodChannel(
    'dev.tukiapp.tuki_little_adventures/external_url',
  );

  Future<bool> openPolicy() async {
    try {
      return await _channel.invokeMethod<bool>('open', {
            'url': privacyPolicyUrl,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
