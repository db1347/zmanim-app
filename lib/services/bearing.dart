/// Pure spherical-geometry helpers for the prayer compass.
///
/// Both bearing conventions are offered because the halachic question of how
/// to "face Jerusalem" on a globe is a genuine debate: the great-circle path
/// is the shortest route, while the rhumb line keeps a constant compass
/// heading (from New York they differ by roughly 70°).
library;

import 'dart:math' as math;

double _deg2rad(double deg) => deg * math.pi / 180.0;
double _rad2deg(double rad) => rad * 180.0 / math.pi;

double _normalize(double deg) {
  final d = deg % 360.0;
  return d < 0 ? d + 360.0 : d;
}

/// Initial great-circle bearing from (lat1,lng1) to (lat2,lng2), in degrees
/// clockwise from true north [0, 360).
double greatCircleBearing(
    double lat1, double lng1, double lat2, double lng2) {
  final phi1 = _deg2rad(lat1);
  final phi2 = _deg2rad(lat2);
  final dLambda = _deg2rad(lng2 - lng1);

  final y = math.sin(dLambda) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
  return _normalize(_rad2deg(math.atan2(y, x)));
}

/// Constant-heading (rhumb line / loxodrome) bearing, degrees from true
/// north [0, 360).
double rhumbLineBearing(double lat1, double lng1, double lat2, double lng2) {
  final phi1 = _deg2rad(lat1);
  final phi2 = _deg2rad(lat2);
  var dLambda = _deg2rad(lng2 - lng1);

  // Take the shorter way around the globe.
  if (dLambda.abs() > math.pi) {
    dLambda = dLambda > 0
        ? dLambda - 2 * math.pi
        : dLambda + 2 * math.pi;
  }

  final dPsi = math.log(
      math.tan(math.pi / 4 + phi2 / 2) / math.tan(math.pi / 4 + phi1 / 2));
  return _normalize(_rad2deg(math.atan2(dLambda, dPsi)));
}

/// Great-circle distance in kilometers (haversine, mean Earth radius).
double greatCircleDistanceKm(
    double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final phi1 = _deg2rad(lat1);
  final phi2 = _deg2rad(lat2);
  final dPhi = _deg2rad(lat2 - lat1);
  final dLambda = _deg2rad(lng2 - lng1);

  final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) * math.cos(phi2) *
          math.sin(dLambda / 2) * math.sin(dLambda / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Signed smallest angle from [from] to [to] in degrees, range (-180, 180].
double angleDelta(double from, double to) {
  var d = (to - from) % 360.0;
  if (d > 180.0) d -= 360.0;
  if (d <= -180.0) d += 360.0;
  return d;
}
