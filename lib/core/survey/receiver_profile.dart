import 'package:uuid/uuid.dart';
import '../hal/connection_types.dart';

class ReceiverProfile {
  final String id;
  String name;
  String manufacturer;
  String model;
  String? serialNumber;
  ConnectionType connectionType;
  String? bluetoothAddress;
  String? bleServiceUuid;
  String? bleRxUuid;
  String? bleTxUuid;
  int baudRate;
  String dataFormat; // nmea | rtcm | mixed
  bool autoConnect;
  bool autoReconnect;

  ReceiverProfile({
    String? id,
    required this.name,
    this.manufacturer = 'Generic',
    this.model = 'NMEA GNSS',
    this.serialNumber,
    this.connectionType = ConnectionType.bluetooth,
    this.bluetoothAddress,
    this.bleServiceUuid,
    this.bleRxUuid,
    this.bleTxUuid,
    this.baudRate = 115200,
    this.dataFormat = 'nmea',
    this.autoConnect = false,
    this.autoReconnect = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'manufacturer': manufacturer,
        'model': model,
        'serialNumber': serialNumber,
        'connectionType': connectionType.name,
        'bluetoothAddress': bluetoothAddress,
        'bleServiceUuid': bleServiceUuid,
        'bleRxUuid': bleRxUuid,
        'bleTxUuid': bleTxUuid,
        'baudRate': baudRate,
        'dataFormat': dataFormat,
        'autoConnect': autoConnect,
        'autoReconnect': autoReconnect,
      };

  factory ReceiverProfile.fromMap(Map map) => ReceiverProfile(
        id: map['id'] as String?,
        name: map['name'] as String? ?? 'Receiver',
        manufacturer: map['manufacturer'] as String? ?? 'Generic',
        model: map['model'] as String? ?? 'NMEA GNSS',
        serialNumber: map['serialNumber'] as String?,
        connectionType: ConnectionType.values.firstWhere(
          (e) => e.name == map['connectionType'],
          orElse: () => ConnectionType.bluetooth,
        ),
        bluetoothAddress: map['bluetoothAddress'] as String?,
        bleServiceUuid: map['bleServiceUuid'] as String?,
        bleRxUuid: map['bleRxUuid'] as String?,
        bleTxUuid: map['bleTxUuid'] as String?,
        baudRate: map['baudRate'] as int? ?? 115200,
        dataFormat: map['dataFormat'] as String? ?? 'nmea',
        autoConnect: map['autoConnect'] as bool? ?? false,
        autoReconnect: map['autoReconnect'] as bool? ?? true,
      );
}
