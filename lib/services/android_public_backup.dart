import 'dart:io';

import 'package:flutter/services.dart';

class AndroidPublicBackup {
  static const _channel = MethodChannel('com.HongNamgyeong.legioActivityApp/backup');

  static Future<bool> write(String content) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'writePublicBackup',
        {'content': content},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<String?> read() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('readPublicBackup');
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> exists() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('publicBackupExists');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
