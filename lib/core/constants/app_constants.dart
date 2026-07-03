import 'package:intl/intl.dart';

class AppConstants {
  static const appName = 'Life Dashboard';

  static const priorities = ['baixa', 'normal', 'alta'];
  static const scheduleCategories = ['estudo', 'trabalho', 'saude', 'pessoal'];
  static const eventCategories = ['pessoal', 'estudo', 'trabalho', 'saude'];

  static const weekdays = <int, String>{
    1: 'Segunda',
    2: 'Terca',
    3: 'Quarta',
    4: 'Quinta',
    5: 'Sexta',
    6: 'Sabado',
    7: 'Domingo',
  };
}

class AppFormatters {
  static final date = DateFormat('dd/MM/yyyy');
  static final dateKey = DateFormat('yyyy-MM-dd');
  static final monthDay = DateFormat('dd MMM', 'pt_PT');
}

String formatDateKey(DateTime value) => AppFormatters.dateKey.format(value);

String formatDate(DateTime? value) {
  if (value == null) {
    return 'Sem data';
  }
  return AppFormatters.date.format(value);
}

DateTime todayDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String compactTime(String value) {
  if (value.length >= 5) {
    return value.substring(0, 5);
  }
  return value;
}
