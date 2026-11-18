/// Canonical geographic value types.
///
/// This package has no renderer, database or HTTP dependency on purpose: a
/// backend-only, agent-only or game-only consumer must be able to take the
/// types without pulling in a map widget.
library;

export 'src/bounding_box.dart';
export 'src/coordinate.dart';
export 'src/crs.dart';
export 'src/distance.dart';
export 'src/errors.dart';
export 'src/geometry.dart';
