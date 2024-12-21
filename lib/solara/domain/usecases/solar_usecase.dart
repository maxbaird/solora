import '../../../core/params/fetch_params.dart';
import '../../../core/resources/solara_io_exception.dart';
import '../../../core/use_case/use_case.dart';
import '../entities/solar.dart';
import '../repositories/solar_repo.dart';

class FetchSolarUseCase
    implements UseCase<(List<SolarEntity>?, SolaraIOException?), FetchParams> {
  const FetchSolarUseCase(this._solarRepo);

  final SolarRepo _solarRepo;

  @override
  Future<(List<SolarEntity>?, SolaraIOException?)> call({
    required FetchParams params,
  }) {
    return _solarRepo.fetch(date: params.date);
  }
}
