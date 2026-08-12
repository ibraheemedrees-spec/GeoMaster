import 'antenna_config.dart';
import 'radio_config.dart';

enum RoverSessionState { idle, connecting, connected, rtkFloat, rtkFixed, error }

/// Rover mode: external GNSS receives corrections; controller configures & monitors.
class RoverSession {
  static final RoverSession instance = RoverSession._();
  RoverSession._();

  RoverSessionState state = RoverSessionState.idle;
  AntennaConfig antenna = AntennaConfig();
  RadioConfig radio = RadioConfig();

  String correctionSource = 'ntrip'; // ntrip | radio | tcp | serial | bluetooth | none
  double elevationMaskDeg = 10;
  int minSatellites = 5;
  double maxPdop = 3.0;
  double maxCorrAgeSec = 5.0;
  String requiredSolution = 'FIXED'; // SINGLE | DGPS | FLOAT | FIXED
  double positionRateHz = 1.0;

  String? solution; // NO FIX | SINGLE | DGPS | FLOAT | FIXED
  int? satsTracked;
  int? satsUsed;
  double? corrAge;
  String? lastError;

  void applySolution(String rtkStatus) {
    solution = rtkStatus;
    switch (rtkStatus) {
      case 'FIXED':
        state = RoverSessionState.rtkFixed;
        break;
      case 'FLOAT':
        state = RoverSessionState.rtkFloat;
        break;
      default:
        if (state == RoverSessionState.idle) state = RoverSessionState.connected;
    }
  }
}
