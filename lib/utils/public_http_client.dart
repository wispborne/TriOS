import 'dart:io';

typedef HttpAddressLookup = Future<List<InternetAddress>> Function(String host);
typedef HttpSocketConnect = Future<ConnectionTask<Socket>> Function(
  InternetAddress address,
  int port,
);

/// Opens sockets only to public addresses. Connect to the checked IP itself so
/// a second DNS lookup cannot replace it with a local address. Retain the
/// original hostname for HTTP headers and TLS verification.
HttpClient createPublicHttpClient({
  bool allowSelfSignedCertificates = false,
  HttpAddressLookup? lookup,
  HttpSocketConnect? connect,
}) {
  final resolve = lookup ?? InternetAddress.lookup;
  final open = connect ?? Socket.startConnect;
  final client = HttpClient();
  client.findProxy = (_) => 'DIRECT';
  client.connectionTimeout = const Duration(seconds: 20);
  client.connectionFactory = (url, proxyHost, proxyPort) async {
    final literal = InternetAddress.tryParse(url.host);
    final addresses = literal == null ? await resolve(url.host) : [literal];
    if (addresses.isEmpty || addresses.any((a) => !isPublicHttpAddress(a))) {
      throw const FormatException(
        'Sources must use a public internet address.',
      );
    }
    final task = await open(addresses.first, url.port);
    if (url.scheme != 'https') return task;
    Socket? activeSocket;
    var cancelled = false;
    final secured = task.socket.then((socket) async {
      activeSocket = socket;
      if (cancelled) {
        socket.destroy();
        throw const SocketException('Connection cancelled.');
      }
      try {
        final secure = await SecureSocket.secure(
          socket,
          host: url.host,
          onBadCertificate: (_) => allowSelfSignedCertificates,
        );
        activeSocket = secure;
        if (cancelled) {
          secure.destroy();
          throw const SocketException('Connection cancelled.');
        }
        return secure;
      } catch (_) {
        socket.destroy();
        rethrow;
      }
    });
    return ConnectionTask.fromSocket(secured, () {
      cancelled = true;
      task.cancel();
      activeSocket?.destroy();
    });
  };
  return client;
}

bool isPublicHttpAddress(InternetAddress address) {
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    final a = bytes[0];
    final b = bytes[1];
    return !(a == 0 ||
        a == 10 ||
        a == 127 ||
        (a == 100 && b >= 64 && b <= 127) ||
        (a == 169 && b == 254) ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 198 && (b == 18 || b == 19)) ||
        a >= 224);
  }
  if (address.type != InternetAddressType.IPv6) return false;
  // IPv4-mapped IPv6 addresses retain the IPv4 restrictions.
  if (bytes.take(10).every((b) => b == 0) &&
      bytes[10] == 255 &&
      bytes[11] == 255) {
    return isPublicHttpAddress(
      InternetAddress.fromRawAddress(bytes.sublist(12)),
    );
  }
  // Permit global unicast only; this excludes unspecified, loopback, local,
  // multicast, and IPv4 translation ranges. Reject 6to4 and Teredo tunnels too.
  return bytes[0] & 0xe0 == 0x20 &&
      !(bytes[0] == 0x20 && bytes[1] == 0x02) &&
      !(bytes[0] == 0x20 && bytes[1] == 0x01 && bytes[2] == 0 && bytes[3] == 0);
}
