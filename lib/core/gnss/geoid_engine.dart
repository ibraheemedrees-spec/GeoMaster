/// Geoid: H = h - N. Does not invent values. Without a model, N stays null.
class GeoidEngine {
  static final GeoidEngine _instance = GeoidEngine._();
  factory GeoidEngine() => _instance;
  GeoidEngine._();

  String? activeModel;
  double? _n;

  double? get separation => _n;
  bool get isAvailable => activeModel != null && _n != null;

  void clear() {
    activeModel = null;
    _n = null;
  }

  void setSeparation(double n, {String? model}) {
    _n = n;
    if (model != null) activeModel = model;
  }

  double? orthometric(double? ellipsoidalH) {
    if (ellipsoidalH == null || _n == null) return null;
    return ellipsoidalH - _n!;
  }

  String statusLabel() {
    if (activeModel == null) return 'Geoid model: unavailable';
    if (_n == null) return 'Geoid: $activeModel (N unavailable)';
    return 'Geoid: $activeModel  N=${_n!.toStringAsFixed(3)} m';
  }
}
