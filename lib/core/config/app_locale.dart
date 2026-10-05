import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// v1 is Turkish only (REQUIREMENTS §6), so the framework's own texts - the
/// date picker, dialog buttons, tooltips - are pinned to Turkish too rather
/// than following the device language into a half-translated screen.
const kAppLocale = Locale('tr');

const kSupportedLocales = [kAppLocale];

const List<LocalizationsDelegate<dynamic>> kLocalizationsDelegates =
    GlobalMaterialLocalizations.delegates;
