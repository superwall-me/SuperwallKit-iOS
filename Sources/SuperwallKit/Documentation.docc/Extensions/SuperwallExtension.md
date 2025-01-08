# ``SuperwallKit/Superwall``

## Overview

The ``Superwall`` class is used to access all the features of the SDK. Before using any of the features, you must call ``Superwall/configure(apiKey:purchaseController:options:completion:)-52tke`` to configure the SDK.

## Topics

### Configuring the SDK

- ``configure(apiKey:purchaseController:options:completion:)-52tke``
- ``configure(apiKey:purchaseController:options:completion:)-ds2x``
- ``configure(apiKey:)``
- ``shared``
- ``isInitialized``
- ``SuperwallDelegate``
- ``SuperwallDelegateObjc``
- ``delegate``
- ``objcDelegate``
- ``PurchaseController``
- ``PurchaseControllerObjc``
- ``subscriptionStatus``
- ``SubscriptionStatus``
- ``SuperwallOptions``
- ``PaywallOptions``
- ``preloadAllPaywalls()``
- ``preloadPaywalls(forEvents:)``
- ``confirmAllAssignments()``
- ``configurationStatus``
- ``ConfigurationStatus``
- ``isConfigured``

### Presenting and Dismissing a Paywall

- ``register(event:params:handler:feature:)``
- ``register(event:params:handler:)``
- ``register(event:)``
- ``register(event:params:)``
- ``getPaywall(forEvent:params:paywallOverrides:delegate:)``
- ``getPaywall(forEvent:params:paywallOverrides:delegate:completion:)-8u1n``
- ``getPaywall(forEvent:params:paywallOverrides:delegate:completion:)-5vtpb``
- ``GetPaywallResultObjc``
- ``publisher(forEvent:params:paywallOverrides:isFeatureGatable:)``
- ``getPresentationResult(forEvent:)``
- ``getPresentationResult(forEvent:params:)-9ivi6``
- ``getPresentationResult(forEvent:params:)-60qtr``
- ``getPresentationResult(forEvent:params:completion:)``
- ``dismiss()-844a9``
- ``dismiss()-4objm``
- ``dismiss(completion:)``
- ``PresentationResult``
- ``PresentationResultObjc``
- ``PaywallInfo``
- ``SuperwallEvent``
- ``SuperwallEventObjc``
- ``PaywallSkippedReason``
- ``PaywallSkippedReasonObjc``
- ``PaywallViewController``
- ``PaywallViewControllerDelegate``
- ``PaywallViewControllerDelegateObjc``

### Handling Purchases

- ``purchase(_:)``
- ``purchase(_:completion:)-6oyxm``
- ``purchase(_:completion:)-4rj6r``
- ``restorePurchases()``
- ``restorePurchases(completion:)-4fx45``
- ``restorePurchases(completion:)-4cxt5``
- ``SuperwallOptions/shouldObservePurchases``

### In-App Previews

- ``handleDeepLink(_:)``

### Identifying a User

- ``identify(userId:options:)``
- ``identify(userId:)``
- ``IdentityOptions``
- ``reset()``
- ``setUserAttributes(_:)-1wql2``
- ``setUserAttributes(_:)-8jken``
- ``removeUserAttributes(_:)``
- ``userAttributes``

### Game Controller

- ``gamepadValueChanged(gamepad:element:)``

### Logging

- ``logLevel``
- ``SuperwallDelegate/handleLog(level:scope:message:info:error:)-9kmai``
- ``LogLevel``
- ``LogScope``
- ``SuperwallOptions/Logging-swift.class``

### Helpers

- ``togglePaywallSpinner(isHidden:)``
- ``latestPaywallInfo``
- ``presentedViewController``
- ``userId``
- ``isLoggedIn``
