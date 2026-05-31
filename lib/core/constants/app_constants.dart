abstract final class AppConstants {
  static const appName = '레지오 활동보고';

  /// 재설치 후 복원용 JSON 백업 파일명 (Android 다운로드 등)
  static const backupFileName = 'legio_activity_report_backup.json';

  /// 앱 최초 설치 시 설정 화면에 채워지는 기본 활동 목록
  /// (실제 테스트 입력 목록 기준)
  static const defaultActivityTypes = [
    '묵주기도',
    '미사',
    '시복시성, 청원기도',
    '가족성화기도',
    '전례봉사',
    '본당 활동',
    '행사준비',
    '아침저녁 기도',
    '가족간미사',
    '성경읽기',
    '성경쓰기',
    '성체조배',
    '연도',
    '십자가의길',
    '소성무일도',
    '교우돌봄',
    '환경보호',
    '비신자상가방문',
    '성지순례',
  ];

  /// v1 기본 목록 (마이그레이션용)
  static const legacyDefaultActivityTypes = [
    '기도',
    '방문',
    '교육',
    '행사 참석',
    '봉사',
    '묵상·독서',
  ];

  /// v2 기본 목록 (마이그레이션용)
  static const previousDefaultActivityTypesV2 = [
    '미사',
    '묵주기도',
    '전례봉사',
    '시복시성, 청원기도',
    '본당 활동',
    '행사준비',
    '가족성화기도',
  ];
}
