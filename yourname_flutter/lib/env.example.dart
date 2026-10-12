enum AppEnvironment { local, production }

// Copy this file to env.dart and select your backend.
const environment = AppEnvironment.local;
const localServerUrl = 'http://localhost:18080/';
const productionServerUrl = 'https://whosme-api-759833941649.us-east4.run.app/';

String get appServerUrl {
  final url = environment == AppEnvironment.local
      ? localServerUrl
      : productionServerUrl;
  if (url.isEmpty) {
    throw StateError(
      'Set productionServerUrl in lib/env.dart before using production.',
    );
  }
  return url.endsWith('/') ? url : '$url/';
}
