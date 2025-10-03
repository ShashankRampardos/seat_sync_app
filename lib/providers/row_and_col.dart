import 'package:flutter_riverpod/flutter_riverpod.dart';

final rowAndCol = Provider<List<int>>((ref) {
  return [5, 4];
});

// now we can use the row and column values any where across the app
