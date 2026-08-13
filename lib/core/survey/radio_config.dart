/// Radio / correction transport abstraction for Base & Rover.
/// Only expose what the active receiver can support; others stay disabled.
class RadioConfig {
  String radioType; // none | internal | external | bluetooth | serial | usb | tcp | network
  String protocol; // rtcm3 | rtcm2 | cmr | unknown
  String? channel;
  double? frequencyMhz;
  int baudRate;
  String? dataRate;
  double? txPowerWatts;
  String? tcpHost;
  int? tcpPort;
  bool supportedByReceiver;

  RadioConfig({
    this.radioType = 'none',
    this.protocol = 'rtcm3',
    this.channel,
    this.frequencyMhz,
    this.baudRate = 38400,
    this.dataRate,
    this.txPowerWatts,
    this.tcpHost,
    this.tcpPort,
    this.supportedByReceiver = false,
  });

  Map<String, dynamic> toMap() => {
        'radioType': radioType,
        'protocol': protocol,
        'channel': channel,
        'frequencyMhz': frequencyMhz,
        'baudRate': baudRate,
        'dataRate': dataRate,
        'txPowerWatts': txPowerWatts,
        'tcpHost': tcpHost,
        'tcpPort': tcpPort,
        'supportedByReceiver': supportedByReceiver,
      };

  factory RadioConfig.fromMap(Map map) => RadioConfig(
        radioType: map['radioType'] as String? ?? 'none',
        protocol: map['protocol'] as String? ?? 'rtcm3',
        channel: map['channel'] as String?,
        frequencyMhz: (map['frequencyMhz'] as num?)?.toDouble(),
        baudRate: map['baudRate'] as int? ?? 38400,
        dataRate: map['dataRate'] as String?,
        txPowerWatts: (map['txPowerWatts'] as num?)?.toDouble(),
        tcpHost: map['tcpHost'] as String?,
        tcpPort: map['tcpPort'] as int?,
        supportedByReceiver: map['supportedByReceiver'] as bool? ?? false,
      );
}
