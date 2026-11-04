import 'package:get/get.dart';

/// Whether the last network call could reach the server. The API client flips
/// this: a call that gets no answer sets it, any answer clears it.
class NetworkStatus {
  NetworkStatus._();

  static final isOffline = false.obs;
}
