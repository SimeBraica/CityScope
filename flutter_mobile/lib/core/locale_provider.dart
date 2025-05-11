import 'package:flutter/material.dart';

class LocaleProvider extends InheritedWidget {
  final void Function(Locale) setLocale;
  const LocaleProvider({required this.setLocale, required Widget child, Key? key}) : super(key: key, child: child);

  static LocaleProvider? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<LocaleProvider>();

  @override
  bool updateShouldNotify(LocaleProvider oldWidget) => true;
} 