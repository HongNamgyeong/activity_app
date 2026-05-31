import 'package:flutter_riverpod/flutter_riverpod.dart';

final mainTabIndexProvider =
    NotifierProvider<MainTabNotifier, int>(MainTabNotifier.new);

class MainTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}
