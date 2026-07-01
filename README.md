# FeatureGate Pro

![Pub Version](https://img.shields.io/pub/v/feature_gate_pro)
![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

A high-performance, robust, and extensible Feature Flag SDK for Flutter. 

FeatureGate Pro is designed for enterprise and production scale, offering a unified **Merge Engine** that seamlessly cascades between Local JSON configs, Firebase Remote Config, and custom REST APIs. It includes built-in support for **Percentage Rollouts**, **Audience Targeting**, **Analytics Sampling**, and a powerful **Developer Debug Dashboard**.

---

## 🚀 Key Features

- 🧠 **Merge Engine Architecture**: Define multiple providers. If a flag isn't found in your API, the engine seamlessly falls back to Firebase, and then down to local JSON.
- 🎯 **Advanced Audience Targeting**: Target specific user cohorts using operators like `==`, `!=`, `<`, `>`, `>=`, `<=`, `in`, and `not_in` across User ID, Country, Platform, App Version (Semantic Versioning aware!), and custom JSON attributes.
- 🎲 **Deterministic Percentage Rollouts**: Safely roll out a feature to 25% of your user base using blazing-fast, predictable FNV-1a hashing. A user in the 25% bucket stays in the 25% bucket across sessions.
- ♻️ **Reactive Flutter Widgets**: `FeatureFlagWidget` and `FeatureFlagBuilder` automatically listen for background syncs and instantly rebuild your UI without manual state management.
- 📊 **Analytics Layer with Sampling**: Track flag evaluations and A/B test variants to Firebase (or your own provider). Includes an event sampling rate (`sampleRate: 0.10`) to massively reduce analytics billing costs.
- 🛡️ **Concurrency Locks**: Rapid successive `refresh()` calls are deduplicated into a single network request to protect battery and bandwidth.
- 🛠 **QA Debug Dashboard**: A drop-in UI for your QA teams to inspect their user context, view all flag states, and force runtime overrides that instantly bypass targeting logic.

---

## 📦 1. Installation

Add `feature_gate_pro` to your `pubspec.yaml`:

```yaml
dependencies:
  feature_gate_pro: ^1.0.3
```

---

## 🛠 2. Initialization & Merge Engine

Initialize the `FlagFlow` engine before your app starts. You can provide multiple `FlagProvider`s. The Merge Engine evaluates them **in the exact order they are listed**.

### The Setup

```dart
import 'package:flutter/material.dart';
import 'package:feature_gate_pro/feature_gate_pro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlagFlow.initialize(
    // 1. (Optional) Provide Context for Targeting & Rollouts
    userContext: const UserContext(
      id: 'user_123', 
      country: 'US',
      platform: 'ios',
      appVersion: '2.1.0',
    ),
    
    // 2. Define your cascading providers
    providers: [
      // Priority 1: Check your custom REST API First
      RestApiProvider(endpoint: 'https://api.my-app.com/flags'),
      
      // Priority 2: Fallback to Firebase Remote Config
      FirebaseAdapterProvider(
        onFetchAndActivate: () async => await FirebaseRemoteConfig.instance.fetchAndActivate(),
        onGetAll: () => FirebaseRemoteConfig.instance.getAll(), // Note: Pass the function! () =>
      ),
      
      // Priority 3: Fallback to Local Defaults (assets are compiled into the app)
      LocalJsonProvider(assetPath: 'assets/flags.json'),
    ],
    
    // 3. (Optional) Setup periodic background syncing every 15 minutes
    // Note: Local asset files are read-only and won't dynamically update.
    // This timer is meant to trigger RestApiProvider or Firebase updates over the network.
    refreshInterval: const Duration(minutes: 15),

    // 4. (Optional) Attach an Analytics Adapter for A/B tracking
    analytics: FirebaseAnalyticsAdapter(
      sampleRate: 0.25, // Only log 25% of evaluations to save costs
      logEvent: (name, params) async {
         await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
      },
    ),
  );

  runApp(const MyApp());
}
```

### Firebase Setup Requirement
Because FeatureGate Pro is completely dependency-free, you must install `firebase_core` and `firebase_remote_config` in your app yourself. Configure it using `flutterfire configure`, run `Firebase.initializeApp()` in `main()`, and pass the methods to `FirebaseAdapterProvider`. The SDK uses dynamic dispatch to automatically extract the strings behind the scenes!

**Testing Firebase `refreshInterval`**: By default, Firebase caches data for 12 hours. If you pass `refreshInterval: Duration(minutes: 1)` to `FlagFlow`, Firebase will ignore the network requests and return cached data. To actually test live background refreshes, you must lower Firebase's internal cache limit in your `main.dart` *before* initializing `FlagFlow`:

```dart
await FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
  fetchTimeout: const Duration(seconds: 10),
  minimumFetchInterval: const Duration(minutes: 1), // Lower this for testing!
));
```

---

## 🎨 3. UI Integration (Reactive Widgets)

FeatureGate Pro provides highly optimized widgets that automatically rebuild whenever flag configurations change (e.g., via background refresh or a forced developer override).

### `FeatureFlagWidget` (Declarative UI Toggling)

Best for wrapping entire screens, features, or large UI blocks for simple `true`/`false` flags.

```dart
FeatureFlagWidget(
  flagKey: 'new_checkout_flow',
  // (Optional) Set to false if you don't want the UI to shift automatically when flags refresh in the background
  listenToChanges: true, 
  // Rendered if 'new_checkout_flow' evaluates to true
  child: const NewCheckoutScreen(),
  // Rendered if false, missing, or targeting fails
  fallback: const OldCheckoutScreen(), 
)
```

### `FeatureFlagBuilder` (Imperative Extraction for Strings/JSON)

Best for extracting underlying strings, integers, or JSON maps dynamically.

```dart
FeatureFlagBuilder(
  flagKey: 'enabled_modules',
  listenToChanges: true, 
  builder: (context, flagValue) {
    // flagValue.asString, .asBool, .asInt, .asDouble, .asJson
    
    final modules = flagValue.asJson;
    final isHomeEnabled = modules['home'] == true;
    final isTasksEnabled = modules['tasks'] == true;
    
    return Column(
      children: [
        if (isHomeEnabled) const HomeWidget(),
        if (isTasksEnabled) const TasksWidget(),
      ],
    );
  }
)
```

**JSON Parsing Magic**: If you provide a raw JSON map in Firebase (e.g. `{"home": true, "tasks": true}`), `FlagFlow` automatically parses it and returns it via `.asJson`.

---

## 🎯 4. Audience Targeting

You can restrict a feature to a specific demographic without touching your Dart code. This works seamlessly across `LocalJsonProvider`, `FirebaseAdapterProvider`, and `RestApiProvider`. 

To use advanced targeting, your flag in Firebase/JSON must be wrapped in a `"value"` key, alongside a `"metadata"` object.

### Supported Operators
- `==` / `!=` (Equality)
- `>`, `<`, `>=`, `<=` (Numerical & Semantic Versioning)
- `in`, `not_in` (List inclusion)

### Example JSON Format (Advanced Mode)

```json
{
  "beta_feature": {
    "value": true,
    "metadata": {
      "custom": {
        "targeting": [
          {
            "attribute": "country", 
            "operator": "in", 
            "value": ["US", "CA", "UK"]
          },
          {
            "attribute": "appVersion", 
            "operator": ">=", 
            "value": "2.0.0"
          },
          {
            "attribute": "is_premium", 
            "operator": "==", 
            "value": true
          }
        ]
      }
    }
  }
}
```
*In this example, `beta_feature` will only evaluate to `true` if the user is in US/CA/UK, running an app version of 2.0.0 or higher, and their `UserContext` indicates they are premium.*

### Updating UserContext at Runtime
If a user logs in, you can hot-swap their context and refresh the flags:
```dart
FlagFlow.setContext(
  UserContext(
    id: user.uid,
    country: user.country,
    customAttributes: {'is_premium': user.isPremium}
  )
);
```

---

## 🎲 5. Percentage Rollouts

Gradually roll out a high-risk feature to a random subset of users. FeatureGate Pro uses consistent hashing (FNV-1a), ensuring a user assigned to the "Enabled" bucket stays in that bucket forever.

### Example JSON Ruleset
```json
{
  "experimental_algorithm": {
    "value": true,
    "metadata": {
      "custom": {
        "rollout": 15
      }
    }
  }
}
```
*This configures a 15% rollout. The other 85% of users will fall back to the next `FlagProvider` in the Merge Engine (or evaluate to `false` if no fallback exists).*

*(Note: Rollouts require a `UserContext` with an `id` to hash against. If `id` is missing, the rollout fails gracefully).*

---

## 🛠 6. QA Debug Dashboard & Runtime Overrides

Empower your QA team to test every variant of your app without relying on production API changes.

FeatureGate Pro ships with `FeatureGateDebugScreen`, a drop-in Material dashboard.

### Opening the Dashboard
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const FeatureGateDebugScreen()),
);
```

### Dashboard Capabilities:
- **Inspect Context**: View the active User ID, App Version, and Country.
- **Flag Inventory**: View every flag registered in the SDK alongside its current evaluation.
- **Runtime Overrides**: Tap any flag to force it to `TRUE` or `FALSE`.
- **Bypass Logic**: Overrides have absolute maximum priority in the Merge Engine. They instantly bypass all network providers, Targeting Rules, and Rollout maths.
- *(Note: Overrides are strictly in-memory. They reset on app restart to prevent QA testers from accidentally bricking their local installation permanently).*

---

## 📝 7. API Reading (Manual Evaluation)

If you need to check a flag imperatively (e.g., inside a Bloc or ViewModel) rather than using a Widget:

```dart
final isEnabled = FlagFlow.getBool('new_checkout', defaultValue: false);
final themeString = FlagFlow.getString('theme', defaultValue: 'light');
final maxRetries = FlagFlow.getInt('max_retries', defaultValue: 3);
final config = FlagFlow.getJson('config', defaultValue: {});
```

### Manual Refreshing
You can force a sync with your providers at any time (e.g. on a "Pull to Refresh" action):

```dart
// Safely mutex-locked! 10 rapid calls will only result in 1 network request.
await FlagFlow.refresh(); 
```

### Debug Logging
If you want to understand *why* a flag evaluated a certain way (e.g., why did targeting fail? Which provider won the merge conflict?), enable debug logging:
```dart
FlagFlow.enableDebugLogging = true;
// Console Output: [FlagFlow Debug] Evaluated 'beta_feature' to 'false' (Source: Default Fallback)
```

---

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
