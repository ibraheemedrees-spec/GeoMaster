/// Transport types supported by GeoMaster (hardware-independent).
enum ConnectionType {
  internalGnss,
  bluetooth,
  ble,
  usb,
  serial,
  tcpIp,
  wifi,
}

extension ConnectionTypeLabel on ConnectionType {
  String get label {
    switch (this) {
      case ConnectionType.internalGnss:
        return 'Internal GNSS';
      case ConnectionType.bluetooth:
        return 'Bluetooth';
      case ConnectionType.ble:
        return 'BLE';
      case ConnectionType.usb:
        return 'USB';
      case ConnectionType.serial:
        return 'Serial';
      case ConnectionType.tcpIp:
        return 'TCP/IP';
      case ConnectionType.wifi:
        return 'Wi-Fi';
    }
  }
}

enum ConnectionState {
  disconnected,
  discovered,
  connecting,
  connected,
  dataDetected,
  gnssVerified,
  rtkVerified,
  error,
}

extension ConnectionStateLabel on ConnectionState {
  String get label {
    switch (this) {
      case ConnectionState.disconnected:
        return 'DISCONNECTED';
      case ConnectionState.discovered:
        return 'DISCOVERED';
      case ConnectionState.connecting:
        return 'CONNECTING';
      case ConnectionState.connected:
        return 'CONNECTED';
      case ConnectionState.dataDetected:
        return 'DATA DETECTED';
      case ConnectionState.gnssVerified:
        return 'GNSS VERIFIED';
      case ConnectionState.rtkVerified:
        return 'RTK VERIFIED';
      case ConnectionState.error:
        return 'ERROR';
    }
  }
}
