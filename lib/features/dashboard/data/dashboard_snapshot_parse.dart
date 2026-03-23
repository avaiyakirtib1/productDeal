import 'models/dashboard_models.dart';

@pragma('vm:entry-point')
DashboardSnapshot parseDashboardSnapshotIsolate(Map<String, dynamic> data) {
  return DashboardSnapshot.fromJson(data);
}
