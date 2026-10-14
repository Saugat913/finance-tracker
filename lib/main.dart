import 'package:flutter/widgets.dart';
import 'package:finance_tracker/app/app.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TelemetryService.init(
    runAppCallback: () async {
      await configureDependencies();
      runApp(const FinanceTrackerApp());
    },
  );
}
