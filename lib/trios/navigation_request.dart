import 'package:trios/trios/navigation.dart';

class NavigationRequest {
  final TriOSTools destination;
  final String? highlightKey;

  const NavigationRequest({required this.destination, this.highlightKey});
}

class ViewerFilterRequest {
  final TriOSTools destination;
  final String modName;

  const ViewerFilterRequest({required this.destination, required this.modName});
}
