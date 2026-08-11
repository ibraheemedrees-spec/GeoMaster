/// Geoid architecture: H = h - N
/// Does NOT invent geoid values. Without a model, separation is null.
class GeoidEngine {
  static final GeoidEngine _instance = GeoidEngine._();
  factory GeoidEngine() => _instance;
  GeoidEngine._();

  String? activeModel; // e.g. EGM2008 — null = unavailable
  double? _n; // undulation if known from receiver/model

  double? get separation => _n;

  bool get isAvailable => activeModel != null && _n != null;

  void clear() {
    activeModel = null;
    _n = null;
  }

  /// Set undulation only when truly known (receiver or grid).
  void setSeparation(double n, {String? model}) {
    _n = n;
    if (model != null) activeModel = model;
  }

  /// Orthometric height H = h - N, or null if N unknown.
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
