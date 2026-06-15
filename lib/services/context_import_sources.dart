import '../models/context_entry.dart';

abstract class HealthContextImportSource {
  Future<List<ContextEntry>> readHealthContextCandidates();
}

abstract class WeatherContextImportSource {
  Future<List<ContextEntry>> readWeatherContextCandidates();
}

abstract class WorkoutContextImportSource {
  Future<List<ContextEntry>> readWorkoutContextCandidates();
}
