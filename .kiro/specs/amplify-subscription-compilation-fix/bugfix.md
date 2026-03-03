# Bugfix Requirements Document

## Introduction

The Flutter app fails to compile due to a missing import and dependency for the Amplify core class. The `SubscriptionService` class attempts to use `Amplify.API.subscribe()` at line 86, but the `Amplify` class is not available because:

1. The file only imports `package:amplify_api/amplify_api.dart` which provides API types but not the core Amplify class
2. The `pubspec.yaml` is missing the `amplify_flutter` package dependency
3. The Amplify class needs to be imported from `package:amplify_flutter/amplify_flutter.dart`

This prevents the app from compiling and blocks the real-time order update functionality implemented in the local-order-persistence-sync spec.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the app is compiled THEN the system fails with error "The getter 'Amplify' isn't defined for the type 'SubscriptionService'" at line 86 of subscription_service.dart

1.2 WHEN subscription_service.dart tries to call Amplify.API.subscribe() THEN the system cannot resolve the Amplify class because it is not imported

1.3 WHEN pubspec.yaml is checked for dependencies THEN the system shows only amplify_api package without the required amplify_flutter core package

### Expected Behavior (Correct)

2.1 WHEN the app is compiled THEN the system SHALL compile successfully without any errors related to the Amplify class

2.2 WHEN subscription_service.dart tries to call Amplify.API.subscribe() THEN the system SHALL resolve the Amplify class from the amplify_flutter package import

2.3 WHEN pubspec.yaml is checked for dependencies THEN the system SHALL include both amplify_flutter and amplify_api packages with compatible versions

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the SubscriptionService class methods are called THEN the system SHALL CONTINUE TO provide the same subscription management functionality

3.2 WHEN subscription events are received THEN the system SHALL CONTINUE TO handle them with the existing _handleSubscriptionUpdate logic

3.3 WHEN subscriptions are cancelled THEN the system SHALL CONTINUE TO clean up resources using the existing cancelSubscription and cancelAllSubscriptions methods

3.4 WHEN other files import subscription_service.dart THEN the system SHALL CONTINUE TO work without requiring changes to those import statements
