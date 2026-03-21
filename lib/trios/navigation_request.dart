import 'package:trios/trios/navigation.dart';

class NavigationRequest {
  final TriOSTools destination;
  final String? highlightKey;

  const NavigationRequest({required this.destination, this.highlightKey});
}
