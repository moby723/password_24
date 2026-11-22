import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceCheck {
  /// 데스크톱(PC) 또는 웹 환경인지 확인 (QR 스캔 불가 환경)
  static bool get isDesktopOrWeb {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// 모바일(안드로이드, iOS) 환경인지 확인 (QR 스캔, 생체 인증 특화 환경)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 생체 인증을 지원하지 않는 환경인지 확인 (local_auth 패키지 기준)
  static bool get isBiometricsUnsupported {
    if (kIsWeb) return true;
    if (Platform.isLinux) return true;
    return false;
  }
}