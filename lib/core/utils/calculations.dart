import 'dart:math' as math;
import '../../data/models/point_model.dart';
import '../../data/models/polygon_model.dart';

class SurveyCalculations {
  /// Haversine distance in meters
  static double distance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  /// Approximate polygon area in m² (spherical excess simplified)
  static double polygonArea(List<PointModel> points) {
    if (points.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    area = area.abs() / 2.0;
    const mpd = 111320.0; // meters per degree approx
    return area * mpd * mpd;
  }

  static double polygonPerimeter(List<PointModel> points) {
    if (points.length < 2) return 0;
    double p = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      p += distance(points[i].latitude, points[i].longitude,
          points[j].latitude, points[j].longitude);
    }
    return p;
  }

  /// Simple volume calculation using average height difference
  /// volume ≈ area × average height difference from a reference
  static double volumeFromPolygon(PolygonModel poly, {double referenceElevation = 0}) {
    if (poly.points.isEmpty) return 0;
    final avgElev = poly.points.map((p) => p.altitude).reduce((a, b) => a + b) / poly.points.length;
    final heightDiff = (avgElev - referenceElevation).abs();
    return poly.area * heightDiff;
  }

  /// Prismoidal volume approximation between two surfaces (simplified)
  static double prismoidalVolume(double area, double h1, double h2, double hMid) {
    return (area / 6) * (h1 + h2 + 4 * hMid);
  }
}
