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
  feature_gate_pro: ^1.0.0
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
      RestApiProvider(url: 'https://api.my-app.com/flags'),
      
      // Priority 2: Fallback to Firebase Remote Config
      FirebaseAdapterProvider(
        onFetchAndActivate: () async => await FirebaseRemoteConfig.instance.fetchAndActivate(),
        onGetAll: () => FirebaseRemoteConfig.instance.getAll(),
      ),
      
      // Priority 3: Fallback to Local Defaults
      LocalJsonProvider(assetPath: 'assets/flags.json'),
    ],
    
    // 3. (Optional) Setup periodic background syncing every 15 minutes
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

---

## 🎨 3. UI Integration (Reactive Widgets)

FeatureGate Pro provides highly optimized widgets that automatically rebuild whenever flag configurations change (e.g., via background refresh or a forced developer override).

### `FeatureFlagWidget` (Declarative UI Toggling)

Best for wrapping entire screens, features, or large UI blocks.

```dart
FeatureFlagWidget(
  flagKey: 'new_checkout_flow',
  // Rendered if 'new_checkout_flow' evaluates to true
  child: const NewCheckoutScreen(),
  // Rendered if false, missing, or targeting fails
  fallback: const OldCheckoutScreen(), 
)
```

### `FeatureFlagBuilder` (Imperative Extraction)

Best for extracting underlying strings, integers, or JSON maps.

```dart
FeatureFlagBuilder(
  flagKey: 'buy_button_color',
  builder: (context, flagValue) {
    // flagValue.asString, .asBool, .asInt, .asDouble, .asJson
    
    final color = flagValue.asString == 'blue' ? Colors.blue : Colors.red;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: const Text('Buy Now'),
      onPressed: () {},
    );
  }
)
```

---

## 🎯 4. Audience Targeting

You can restrict a feature to a specific demographic without touching your Dart code. This works seamlessly across `LocalJsonProvider`, `FirebaseAdapterProvider`, and `RestApiProvider` by reading the `metadata` JSON object.

### Supported Operators
- `==` / `!=` (Equality)
- `>`, `<`, `>=`, `<=` (Numerical & Semantic Versioning)
- `in`, `not_in` (List inclusion)

### Example JSON Ruleset

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
    attributes: {'is_premium': user.isPremium}
  )
);
```

---

## 🎲 5. Percentage Rollouts

Gradually roll out a high-risk feature to a random subset of users. FeatureGate Pro uses consistent hashing, ensuring a user assigned to the "Enabled" bucket stays in that bucket forever.

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
```

### Manual Refreshing
You can force a sync with your providers at any time (e.g. on a "Pull to Refresh" action):

```dart
// Safely mutex-locked! 10 rapid calls will only result in 1 network request.
await FlagFlow.refresh(); 
```

---

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
