import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class AndroidPublicBackup {
  static const _channel =
      MethodChannel('com.HongNamgyeong.legioActivityApp/backup');

  /// 다운로드 백업 읽기 권한. [context]가 있으면 거부 시 설정 안내.
  static Future<bool> ensureAccess({BuildContext? context}) async {
    if (!Platform.isAndroid) return true;

    if (await exists()) {
      return true;
    }

    final granted = await _requestStoragePermissions();
    if (granted && await exists()) {
      return true;
    }

    if (context != null && context.mounted) {
      await _showPermissionSettingsDialog(context);
    }
    return false;
  }

  static Future<bool> _requestStoragePermissions() async {
    // Android 13+: storage → 미디어 권한, 이후 all files로 Downloads 접근
    var storageStatus = await ph.Permission.storage.status;
    if (!storageStatus.isGranted) {
      storageStatus = await ph.Permission.storage.request();
    }
    if (storageStatus.isGranted) {
      return true;
    }

    var allFilesStatus = await ph.Permission.manageExternalStorage.status;
    if (!allFilesStatus.isGranted) {
      allFilesStatus = await ph.Permission.manageExternalStorage.request();
    }
    return allFilesStatus.isGranted;
  }

  static Future<void> _showPermissionSettingsDialog(BuildContext context) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('저장소 접근 권한'),
        content: const Text(
          '다운로드 폴더의 백업을 읽으려면 권한이 필요합니다.\n\n'
          '「설정 열기」 → 권한에서 아래 항목을 허용해 주세요.\n'
          '· 다운로드 (또는 음악 및 오디오)\n'
          '· 모든 파일 관리 (있는 경우)\n\n'
          '허용 후 다시 「백업에서 복원」을 눌러 주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );

    if (openSettings == true) {
      await _openSystemSettings();
    }
  }

  static Future<void> _openSystemSettings() async {
    if (!Platform.isAndroid) return;
    final opened = await ph.openAppSettings();
    if (!opened) {
      try {
        await _channel.invokeMethod<void>('openAppSettings');
      } on PlatformException {
        // ignore
      }
    }
  }

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

  static Future<void> cleanupDuplicates() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('cleanupDuplicateBackups');
    } on PlatformException {
      // ignore
    }
  }
}
