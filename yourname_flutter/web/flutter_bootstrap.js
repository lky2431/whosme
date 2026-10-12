{{flutter_js}}
{{flutter_build_config}}

// Serverpod caches static assets for a day. Give each compiled entry point its
// build hash so a refresh cannot mix a new loader with yesterday's game code.
const buildVersion = {{flutter_service_worker_version}};
for (const build of _flutter.buildConfig.builds) {
  for (const key of ['mainJsPath', 'mainWasmPath', 'jsSupportRuntimePath']) {
    if (build[key]) build[key] += '?build=' + buildVersion;
  }
}
_flutter.loader.load();
