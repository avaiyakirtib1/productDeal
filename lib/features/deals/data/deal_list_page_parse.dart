import 'models/deal_models.dart';

@pragma('vm:entry-point')
DealListPage parseDealListPageIsolate(Map<String, dynamic> json) {
  return DealListPage.fromJson(json);
}
