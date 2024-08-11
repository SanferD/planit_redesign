import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planit_redesign/infrastructure/stores/stores.dart';

class BlocUtils {
  static Future<void> initialize() async {
    await registerCalendarStore();
  }

  static Future<void> dispose() async {
    final store = GetIt.instance.get<CalendarsStore>();
    await store.isar.close(deleteFromDisk: true);
    GetIt.instance.unregister<CalendarsStore>();
  }

  static Future<void> registerCalendarStore() async {
    final dir = await getApplicationSupportDirectory();
    final isar = await Isar.open([CalendarSchema], directory: dir.path, inspector: true);
    GetIt.instance.registerSingleton(CalendarsStore(isar: isar));
  }
}
