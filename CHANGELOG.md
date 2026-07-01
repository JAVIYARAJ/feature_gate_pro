## 1.2.5

* **Bug Fix**: Fixed a Dart type promotion error in `FirebaseAnalyticsAdapter` where the `firebase_analytics` package rejected the map because it required `Map<String, Object>?` instead of `Map<String, dynamic>?`.

## 1.2.4

* **Documentation**: Massively expanded the `How to Test Every SDK Feature` section in the `README.md` to include instructions for all 8 core SDK features, including the QA Dashboard, REST APIs, Local JSON, and Analytics tracking.

## 1.2.3

* **Documentation**: Added an exhaustive `How to Test the SDK Features` section to the `README.md`. This gives developers an absolute foolproof guide on how to test Firebase caching, Percentage Rollouts, Audience Targeting, and the Offline Cache.

## 1.2.2

* **Critical Bug Fix**: Fixed an issue where `FeatureFlagWidget` and `FeatureFlagBuilder` would not reactively rebuild if the flag was provided exclusively by `FirebaseAdapterProvider` or `RestApiProvider` and not present in the local `FlagRegistry` fallback cache.

## 1.2.1

* **Documentation**: Updated the `README.md` to document the new `listenToChanges` parameter in the Reactive Widgets section.

## 1.2.0

* **New Feature**: Added `listenToChanges` parameter to `FeatureFlagWidget` and `FeatureFlagBuilder`. You can now set this to `false` if you want the widget to read the flag once during initialization and intentionally ignore background refreshes (preventing sudden UI shifts).

## 1.1.2

* **Bug Fix**: Fixed an issue where the background `refreshInterval` would successfully download new flags but fail to trigger a reactive UI rebuild for `FeatureFlagWidget` and `FeatureFlagBuilder`. 

## 1.1.1

* Added explicit instructions to the `README.md` about Firebase Remote Config's internal `minimumFetchInterval` caching to help developers correctly test the `refreshInterval` feature.

## 1.1.0

* **New Feature**: Added `jsonKey` parameter to `FeatureFlagWidget`. You can now declaratively extract boolean values from deeply nested JSON payload flags directly in the UI!

## 1.0.4

* Expanded the `README.md` to include explicit guidance on Firebase Setup, JSON object extraction using `.asJson`, and debugging utilities.

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
