/// OEM adapter architecture — interfaces only.
/// Do NOT invent proprietary protocols. Wire SDKs when documentation is available.

abstract class IOemReceiverAdapter {
  String get manufacturer;
  Future<bool> configureConstellations(Set<String> systems);
  Future<bool> setElevationMask(double degrees);
  Future<bool> setSnrMask(int snr);
  /// Raw proprietary command passthrough — only when vendor documents it.
  Future<bool> sendVendorCommand(List<int> bytes);
}

/// Placeholder adapters — all defer to generic NMEA until OEM SDK is integrated.
class GenericNmeaAdapter implements IOemReceiverAdapter {
  @override
  String get manufacturer => 'Generic';
  @override
  Future<bool> configureConstellations(Set<String> systems) async => false;
  @override
  Future<bool> setElevationMask(double degrees) async => false;
  @override
  Future<bool> setSnrMask(int snr) async => false;
  @override
  Future<bool> sendVendorCommand(List<int> bytes) async => false;
}

class EmlidAdapter extends GenericNmeaAdapter {
  @override
  String get manufacturer => 'Emlid';
}

class SouthAdapter extends GenericNmeaAdapter {
  @override
  String get manufacturer => 'South';
}

class HiTargetAdapter extends GenericNmeaAdapter {
  @override
  String get manufacturer => 'Hi-Target';
}

class ChcnavAdapter extends GenericNmeaAdapter {
  @override
  String get manufacturer => 'CHCNAV';
}

class StonexAdapter extends GenericNmeaAdapter {
  @override
  String get manufacturer => 'Stonex';
}

class ComNavAdapter extends GenericNmeaAdapter {
  @override
  String get manufacturer => 'ComNav';
}

class TrimbleAdapter extends GenericNmeaAdapter {
  @override
  String get manufacturer => 'Trimble';
}

class LeicaAdapter extends GenericNmeaAdapter {
  @override
  String get manufacturer => 'Leica';
}

class SokkiaAdapter extends GenericNmeaAdapter {
  @override
  String get manufacturer => 'Sokkia';
}

class TopconAdapter extends GenericNmeaAdapter {
  @override
  String get manufacturer => 'Topcon';
}

IOemReceiverAdapter oemAdapterFor(String manufacturer) {
  switch (manufacturer.toLowerCase()) {
    case 'emlid':
      return EmlidAdapter();
    case 'south':
      return SouthAdapter();
    case 'hi-target':
    case 'hitarget':
      return HiTargetAdapter();
    case 'chcnav':
      return ChcnavAdapter();
    case 'stonex':
      return StonexAdapter();
    case 'comnav':
      return ComNavAdapter();
    case 'trimble':
      return TrimbleAdapter();
    case 'leica':
      return LeicaAdapter();
    case 'sokkia':
      return SokkiaAdapter();
    case 'topcon':
      return TopconAdapter();
    default:
      return GenericNmeaAdapter();
  }
}
