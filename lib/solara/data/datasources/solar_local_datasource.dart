import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/resources/http_error.dart';
import '../../../core/util/logger.dart';
import '../../../core/util/repo_config.dart';
import '../models/solar_model.dart';

class SolarLocalDatasourceImpl implements SolarLocalDataSource {
  SolarLocalDatasourceImpl(this.config, {String? cacheName}) {
    _cacheName = cacheName ?? runtimeType.toString();
  }

  final RepoConfig config;

  late final String _cacheName;

  Box<dynamic>? _cache;
  final _log = logger;

  @override
  Future<(List<SolarModel>?, HttpError?)> fetch({DateTime? date}) async {
    try {
      if (!await Hive.boxExists(_cacheName)) {
        _log.w('Hive Box for SolarDataSourceImpl not found');
        return (
          null,
          HttpError(
              type: HttpExceptionType.localStorage,
              error: 'Cache for SolarDataSourceImpl not found')
        );
      }

      await _openStorage();

      final List<dynamic> resultItems = _cache!.values.toList();

      List<SolarModel> solarModels = _filterByDate(resultItems, date);

      _log.i(
          'Fetched ${solarModels.length} from SolarModelLocalDataSourceImpl cache');
      await _closeStorage();
      return (solarModels, null);
    } catch (e) {
      _log.e('Error fetching data from SolarDataSourceImpl: $_cacheName: $e');
      return (null, HttpError(error: e));
    }
  }

  @override
  Future<bool> create(SolarModel model) async {
    final String? key = model.date?.toIso8601String();

    if (key == null) {
      return false;
    }

    await _openStorage();

    if (_cache!.containsKey(key)) {
      return false;
    }

    await _cache!.put(key, model.toJson());
    await _closeStorage();
    return true;
  }

  @override
  Future<void> clear() async {
    await _openStorage();
    try {
      _cache?.clear();
      _log.i('Cleared SolarLocalDataSourceImpl local storage');
    } catch (e) {
      _log.e(e);
      rethrow;
    }
  }

  Future<bool> _openStorage() async {
    if (Hive.isBoxOpen(_cacheName)) {
      return true;
    }

    _cache = await Hive.openBox(_cacheName);
    return true;
  }

  Future<bool> _closeStorage() async {
    /// Not necessary according to docs:
    /// [https://docs.hivedb.dev/#/basics/boxes?id=close-box]
    await _cache?.close();
    return true;
  }

  List<SolarModel> _filterByDate(List<dynamic> resultItems, DateTime? date) {
    if (date == null) {
      return [];
    }

    List<SolarModel> solarModels = [];

    for (var item in resultItems) {
      SolarModel model = SolarModel.fromJson(Map<String, dynamic>.from(item));
      DateTime? modelDate = model.date;

      if (modelDate == null) {
        continue;
      }

      if (modelDate.year == date.year &&
          modelDate.month == date.month &&
          modelDate.day == date.day) {
        solarModels.add(model);
      }
    }
    return solarModels;
  }
}

abstract class SolarLocalDataSource {
  Future<(List<SolarModel>?, HttpError?)> fetch({
    required DateTime? date,
  });

  Future<bool> create(SolarModel model);

  Future<void> clear();
}
