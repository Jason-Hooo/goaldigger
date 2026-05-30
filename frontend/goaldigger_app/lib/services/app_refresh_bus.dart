part of '../main.dart';

class AppRefreshBus {
  AppRefreshBus._();

  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  static void notifyChanged() {
    tick.value += 1;
  }
}