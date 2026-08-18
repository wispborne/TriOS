import 'dart:typed_data';

/// Packing small lists of numbers that the ship and weapon data is full of.
///
/// A `List<double>` keeps a separate sixteen-byte object for every number, plus
/// a pointer to each. These lists are tiny and there are a great many of them —
/// two per weapon slot, and a big mod list has well over a hundred thousand
/// slots — so the bookkeeping costs far more than the numbers do.
///
/// [Float64List] holds the numbers themselves with no per-number object, and it
/// is a `List<double>`, so anything reading one of these carries on unchanged.
/// Float64 rather than Float32: the smaller type would save a little more and
/// lose precision for no good reason.

/// The empty packing, shared. Most slots have no [Float64List] worth its own
/// allocation, and an empty one is the same as every other empty one.
final Float64List _nothing = Float64List(0);

/// [numbers], packed.
Float64List packNumbers(List<double> numbers) {
  if (numbers.isEmpty) return _nothing;
  return Float64List.fromList(numbers);
}

/// [numbers], packed, or null if there were none.
///
/// For the many optional coordinate lists on ships and weapons. The field they
/// go into stays a `List<double>?`, because a [Float64List] is one — so nothing
/// reading them, including the generated mappers, has to change.
Float64List? packNumbersOrNull(List<double>? numbers) =>
    numbers == null ? null : packNumbers(numbers);
