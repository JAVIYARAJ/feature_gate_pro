## 1.0.3

* Added comprehensive Dartdoc (`///`) comments to all public APIs (`FeatureFlagWidget`, `FlagFlow`, `UserContext`, etc.) to improve IDE hover tooltips.

## 1.0.2

* Fixed dynamic dispatch type casting for `FirebaseAdapterProvider` to perfectly extract `RemoteConfigValue`.

## 1.0.1

* Updated GitHub repository and homepage URLs in `pubspec.yaml` to ensure correct package linking on pub.dev.

## 1.0.0

* Initial Release of FeatureGate Pro SDK.
* Implemented FlagFlow Merge Engine.
* Supported Providers: `LocalJsonProvider`, `RestApiProvider`, `FirebaseAdapterProvider`.
* Supported reactive widgets: `FeatureFlagWidget`, `FeatureFlagBuilder`.
* Implemented Target Rules Engine with numeric, boolean, string, and semantic versioning support.
* Implemented Deterministic Percentage Rollout Engine.
* Implemented Mutex-locked periodic background refresh system.
* Implemented comprehensive Developer Debug Dashboard and Runtime Overrides.
* Implemented Analytics tracking layer with random sampling.
