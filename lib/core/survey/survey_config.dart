import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../gnss/quality_control.dart';
import 'antenna_config.dart';
import 'receiver_profile.dart';

class SurveyConfig {
  final String id;
  String name;
  String? receiverId;
  String correctionSource; // none | ntrip | radio | tcp | base
  String? ntripHost;
  int ntripPort;
  String? ntripMountpoint;
  String? ntripUser;
  String? ntripPassword;
  bool ntripSendGga;
  int ntripGgaIntervalSec;
  bool ntripAutoReconnect;
  int ntripReconnectDelaySec;
  AntennaConfig antenna;
  String coordSystemId;
  String? geoidModel;
  String units; // m | ft
  String observationMethod; // instant | average | fixed_time | fixed_epochs
  int observationSeconds;
  int minEpochs;
  QualityLimits quality;
  double stakeoutToleranceM;
  bool isActive;

  SurveyConfig({
    String? id,
    required this.name,
    this.receiverId,
    this.correctionSource = 'none',
    this.ntripHost,
    this.ntripPort = 2101,
    this.ntripMountpoint,
    this.ntripUser,
    this.ntripPassword,
    this.ntripSendGga = true,
    this.ntripGgaIntervalSec = 5,
    this.ntripAutoReconnect = true,
    this.ntripReconnectDelaySec = 5,
    AntennaConfig? antenna,
    this.coordSystemId = 'wgs84',
    this.geoidModel,
    this.units = 'm',
    this.observationMethod = 'instant',
    this.observationSeconds = 5,
    this.minEpochs = 5,
    QualityLimits? quality,
    this.stakeoutToleranceM = 0.050,
    this.isActive = false,
  })  : id = id ?? const Uuid().v4(),
        antenna = antenna ?? AntennaConfig(),
        quality = quality ?? QualityLimits();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'receiverId': receiverId,
        'correctionSource': correctionSource,
        'ntripHost': ntripHost,
        'ntripPort': ntripPort,
        'ntripMountpoint': ntripMountpoint,
        'ntripUser': ntripUser,
        'ntripPassword': ntripPassword,
        'ntripSendGga': ntripSendGga,
        'ntripGgaIntervalSec': ntripGgaIntervalSec,
        'ntripAutoReconnect': ntripAutoReconnect,
        'ntripReconnectDelaySec': ntripReconnectDelaySec,
        'antenna': antenna.toMap(),
        'coordSystemId': coordSystemId,
        'geoidModel': geoidModel,
        'units': units,
        'observationMethod': observationMethod,
        'observationSeconds': observationSeconds,
        'minEpochs': minEpochs,
        'quality': quality.toMap(),
        'stakeoutToleranceM': stakeoutToleranceM,
        'isActive': isActive,
      };

  factory SurveyConfig.fromMap(Map map) => SurveyConfig(
        id: map['id'] as String?,
        name: map['name'] as String? ?? 'Config',
        receiverId: map['receiverId'] as String?,
        correctionSource: map['correctionSource'] as String? ?? 'none',
        ntripHost: map['ntripHost'] as String?,
        ntripPort: map['ntripPort'] as int? ?? 2101,
        ntripMountpoint: map['ntripMountpoint'] as String?,
        ntripUser: map['ntripUser'] as String?,
        ntripPassword: map['ntripPassword'] as String?,
        ntripSendGga: map['ntripSendGga'] as bool? ?? true,
        ntripGgaIntervalSec: map['ntripGgaIntervalSec'] as int? ?? 5,
        ntripAutoReconnect: map['ntripAutoReconnect'] as bool? ?? true,
        ntripReconnectDelaySec: map['ntripReconnectDelaySec'] as int? ?? 5,
        antenna: map['antenna'] is Map
            ? AntennaConfig.fromMap(Map<String, dynamic>.from(map['antenna'] as Map))
            : AntennaConfig(),
        coordSystemId: map['coordSystemId'] as String? ?? 'wgs84',
        geoidModel: map['geoidModel'] as String?,
        units: map['units'] as String? ?? 'm',
        observationMethod: map['observationMethod'] as String? ?? 'instant',
        observationSeconds: map['observationSeconds'] as int? ?? 5,
        minEpochs: map['minEpochs'] as int? ?? 5,
        quality: map['quality'] is Map
            ? QualityLimits.fromMap(Map<String, dynamic>.from(map['quality'] as Map))
            : QualityLimits(),
        stakeoutToleranceM: (map['stakeoutToleranceM'] as num?)?.toDouble() ?? 0.050,
        isActive: map['isActive'] as bool? ?? false,
      );

  SurveyConfig duplicate() {
    final m = toMap();
    m['id'] = const Uuid().v4();
    m['name'] = '$name (copy)';
    m['isActive'] = false;
    return SurveyConfig.fromMap(m);
  }
}

/// Local persistence for configs & receivers (separate from project Hive types).
class SurveyConfigStore {
  static const _configBox = 'survey_configs';
  static const _receiverBox = 'receiver_profiles';
  static const _metaBox = 'survey_meta';

  static Future<void> init() async {
    await Hive.openBox(_configBox);
    await Hive.openBox(_receiverBox);
    await Hive.openBox(_metaBox);
  }

  static Box get configs => Hive.box(_configBox);
  static Box get receivers => Hive.box(_receiverBox);
  static Box get meta => Hive.box(_metaBox);

  static List<SurveyConfig> allConfigs() {
    return configs.values
        .map((e) => SurveyConfig.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveConfig(SurveyConfig c) async {
    await configs.put(c.id, c.toMap());
  }

  static Future<void> deleteConfig(String id) async {
    await configs.delete(id);
  }

  static SurveyConfig? activeConfig() {
    final id = meta.get('activeConfigId') as String?;
    if (id == null) return null;
    final raw = configs.get(id);
    if (raw == null) return null;
    return SurveyConfig.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  static Future<void> setActiveConfig(String id) async {
    for (final key in configs.keys) {
      final m = Map<String, dynamic>.from(configs.get(key) as Map);
      m['isActive'] = key == id;
      await configs.put(key, m);
    }
    await meta.put('activeConfigId', id);
  }

  static List<ReceiverProfile> allReceivers() {
    return receivers.values
        .map((e) => ReceiverProfile.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveReceiver(ReceiverProfile r) async {
    await receivers.put(r.id, r.toMap());
  }

  static Future<void> deleteReceiver(String id) async {
    await receivers.delete(id);
  }

  static String? get activeReceiverId => meta.get('activeReceiverId') as String?;

  static Future<void> setActiveReceiver(String id) async {
    await meta.put('activeReceiverId', id);
  }
}
