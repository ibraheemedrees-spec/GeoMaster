import 'gnss_fix.dart';

enum QcStatus { acceptable, warning, notAcceptable }

class QualityLimits {
  int minSatellites;
  double maxPdop;
  double maxHAccuracy;
  double maxVAccuracy;
  double maxCorrAgeSec;
  bool requireRtkFixed;

  QualityLimits({
    this.minSatellites = 5,
    this.maxPdop = 3.0,
    this.maxHAccuracy = 0.020,
    this.maxVAccuracy = 0.030,
    this.maxCorrAgeSec = 5.0,
    this.requireRtkFixed = false,
  });

  Map<String, dynamic> toMap() => {
        'minSatellites': minSatellites,
        'maxPdop': maxPdop,
        'maxHAccuracy': maxHAccuracy,
        'maxVAccuracy': maxVAccuracy,
        'maxCorrAgeSec': maxCorrAgeSec,
        'requireRtkFixed': requireRtkFixed,
      };

  factory QualityLimits.fromMap(Map map) => QualityLimits(
        minSatellites: map['minSatellites'] as int? ?? 5,
        maxPdop: (map['maxPdop'] as num?)?.toDouble() ?? 3.0,
        maxHAccuracy: (map['maxHAccuracy'] as num?)?.toDouble() ?? 0.020,
        maxVAccuracy: (map['maxVAccuracy'] as num?)?.toDouble() ?? 0.030,
        maxCorrAgeSec: (map['maxCorrAgeSec'] as num?)?.toDouble() ?? 5.0,
        requireRtkFixed: map['requireRtkFixed'] as bool? ?? false,
      );
}

class QualityResult {
  final QcStatus status;
  final List<String> messages;

  const QualityResult(this.status, this.messages);

  String get label {
    switch (status) {
      case QcStatus.acceptable:
        return 'ACCEPTABLE';
      case QcStatus.warning:
        return 'WARNING';
      case QcStatus.notAcceptable:
        return 'NOT ACCEPTABLE';
    }
  }
}

class QualityControl {
  static QualityResult evaluate(GnssFix fix, QualityLimits limits) {
    final msgs = <String>[];
    var hardFail = false;
    var warn = false;

    final sats = fix.satellitesUsed ?? fix.satellitesVisible;
    if (sats != null && sats < limits.minSatellites) {
      msgs.add('Satellites $sats < ${limits.minSatellites}');
      hardFail = true;
    }

    if (fix.pdop != null && fix.pdop! > limits.maxPdop) {
      msgs.add('PDOP ${fix.pdop!.toStringAsFixed(1)} > ${limits.maxPdop}');
      hardFail = true;
    }

    if (fix.horizontalAccuracy != null &&
        fix.horizontalAccuracy! > limits.maxHAccuracy) {
      msgs.add(
          'H Acc ${fix.horizontalAccuracy!.toStringAsFixed(3)} > ${limits.maxHAccuracy}');
      // Phone GPS often > 0.02m — warning unless RTK required
      if (limits.requireRtkFixed) {
        hardFail = true;
      } else {
        warn = true;
      }
    }

    if (fix.verticalAccuracy != null &&
        fix.verticalAccuracy! > limits.maxVAccuracy) {
      msgs.add(
          'V Acc ${fix.verticalAccuracy!.toStringAsFixed(3)} > ${limits.maxVAccuracy}');
      if (limits.requireRtkFixed) {
        hardFail = true;
      } else {
        warn = true;
      }
    }

    if (fix.correctionAgeSec != null &&
        fix.correctionAgeSec! > limits.maxCorrAgeSec) {
      msgs.add(
          'Corr age ${fix.correctionAgeSec!.toStringAsFixed(1)}s > ${limits.maxCorrAgeSec}');
      warn = true;
    }

    if (limits.requireRtkFixed && fix.rtkStatus != 'FIXED') {
      msgs.add('RTK FIXED required (now ${fix.rtkStatus})');
      hardFail = true;
    }

    if (!fix.hasPosition) {
      msgs.add('No position');
      hardFail = true;
    }

    if (msgs.isEmpty) msgs.add('All checks passed');

    if (hardFail) return QualityResult(QcStatus.notAcceptable, msgs);
    if (warn) return QualityResult(QcStatus.warning, msgs);
    return QualityResult(QcStatus.acceptable, msgs);
  }
}
