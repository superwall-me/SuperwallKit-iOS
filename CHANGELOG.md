# CHANGELOG

The changelog for `SuperwallKit`. Also see the [releases](https://github.com/superwall/Superwall-iOS/releases) on GitHub.

## 4.0.0-beta.2

### Fixes

- Fixes an issue to do with audience filters.
- Readds unavailable functions from v3 to make the upgrade path smoother.

## 4.0.0-beta.1

### Fixes

- Removes date checking for transactions, which was resulting in some purchases being marked as restored.
- Checks for the `SKIncludeConsumableInAppPurchaseHistory` info.plist key. If set to `true`, defaults to using `.storeKit2` only if on iOS 18+.
- Fixes visionOS issues.

## 4.0.0-alpha.4

### Fixes

- Fixes bug for StoreKit version specified in a `transaction_complete` event.
- Reverts change of `presented_by_placement_name` to `presented_by_event_name` to fix campaign charts.

## 4.0.0-alpha.3

### Enhancements

- Adds the obsoleted attribute to more variants of `register(event:)` for a smoother upgrade path.

### Fixes

- Fixes issue with optional audience filter properties inside `PaywallInfo`.

## 4.0.0-alpha.2

### Breaking Changes

- Removes `trigger_session_id` from `PaywallInfo` params.
- `ProductInfo` is renamed to `Product` and the old `Product` class no longer exists.
- Removes `Superwall.shared.subscriptionStatus` in favor of entitlements.
- Removes `subscriptionStatus_didChange`.
- Removes `subscriptionStatusDidChange(to:)` from the `SuperwallDelegate`.
- Renames `productItems` to `products` in `PaywallInfo`.
- Renames `register(event:)` to `register(placement:)`. DONE
- Renames `preloadPaywalls(forEvents:)` to `preloadPaywalls(forPlacements:)`. DONE
- Renames `getPaywall(forEvent:)` to `getPaywall(forPlacement:)`. DONE
- Renames `getPresentationResult(forEvent:)` to `getPresentationResult(forPlacement:)`. DONE
- Renames the `TriggerResult`, `PresentationResult` and `PaywallSkippedReason` `eventNotFound` case to `placementNotFound` and `noEventMatch` to `noAudienceMatch`. DONE
- Renames `handleSuperwallEvent(withInfo:)` to `handleSuperwallPlacement(withInfo:). DONE
- Moves `ComputedPropertyRequestType` to be a top-level type.
- Renames `Store` to `ProductStore`.
- Removes `Superwall.shared.isConfigured` in favor of `Superwall.shared.configurationStatus`.
- Defaults to StoreKit 2 for product purchasing for apps running on iOS 15+. You can change this back to StoreKit 1 by setting the `SuperwallOption` `storeKitVersion` to `.storeKit1`. When using Objective-C and providing a PurchaseController or using observer mode, the SDK will default to `.storeKit1`. If you're using Objective-C and using `purchase(_:)`, you must use `.storeKit1`.
- Changes the `PurchaseController` purchase function to `func purchase(product: StoreProduct) async -> PurchaseResult`. There will be an StoreKit 2 product accessible via `product.sk2Product` by default. However, if you're using the StoreKit 1 `SuperwallOption` or your app is running on an iOS version lower than iOS 15, this will be `nil` and you can access the StoreKit 1 product via `product.sk1Product`. DONE
- Consumables no longer count as lifetime subscriptions when using StoreKit 2. REVISIT
- Renames the `PurchaseResult` case `purchased(productId: String)` to `purchased(Product)`.
- Changes the Swift `onDismiss` block of the `PaywallPresentationHandler` to accept both a `PaywallInfo` object and a `PaywallResult` object so you know which product was purchased after dismiss.
- Changes the `onRequestDismiss` block of the `PaywallView` to accept both a `PaywallInfo` object and a `PaywallResult` object.
- Changes the Objective-C `onDismiss` block of the `PaywallPresentationHandler` to accept both a `PaywallInfo` object, a `PaywallResult` object, and an optional `StoreProduct`, so you know which product was purchased after dismiss.
- Renames `LogScope` case `paywallTransactions` to `transactions`.
- Adds `type` to the `transactionComplete` placement.

### Enhancements

- Adds `purchase(_:)` support for both StoreKit 2 products and `StoreProduct`.
- Adds `Superwall.shared.entitlements`. This is a published property of type `EntitlementStatus`. If you're using Combine or SwiftUI, you can listen to this to receive updates whenever it changes. Otherwise, you can use the `SuperwallDelegate` method `entitlementStatusDidChange(from:to:)`. If you're not using a `PurchaseController`, we will handle the entitlements for you depending on what products the user purchases. However, if you're using a `PurchaseControler`, you can set the entitlement status, which can be `.unknown`, `.inactive`, or `.active(Set<Entitlement>)`. You can also access `all`, `active` and `inactive` entitlements from the entitlements object.
- Adds `getStatus()`, `setUnknownStatus()`, `setInactiveStatus()`, and `setActiveStatus(with:)` on `Superwall.shared.entitlements` for Objective-C users.
- Tracks an `entitlementStatus_didChange` event whenever the entitlement status changes.
- Updates the example apps. We now have Basic and Advanced. Basic is a simple plug-and-play superwall setup that doesn't use entitlements. Advanced uses entitlements and has three possible ways of configuring Superwall: 1. Letting Superwall manage everything, 2. Using a purchase controller with StoreKit, 2. Using a purchase controller with RevenueCat.
- Uses `Superscript` for all audience filter evaluations. This is our in-house package that uses Google's Common Expression Language to evaluate audience filters. It allows for complex expressions within the audience filter builder.
- Adds the `LogScope` case `entitlements`.
- Adds StoreKit 2 observer mode. This can be enabled by setting the `SuperwallOptions` `shouldObservePurchases` to `true` and `storeKitVersion` to `.storeKit2` (which is the default value). Note that this is only available with apps running iOS 17.2+.
- Adds `products(for:)` which gets the ``StoreProduct`s for given product identifiers.

## 3.12.2

### Fixes

- Fixes visionOS build issues.

## 3.12.1

### Fixes

- Fixes issue for flutter when enabling Apple Search Ads on the Dashboard. This is done by cleaning all user attributes such that only those that are JSON serializable are stored.
- Removes date checking for transactions, which was resulting in some purchases being marked as restored.

## 3.12.0

### Enhancements

- Adds the `SuperwallOption` `shouldObservePurchases`. Set this to `true` to allow us to observe StoreKit 1 transactions you make with your app outside of Superwall. When this is enabled Superwall will not finish your external transactions. StoreKit 2 will be widely supported in the next major version of our SDK.
- Adds Apple Search Ads attribution data to user attributes, which is visible on the user's page in Superwall. Attribution data will be collected if you have enabled Basic or Advanced Apple Search Ads in the Superwall dashboard settings. Advanced attribution data includes the keyword name, campaign name, bid amount, match type, and more. Otherwise, the basic attribution data will be collected, which is mostly IDs. This data will soon be added to Charts.
- Adds `isSubscribed` to product attributes so that you can use `products.primary.isSubscribed` as a dynamic value in the paywall editor.
- Adds `device.appVersionPadded` to the device properties that you can use in audience filters.
- Adds a `notificationPermissionsDenied` `PaywallOption`, which you can set to show an alert after a user denies notification permissions.

### Fixes

- Fixes issue where network requests that returned an error code weren't being retried.
- Fixes date formatting on a device property.

## 3.11.3

### Enhancements

- Updates Superscript to [0.1.16](https://github.com/superwall/Superscript-iOS/releases/tag/0.1.16).

## 3.11.2

### Enhancements

- Adds `shimmerView_start` and `shimmerView_complete` events. The `shimmerView_complete` event contains a `visible_duration` parameter which indicates how long the shimmer view was visible after paywall open, if at all.
- Adds `isScrollEnabled` to `PaywallInfo`, which indicates whether the webview should scroll or not.
- Updates Superscript to [v0.1.15](https://github.com/superwall/Superscript-iOS/releases/tag/0.1.15).
- Adds `$source`, `$store`, and `$storekit_version` to transaction events.

### Fixes

- Fixes issue where using a `PurchaseController` with `Superwall.shared.purchase(product)` was resulting in transaction events being tracked twice.
- Fixes build issues for visionOS, Mac Catalyst, and watchOS.

## 3.11.1

### Fixes

- Fixes an issue when getting the Superscript package.

## 3.11.0

### Enhancements

- Adds a `PaywallView` for SwiftUI users using iOS 14+. You can use this as a standalone paywall view that you can embed and present however you like instead of using `register`. This uses `getPaywall(forEvent:params:paywallOverrides:)` under the hood. Note that you're responsible for the deallocation of the view. If you have a `PaywallView` presented somewhere and you try to present the same `PaywallView` elsewhere, you will get a crash.
- Adds our `Superscript` package as a dependency. We are migrating towards using Google's Common Expression Language (CEL) in audience filters to allow for more complex expressions. The use of this is behind a feature flag.

### Fixes

- visionOS fixes.

## 3.10.2

### Enhancements

- Adds `maxConfigRetryCount` as a `SuperwallOption`. Use this to determine the number of times the SDK will attempt to get the Superwall configuration after a network failure before it times out.

## 3.10.1

### Fixes

- Tweaks logic for `purchase(_:)` and `restorePurchases()` so the SDK never finishes transactions made when there's a purchase controller present.
- Fixes internal caching issues of the Superwall config.

## 3.10.0

### Enhancements

- Adds `purchase(_:)` to initiate a purchase of an `SKProduct` via Superwall regardless of whether you are using paywalls or not.
- Adds `restorePurchases()` to restore purchases via Superwall.
- Adds an optional `paywall(_:loadingStateDidChange)` function to the `PaywallViewControllerDelegate`. This is called when the loading state of the presented `PaywallViewController` did change.
- Makes `loadingState` on the `PaywallViewController` a public published property.

### Fixes

- Tweaks AdServices token logic to prevent getting the token twice.

## 3.9.1

### Fixes

- Moves to collecting just the AdServices attribute token, which will be process by our backend. Adds `adServicesTokenRequest_start`, `adServicesTokenRequest_complete`, and `adServicesTokenRequest_fail`.

## 3.9.0

### Enhancements

- If a network issue occurs while retrieving the latest Superwall configuration, or it takes longer than 1s to retrieve, the SDK falls back to a cached version. Then it tries to refresh it in the background. This behavior is behind a feature flag.
- When the Superwall configuration is set or refreshed, a `config_refresh` event is tracked, which will give insight into whether a cached version of the Superwall configuration is being used or not.
- When the Superwall configuration fails to be retrieved, a `config_fail` event is tracked.
- Adds the `config_caching` capability.
- Adds the `SuperwallOption` `collectAdServicesAttribution`. When set to `true`, this will get the app-download campaign attributes associated with Apple Search Ads and attach them to the user attributes. This happens once per user per install. Calling `Superwall.shared.reset()` will fetch the attributes again and attach them to the new user.
- Adds`adServicesAttributionRequest_start`, `adServicesAttributionRequest_fail`, and `adServicesAttributionRequest_complete` events for the lifecycle of collecting AdServices attributes.

### Fixes

- Adds in missing `weak self` references inside task group closures.

## 3.8.0

### Enhancements

- Adds `Superwall.shared.confirmAllAssignments()`, which confirms assignments for all placements and returns an array of all confirmed experiment assignments. Note that the assignments may be different when a placement is registered due to changes in user, placement, or device parameters used in audience filters.
- Adds a published property `Superwall.shared.configurationStatus`, which replaces `isConfigured`. This is an enum which can either be `pending`, `configured`, or `failed`.

### Fixes

- Fixes `UIScreen unavailable in visionOS` error message in `PaywallViewController`.
- Fixes the error `Symbol not found: _$s10Foundation14NSDecimalRoundyySpySo0B0aG_SPyADGSiSo14NSRoundingModeVtF`, which is an Xcode 16 bug.

## 3.7.4

### Fixes

- Fixes rare crash caused by a Combine issue.
- Confirms the assigment to holdouts for implicit placements like `paywall_decline`.
- Tracks the `trigger_fire` event for implicit placements.

## 3.7.3

### Fixes

- Fixes issue with decoding custom placements from paywalls.

## 3.7.2

### Fixes

- Changes access level of a property used by our Flutter and React Native wrapper SDKs.

## 3.7.1

### Enhancements

- Adds a `custom_placement` event that you can attach to any element in the paywall with a dictionary of parameters. When the element is tapped, the event will be tracked. The name of the placement can be used to trigger a paywall and its params used in audience filters.
- Tracks a `config_attributes` event after calling `Superwall.configure`, which contains info about the configuration of the SDK. This gets tracked whenever you set the delegate.
- Adds in device attributes tracking after setting the interface style override.
- Adds `close_reason` to `PaywallInfo` properties.

## 3.7.0

### Enhancements

- Adds support for multiple paywall URLs, incase one CDN provider fails.
- Adds the ability for the SDK to refresh the Superwall configuration every session start, subject to a feature flag. This means the paywalls will be kept updated even if the app has been open for a long time in the background.
- Adds `build_id` and `cache_key` to `PaywallInfo`.
- Tracks a `config_refresh` Superwall event when the configuration is refreshed.
- Adds product retrying if we fail to fetch an `SKProduct`. This tracks a `paywallProductsLoad_retry` event whenever the product loading request gets retried.
- SW-2899: Adds `Superwall.shared.localeIdentifier` as a convenience variable that you can use to dynamically update the locale used for evaluating rules and getting localized paywalls.
- Adds feature flag to enable text interaction with a paywall.
- SW-2901: Adds `abandoned_product_id` to a `transaction_abandon` event to use in audience filters. You can use this to show a paywall if a user abandons the transaction for a specific product.
- Updates RevenueCat example app to use v5 of their SDK.

### Fixes

- Fixes error message `undefined is not an object` that sometimes appeared when opening a paywall.
- SW-2871: Makes sure to track device attributes after geo location data is found.
- Fixes issue where restored transactions were being finished even if a `PurchaseController` was supplied in configure.
- SW-2879: Adds `capabilities` to device attributes. This is a comma-separated list of capabilities the SDK has that you can target in audience filters. This release adds the `paywall_event_receiver` capability. This indicates that the paywall can receive transaction and restore events from the SDK.
- SW-2879: Adds `configCapabilties` which contains a `name` of the capability and any additional info. The `paywall_event_receiver` capability contains a list of eventNames specifying the exact events paywalljs can receive.
- Fixes a crash caused by an arithmetic overflow if there was an issue with audience filter limits.
- Fixes `UIScreen unavailable in visionOS` error message in `PaywallViewController`.

## 3.6.6

### Enhancements

- SW-2804: Exposes a `presentation` property on the `PaywallInfo` object. This contains information about the presentation of the paywall.
- Adds `restore_start`, `restore_complete`, and `restore_fail` events.
- SW-2850: Adds error message to `paywallWebviewLoad_fail`.
- SW-2851: Adds error message to `paywallProductsLoad_fail`.
- SW-2783: Logs error when trying to purchase a product that has failed to load.

### Fixes

- Makes sure the formatting of SK2 product variables use the same locale as the product.

## 3.6.5

### Enhancements

- Adds `enable_webview_process_pool`, `enable_suppresses_incremental_rendering`, `enable_throttle_scheduling_policy`, `enable_none_scheduling_policy` as feature flags for the webview configuration.

## 3.6.4

### Enhancements

- Tweaks to webview configuration for performance improvements.

### Fixes

- Fixes bug where paywall background wasn't being set.

## 3.6.3

### Enhancements

- SW-2828: Adds the Superwall `appUserId` as the `applicationUsername` for internal `SKPayments`.
- SW-2817: Adds support for dark mode paywall background color.
- SW-2815: Adds ability to target devices based on their IP address location. Use `device.ipRegion`, `device.ipRegionCode`, `device.ipCountry`, `device.ipCity`, `device.ipContinent`, or `device.ipTimezone`.
- Paywalls built with the new editor can be downloaded as webarchive files. This allows for shared resources and faster loading times for paywalls.

### Fixes

- Fixes issue where implicit triggers weren't sending a `paywallPresentationRequest` when they didn't result in a paywall. Now this applies only to implicit triggers that are derived from an action on the paywall, like `paywall_decline`.

## 3.6.2

### Enhancements

- Tracks an `identity_alias` event whenever identify is called to alias Superwall's anonymous ID with a developer provided id.
- Adds `setInterfaceStyle(to:)` which can be used to override the system interface style.
- Adds `device.interfaceStyleMode` to the device template, which can be `automatic` or `manual` if overriding the interface style.

### Fixes

- Changes the `$feature_gating` parameter in `PaywallInfo` from 0 and 1 to `GATED` and `NON_GATED` to prevent confusion.
- Fixes issue where feature gating wasn't working correctly when an implicit event triggered by `paywall_decline`, `transaction_fail`, `transaction_abandon`, or `survey_response` was resulting in a `skipped` `PaywallState`.
- Fixes issue where a `transaction_abandon` implicit event that resulted in a `skipped` `PaywallState` was accidentally closing a paywall when it shouldn't have.

## 3.6.1

### Enhancements

- Adds privacy manifest.

## 3.6.0

### Enhancements

- Adds support for unlimited products in a paywall.
- SW-2767: Adds `device.regionCode` and `device.preferredRegionCode`, which returns the `regionCode` of the locale. For example, if a locale is `en_GB`, the `regionCode` will be `GB`. You can use this in the filters of your campaign.
- Adds ability to specify custom API endpoints using `SuperwallOptions` to facilitate local testing more easily.

### Fixes

- Calls the completion block even if Superwall.configure is called more than once.
- `getPresentationResult` now confirms assignments for holdouts.

## 3.5.0

### Enhancements

- Adds visionOS support.

### Fixes

- Moves resources into their own resources bundle when installing via CocoaPods.

## 3.5.0-rc.3

### Fixes

- Moves resources into their own resources bundle when installing via CocoaPods.

## 3.5.0-rc.1

This is our first visionOS pre-release, we'll test this on a few devices to
ensure everything works as expected!

### Enhancements

- Adds support for visionOS!

## 3.4.8

### Enhancements

- SW-2667: Adds `preferredLanguageCode` and `preferredLocale` to device attributes. If your app isn't already localized for a language you're trying to target, the `deviceLanguageCode` and `deviceLocale` may not be what you're expecting. Use these device attributes instead to access the first preferred locale the user has in their device settings.

### Fixes

- Fixes bug where a `transaction_abandon` or `transaction_fail` event would prevent the presented paywall from dismissing if `paywall_decline` was a trigger.
- SW-2678: Fixes issue where the `subscription_start` event was being fired even if a non-recurring product was purchased.
- SW-2659: Fixes issue on macOS where the window behind a paywall wasn't being removed when a paywall was dismissed, leading to the app appearing to be in a frozen state.

## 3.4.6

### Enhancements

- Adds internal code for SDK wrappers like Flutter.

## 3.4.5

### Enhancements

- Adds internal feature flag to disable verbose events like `paywallResponseLoad_start`.
- Tracks a Superwall Event `reset` whenever `Superwall.shared.reset()` is called.

### Fixes

- Fixes issue where holdouts were still matching even if the limit set for their corresponding rules were exceeded.
- Fixes potential crash if the free trial notification delay was set to zero seconds.

## 3.4.4

### Enhancements

- Tracks user attributes on session start.
- Exposes `triggerSessionId` on the `PaywallInfo` object.
- Makes `PaywallSkippedReason` conform to `CustomStringConvertible`.
- Adds the Superwall SDK version and your app's version/build number to the debugger menu. Press the hamburger icon on the top left in the debugger to access it.

### Fixes

- Changes the way paywall presentation serialization is performed to avoid mixing of concurrency paradigms.
- Prevents `preloadAllPaywalls()` from being called if the SDK is already preloading paywalls.
- Fixes issue where experiment and trigger session details were missing from transaction events if a paywall was closed before returning a `PurchaseResult` in the `PurchaseController`.
- Prevents multiple taps on a purchase button from firing the `PurchaseController` purchase function multiple times.
- Tracks `survey_response` when selected in debugger.

## 3.4.3

### Enhancements

- Exposes `isPaywallPresented` convenience variable.
- Adds `device_attributes` event, which tracks the device attributes every new session.
- Stops preloading paywalls that we know won't ever match.
- Adds a `.restored` case to `PurchaseResult` and `PurchaseResultObjc`. Return this from your `PurchaseController` when you detect a user has tried to purchase a product that they've already purchased. This happens when `transaction.transactionDate < purchaseDate`, where `purchaseDate` is the date that the purchase was initiated. Check out `RCPurchaseController.swift` in our Superwall-UIKit+RevenueCat example app for how to implement this. If you let Superwall handle purchasing, then we will automatically detect this.
- Adds `restore_via_purchase_attempt` to a `transaction_restore` event. This indicates whether the restoration happened due to the user purchasing or restoring.

## 3.4.2

### Fixes

- Fixes issue where multiple events registered in quick succession may not be performed in serial, resulting in unexpected paywalls.
- Fixes issue where transaction data wouldn't be available for those who are using a purchase controller.

## 3.4.0

### Enhancements

- Adds `sdkVersion`, `sdkVersionPadded`, `appBuildString`, and `appBuildStringNumber` to the device object for use in rules. `sdkVersion` is the version of the sdk, e.g. `3.4.0`. `sdkVersionPadded` is the sdk version padded with zeros for use with string comparison. For example `003.004.000`. `appBuildString` is the build of your app and `appBuildStringNumber` is the build of your app casted as an Int (if possible).
- When you experience `no_rule_match`, the `TriggerFire` event params will specify which part of the rules didn't match in the format `"unmatched_rule_<id>": "<outcome>"`. Where `outcome` will either be `OCCURRENCE`, referring to the limit applied to a rule, or `EXPRESSION`. The `id` is the experiment id.
- Adds a `touches_began` implicit trigger. By adding the `touches_began` event to a campaign, you can show a paywall the first time a user touches anywhere in your app.
- Adds the ability to include a close button on a survey.
- If running in sandbox, the duration of a free trial notification added to a paywall will be converted from days to minutes for testing purposes.
- Adds the ability to show a survey after purchasing a product.

### Fixes

- Fixes issue where a survey attached to a paywall wouldn't show if you were also using the `paywall_decline` trigger.
- Fixes issue where verification was happening after the finishing of transactions when not using a `PurchaseController`.
- Fixes issue where the retrieved `StoreTransaction` associated with the purchased product may be `nil`.
- Fixes issue where a `presentationRequest` wasn't being tracked for implicit triggers like `session_start` when there was no internet.

## 3.3.2

### Fixes

- Fixes issue where a rule added with `paywall_decline` would result in the feature block being called too early.
- Fixes issue where paywall assignments may not have been cleared when resetting.

## 3.3.1

### Enhancements

- Adds logic to enhance debugging by sending a stringified version of all the device/user/event parameters used to evaluate rules within the `paywallPresentationRequest` event. This is behind a feature flag.
- Adds logic to keep the user's generated `seed` value consistent when `Superwall.identify` is called. This is behind a feature flag.

### Fixes

- Fixes rare issue when using limits on a campaign rule. If a paywall encountered an error preventing it from being presented, it may still have been counted as having been presented. This would then have affected future paywall presentation requests underneath the same rule.
- Fixes issue where assets weren't being accessed correctly when installing the SDK via CocoaPods.
- Fixes crash if you tried to save an object that didn't conform to NSSecureCoding in user attributes.

## 3.3.0

### Enhancements

- Adds the ability to add a paywall exit survey. Surveys are configured via the dashboard and added to paywalls. When added to a paywall, it will attempt to display when the user taps the close button. If the paywall has the `modalPresentationStyle` of `pageSheet`, `formSheet`, or `popover`, the survey will also attempt to display when the user tries to drag to dismiss the paywall. The probability of the survey showing is determined by the survey's configuration in the dashboard. A user will only ever see the survey once unless you reset responses via the dashboard. The survey will always show on exit of the paywall in the debugger.
- Adds the ability to add `survey_response` as a trigger and use the selected option title in rules.
- Adds new `PaywallCloseReason` `.manualClose`.

### Fixes

- Fixes a recursive issue that was happening if you forgot to configure the Superwall instance.
- Fixes issue where a preloaded `Paywall` object wouldn't have had an experiment available on its `info` property.
- Fixes "error while deleting file" log on clean install of app.
- Exposes the `IdentityOptions` initializer.
- Fixes thread safety issues.

## 3.2.2

### Fixes

- If using a purchase controller, returning `.restored` from `restorePurchases()` would dismiss the paywall and assume an active subscription status. This was incorrect behavior. Now we specifically check both the subscription status and the restoration result to determine whether to dismiss the paywall, regardless of whether a purchase controller is being used.
- Added extra logging when a timeout occurs during paywall presentation.

## 3.2.1

### Fixes

- Fixes `user_attributes` being unnecessarily fired on every cold app launch.

## 3.2.0

### Enhancements

- Adds `user.seed` to user attributes for use in campaign rules. This assigns a user a random number from 0 to 99. This allows you to segment users into cohorts across campaigns. For example, in campaign A you may say `if user.seed < 50 { show variant A } else { show variant B }`, in campaign B you may say `if user.seed < 50 { show variant X } else { show variant Y }`. Therefore users who see variant A will then see variant X.
- Adds ability to use `device.interfaceType` in campaign rules to show different paywalls for different interface types. Use this instead of `device.deviceModel`, as that can lead to inaccurate results on some devices. `interfaceType` can be one of `ipad/iphone/mac/carplay/tv/unspecified`. Note that iPhone screen size emulated in iPad will be `iphone`. Built for iPad on Mac will be `ipad`.
- Adds `presentation_source_type` to `PaywallInfo`, which lets you know the source function that retrieved the paywall – register/getPaywall/implicit.
- Tracks whether a purchase controller is being used on the `AppInstall` event.

### Fixes

- Fixes issue where the transition from background to foreground may not have been detected on app launch, resulting in paywalls not showing.
- Fixes iOS 14 transaction validation issue that affects apps on v3.0.2+.
- Adds safeguard for developers returning an empty `NSError` on purchase failure which could cause a crash.

## 3.1.1

### Enhancements

- Adds `shouldShowPurchaseFailureAlert` as a `PaywallOption`. This defaults to `true`. If you're using a `PurchaseController`, set this to `false` to disable the alert that shows after the purchase fails.

### Fixes

- Fixes issue where a secondary paywall wouldn't present with the `transaction_fail` trigger.
- Fixes issue where the paywall preview wasn't obeying free trial/default paywall overrides.
- Fixes issue where preloaded paywalls may be associated with the incorrect experiment.

## 3.1.0

### Enhancements

- Adds support for paywalls that include a free trial notification. After starting a free trial, the app checks whether the paywall should notify the user when their trial is about to end. If so, the user will be asked to enable notifications (if they haven't already) before scheduling a local notification. You can add a free trial notification to your paywall from the paywall editor.
- Adds ability to use `device.minutesSince_X`, `device.hoursSince_X`, `device.daysSince_X`, `device.monthsSince_X`, and `device.yearsSince_X` in campaign rules and paywalls, where `X` is an event name. This can include Superwall events, such as `app_open`, or your own events.
- Prints out the Superwall SDK version when the `debug` logLevel is enabled.
- Adds `removeAllPendingSuperwallNotificationRequests()`, `removeAllPendingNonSuperwallNotificationRequests()`, `removeAllDeliveredSuperwallNotifications()`, and `removeAllDeliveredNonSuperwallNotifications()` to `UNUserNotificationCenter`. You can use these methods to remove your app's notifications without affecting Superwall's local notifications and vice-versa.
- Updates RevenueCat to the latest version in our RevenueCat example app.

### Fixes

- Fixes a Core Data multi-threading issue when performing a count. If you had enabled Core Data multi-threading assertions in Xcode, this will have caused a crash.
- Fixes very rare crash when purchasing without a `PurchaseController`.
- Reduces reliance on Combine when using register to fix memory management crashes.

## 3.0.3

### Fixes

- Fixes an issue where Superwall events `app_launch`, `app_install`, and `session_start` weren't working as paywall triggers from a cold start.

## 3.0.2

### Fixes

- Fixes issues with Xcode 15 and iOS 17.
- Moves the loading of localizations to only when the debugger is launched, therefore reducing setup time of Superwall.
- Removes reliance on force unwrapping/force casting as a safety precaution.
- Moves tracking of free trial start and transaction complete events to a higher priority Task. Before, this was of background priority and would take a while to track.
- Fix crash when trying to access `Superwall.shared.userId`.
- Prices in variables are now rounded down, e.g. 3.999 becomes 3.99, rather than 4.00.
- Fixes incorrect values for `trialPeriodPrice`, `trialPeriodDailyPrice`, `trialPeriodWeeklyPrice`, `trialPeriodMonthlyPrice`, `trialPeriodYearlyPrice` variables.

## 3.0.1

### Fixes

- Fixes bug that prevented Superwall from configuring when SwiftUI users in sandbox mode used the App file's `init()` to configure Superwall.

## 3.0.0

Welcome to `SuperwallKit` v3.0, the framework formally known as `Paywall`!

This update is a major release, containing lots of breaking changes, enhancements and bug fixes. We're excited for you to use it!

We understand that transitions between major SDK releases can become frustrating, so we've made a [migration guide](https://docs.superwall.com/docs/migrating-to-v3) to make your life easier. We've also updated our [example apps](Examples) to v3, including RevenueCat+SuperwallKit and Objective-C apps. Finally, we recommend you check out our [updated docs](https://docs.superwall.com/docs).

### Breaking Changes

- Renames the package from `Paywall` to `SuperwallKit`.
- Renames the primary static class for integrating Superwall from `Paywall` to `Superwall`.
- Sets the minimum iOS version to iOS 13.
- Moves all functions and variables to the `shared` instance for consistency.
- Renames `preloadPaywalls(forTriggers:)` to `preloadPaywalls(forEvents:)`
- Renames `configure(apiKey:userId:delegate:options:)` to `configure(apiKey:purchaseController:options:completion:)`. You can use the completion block to know when Superwall has finished configuring.
- Removes delegate from `configure`. You now set the delegate via `Superwall.shared.delegate`.
- Changes `PaywallOptions` to `SuperwallOptions`. This now clearly defines which of the options are explicit to paywalls vs other configuration options within the SDK.
- Makes `Superwall.shared.options` internal so that options must be set in `configure`.
- Removes `Superwall.trigger(event:)` and replaces with register(event:params:handler:feature). This is Superwall's most powerful feature yet. Wrap your features with this method to conditionally show paywalls, lock features and more.
- Renames `Paywall.EventName` to `SuperwallEvent` and removes `.manualPresent` as a `SuperwallEvent`.
- Renames `PaywallDelegate` to `SuperwallDelegate`.
- Superwall now automatically handles all subscription-related logic. However, if you'd still like control (e.g. if you're using RevenueCat), you'll need to implement a `PurchaseController` and set `Superwall.shared.subscriptionStatus` yourself whenever the subscription status of the user changes. You pass your `PurchaseController` to `configure(apiKey:purchaseController:options:completion:)`.
- Removes `isUserSubscribed()` from the delegate and replaces this with a published instance variable `subscriptionStatus`. This is enum that defaults to `.unknown` on first install and the cached value on subsequent app opens. If you're using a `PurchaseController` to handle subscription-related logic, you must set `subscriptionStatus` every time the user's subscription status changes. If you're letting Superwall handle subscription-related logic, this value will be updated with the device receipt.
- For Objective-C users, this changes the `SWKPurchaseController` method `purchase(product:)` to `purchase(product:completion:)`. You call the completion block with the result of the user attempting to purchase a product, making sure you handle all cases of `SWKPurchaseResult`: `.purchased`, `.cancelled`, `.pending`, `failed`. When you have a purchasing error, you need to call the completion block with the `.failed` case along with the error.
- Changes `restorePurchases()` to an async function that returns a boolean instead of having a completion block.
- Removes `Paywall.load(identifier:)`. This was being used to preload a paywall by identifier.
- Removes `.triggerPaywall()` for SwiftUI apps. Instead, SwiftUI users should now use the UIKit function `Superwall.register()`.
- Changes the `period` and `periodly` attributes for 2, 3 and 6 month products. Previously, the `period` would be "month", and the `periodly` would be "monthly" for all three. Now the `period` returns "2 months", "quarter", "6 months" and the `periodly` returns "every 2 months", "quarterly", and "every 6 months".
- Removes `localizationOverride(localeIdentifier:)` and replaces it with the `SuperwallOption` `localeIdentifier`. You set this on configure.
- Removes ASN1Swift as a package dependency.
- Changes free trial logic. Previously we'd look at just the primary product. However, we determing free trial eligibility based on the first product in the paywall that has a free trial available.
- Changes Objective-C method `setUserAttributesDictionary(_:)` to `setUserAttributes(_:)`.
- Adds `PaywallInfo` to `SuperwallDelegate` methods `WillPresentPaywall(withInfo:)`, `didPresentPaywall(withInfo:)`, `willDismissPaywall(withInfo:)` and `didDismissPaywall(withInfo:)`.
- Renames `SuperwallDelegate` method `didTrackSuperwallEventInfo(_:SuperwallEventInfo)` to `handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo)` for clarity.
- Renames `SuperwallDelegate` methods `willOpenURL(url:)` and `willOpenDeepLink(url:)` to `paywallWillOpenURL(url:)` and `paywallWillOpenDeepLink(url:)` respectively.
- Changes the `logLevel` to be non-optional and introduces a `none` case to turn off logging.
- Removes all guides from the SDK documentation. From now on, our [online docs](https://docs.superwall.com/docs/) provide guides and the SDK documentation is only there as a technical reference.
- Changes the return type of `PurchaseController.restorePurchases()` from `Bool` to `RestorationResult`.
- Changes `DismissState` to `PaywallResult`.
- Renamed the `PaywallResult` case `closed` to `declined`.
- Removes .error(Error) from `PaywallSkippedReason` in favor of a new `PaywallState` case `.presentationError(Error)`.
- Exposes the `transactionBackgroundView` `PaywallOption` to Objective-C by making it non-optional and adding a `none` case in place of setting it to `nil`.

### Enhancements

- Adds `getPaywall(forEvent:params:paywallOverrides:delegate:)`! You can use this to request the `PaywallViewController` to present however you like. Please read our docs to learn more about how to use this.
- Adds paywall caching. This is enabled on all paywalls by default, however it can be turned off on a case by case basis via the dashboard. With this enhancement, your paywalls will load lightning fast and will reduce network load of your app.
- You can now pass an `IdentityOptions` object to `identify(userId:options)`. This should only be used in advanced use cases. By setting the `restorePaywallAssignments` property of `IdentityOptions` to `true`, it prevents paywalls from showing until after paywall assignments have been restored. If you expect users of your app to switch accounts or delete/reinstall a lot, you'd set this when identifying an existing account.
- Adds `Superwall.shared.isLoggedIn` to check whether the user is logged in to the SDK or not. This will be true if you've previously called `identify(userId:options:)`. This is added to user properties, which means you can create a rule based on whether the user is logged in vs. whether they're anonymous.
- Adds a new example app, UIKit+RevenueCat, which shows you how to use Superwall with RevenueCat.
- Adds a new Objective-C example app UIKit-Objc.
- Adds an Objective-C-only function `removeUserAttributes(_:)` to remove user attributes. In Swift, to remove attributes you can pass in `nil` for a specific attribute in `setUserAttributes(_:)`.
- Adds `getPresentationResult(forEvent:params:)`. This returns a `PresentationResult`, which preemptively gets the result of registering an event. This helps you determine whether a particular event will present a paywall in the future.
- Logs when products fail to load with a link to help diagnose the cause.
- Adds a published property `isConfigured`. This is a boolean which you can use to check whether Superwall is configured and ready to present paywalls.
- Adds `isFreeTrialAvailable` to `PaywallInfo`.
- Adds `subscriptionStatusDidChange(to:)` delegate function. If you're letting Superwall handle subscription logic you can use this to receive a callback whenever the user's internal subscription status changes. You can also listen to the published `subscriptionStatus` variable.
- Adds a completion handler to `Superwall.configure(...)` that lets you know when Superwall has finished configuring. You can also listen to the published `isConfigured` variable.
- If you let Superwall handle your subscription-related logic, we now assume that a non-consumable product on your paywall is a lifetime subscription. If not, you'll need to return a `SubscriptionController` from the delegate.
- `handleDeepLink(_:)` now returns a discardable `Bool` indicating whether the deep link was handled. If you're using `application(_:open:options:)` you can return its value there.
- Adds `togglePaywallSpinner(isHidden:)` to arbitrarily toggle the loading spinner on and off. This is particularly useful when you're doing async work when performing a custom action in `handleCustomPaywallAction(withName:)`.
- Adds a new event `SubscriptionStatusDidChange` which is logged on the dashboard whenever the user's subscription status changes.
- You can now target `device.isSandbox` in rules.
- Tweaks the loading indicator UI.
- Prevents the registering of events that have the same name as internally tracked `SuperwallEvents` like `paywall_open`.
- Adds a drawer display option which displays the paywall at 70% screen height on iOS 16 iPhones.
- Adds `$is_feature_gatable` standard property to register calls.
- Cleans up and reformats SDK logs.
- If you're using SwiftUI, you can now call `Superwall.configure` in the `init()` of your `App` file. This means you don't need to have a `UIApplicationDelegate`.
- You can access `device.subscriptionStatus` in a rule, which is a string that's either `ACTIVE`, `INACTIVE`, or `UNKNOWN`.
- You no longer need to have swiftlint installed to run our example apps.
- Adds static variable `Superwall.isInitialized` which is `true` when initialization is complete and `Superwall.shared` can be accessed.
- Adds `transaction_abandon`, `transaction_fail` and `paywall_decline` as potential triggers. This comes with a new `PaywallInfo` property called `closeReason`, which can either be `none`, `.systemLogic`, or `.forNextPaywall`.
- Changes default logging level to `INFO`.
- Adds new automatically tracked event `presentation_request` that gets sent with properties explaining why a paywall was or was not shown.
- Adds a `device.isFirstAppOpen` property that you can use in paywall rules. This is `true` for the very first time a user opens the app. When the user closes and reopens the app, this will be `false`.
- Adds `isInspectable` to the paywall web view if running on iOS 16.4+.
- Adds `rawTrialPeriodPrice`, `trialPeriodPrice`, `trialPeriodDailyPrice`, `trialPeriodWeeklyPrice`, `trialPeriodMonthlyPrice`, `trialPeriodYearlyPrice` to product variables.
- Fully handles what happens when there are network failures.

### Fixes

- Fixes race condition issue where the free trial paywall information would still be shown even if you had previously used a free trial on an expired product.
- Fixes a caching issue where the paywall was still showing in free trial mode when it shouldn't have. This was happening if you had purchased a free trial, let it expire, then reopened the paywall. Note that in Sandbox environments this issue may still occur due to introductory offers not being added to a receipt until after a purchase.
- The API uses background threads wherever possible, dispatching to the main thread only when necessary and when calling completion blocks.
- The API is now fully compatible with Objective-C.
- Setting the `PaywallOption` `automaticallyDismiss` to `false` now keeps the loading indicator visible after restoring and successfully purchasing until you manually dismiss the paywall.
- Improves the speed of requests by changing the cache policy of requests to our servers.
- Fixes `session_start`, `app_launch` and `first_seen` not being tracked if the SDK was initialised a few seconds after app launch.
- Stops the unnecessary retemplating of paywall variables when coming back to the paywall after visiting a link via the in-app browser.
- Removes the transaction timeout popup. This was causing a raft of issues so we now rely on overlayTimeout to cancel the transaction flow.
- Fixes bug in `<iOS 14` where the spinner wasn't appearing when transacting.
- Fixes an rare crash associated with the loading and saving of Core Data.
- Makes `NetworkEnvironment` Objective-C compatible.
- Fixes race condition when calling identify and registering an event.
- Fixes a long term bug where registering an event to show a paywall and registering an event that results in noRuleMatch would interfere with each other and cause the trigger session to be set to `nil`. This resulted in some paywall data being incorrect on the dashboard.
- Fixes issue where an invalid URL provided for an "Open URL" click behavior would result in a crash.
- Fixes various memory related crashes.
- Fixes a crash when calling `reset()` when a paywall is displayed.
- Fixes issue where a crash would occur if storage was full and a persistent container couldn't be created.
- If the internet is offline when trying to present a paywall, the paywall configuration hasn't been retrieved, and the user is not subscribed, it now throws a presentationError. If the internet reconnects future paywalls will show.
- Fixes retry logic for requests.
- Fixes crash when handling a deep link.

## 3.0.0-rc.7

### Breaking Changes

- Exposes the `transactionBackgroundView` `PaywallOption` to Objective-C by making it non-optional and adding a `none` case in place of setting it to `nil`.
- Renames `getPaywallViewController` to `getPaywall`.
- Renames `paywallStatePublisher` property on `PaywallViewController` to `statePublisher`.
- Changes the presentation error domain code from `SWPresentationError` to `SWKPresentationError`.

### Enhancements

- Adds paywall caching. This is disabled by default but we'll roll this out to users accounts remotely. With this enhancement, your paywalls will load lightning fast and will reduce network load of your app.
- Exposes `Logging` `SuperwallOption` to Objective C.
- Exposes `info` on the `PaywallViewController`.
- Adds `rawTrialPeriodPrice`, `trialPeriodPrice`, `trialPeriodDailyPrice`, `trialPeriodWeeklyPrice`, `trialPeriodMonthlyPrice`, `trialPeriodYearlyPrice`.

### Fixes

- Fixes issue where a crash would occur if storage was full and a persistent container couldn't be created.
- Fixes thread safety issue when using a lazy variable to retrieve products.
- If the internet is offline when trying to present a paywall, the paywall configuration hasn't been retrieved, and the user is not subscribed, it now throws a presentationError. If the internet reconnects future paywalls will show.
- Fixes retry logic for requests.
- Fixes crash when handling a deep link.
- Creates a strong reference to the purchase controller as it was getting deallocated if you didn't keep a hold on it.

## 3.0.0-rc.6

### Breaking Changes

- Adds a `PaywallViewControllerDelegate` to the `getPaywallViewController` functions. This is mandatory and is how you control what happens after a paywall is dismissed.
- The completion block of `getPaywallViewController(forEvent:params:paywallOverrides:delegate:completion:)` now accepts an optional `PaywallViewController`, an optional `PaywallSkippedReason` and an optional `Error`. This makes it easier to understand when the paywall was skipped vs when a real error occurred.
- Renamed the `PaywallResult` case `closed` to `declined`.

### Enhancements

- Exposes `PaywallOverrides` and `PaywallViewController` to Objective-C.
- Adds Objective-C convenience methods to `PaywallOverrides`.
- Adds a `device.isFirstAppOpen` property that you can use in paywall rules. This is `true` for the very first time a user opens the app. When the user closes and reopens the app, this will be `false`.
- Removes the need to tell us when you're going to present/have presented a `PaywallViewController` that has been retrieved using `getPaywallViewController(...)`.
- Adds `isInspectable` to the paywall web view if running on iOS 16.4+.
- Exposes `PaywallViewControllerDelegate` to be used with `getPaywallViewController(...)`

### Fixes

- Fixes various memory related crashes.
- Fixes a crash when calling `reset()` when a paywall is displayed.

## 3.0.0-rc.5

### Fixes

- Fixes bug where `Superwall.shared.register`'s feature handler would not be called if the user is subscribed.

## 3.0.0-rc.4

### Breaking Changes

- Changes `DismissState` to `PaywallResult`.
- Removes the `closedForNextPaywall` case from `PaywallResult` in favor of a new `PaywallInfo` property called `closeReason`, which can either be `nil`, `.systemLogic`, or `.forNextPaywall`.
- Changes the `PaywallPresentationHandler` variables to functions.
- Removes `Superwall.shared.track`. We're going all in on `Superwall.shared.register` baby!
- Removes .error(Error) from `PaywallSkippedReason` in favor of a new `PaywallState` case `.presentationError(Error)`.
- Removes `PaywallPresentationHandler` completion block variables removed in favor of function calls with the same names.
- Changes `.onError` of `PaywallPresentationHandler` to no longer be called when a paywall is intentionally not shown (i.e. user is subscribed, user is in holdout, no rule match, event not configured)
- Adds `.onSkip(reason:)` to `PaywallPresentationHandler` to handle cases where paywall isn't shown because user is subscribed, user is in holdout, no rules match, event not configured

### Enhancements

- Adds `getPaywallViewController`! You can no request an actual view controller to present however you like. Check function documentation in Xcode for instructions – follow directions closely.
- Changes default logging level to `INFO`.
- Adds new automatically tracked `paywall_decline` event that can be used to present a new paywall when a user dismisses a paywall.
- Allows `transaction_abandon` to trigger new paywalls when added to a campaign – called when a user abandons checkout (did you know 75% of the time, users abandon checkout when Apple's payment sheet comes up?!).
- Adds `.onSkip` to `PaywallPresentationHandler` which is passed a `PaywallSkippedReason` when a paywall is not supposed to show.
- Adds logging at `INFO` level, mansplaining exactly why a paywall is not shown when calling `register` or `getPaywallViewController`.
- Adds new automatically tracked event `presentation_request` that gets sent with properties explaining why a paywall was or was not shown.

### Fixes

- Paywalls will now show even if you are missing products.

## 3.0.0-rc.3

### Breaking Changes

- Changes the `logLevel` to be non-optional and introduces a `none` case to turn off logging.
- Removes all guides from the SDK documentation. From now on, our [online docs](https://docs.superwall.com/docs/) provide guides and the SDK documentation is only there as a technical reference.
- Changes `TrackResultObjc` to `PresentationResultObjc`
- Removes convenience methods for creating PaywallPresentationHandlers because they were a bit confusing
- Changes the return type of `PurchaseController.restorePurchases()` from `bool` to `RestorationResult`

### Enhancements

- If you're using SwiftUI, you can now call `Superwall.configure` in the `init()` of your `App` file. This means you don't need to have a `UIApplicationDelegate`.
- Prevents validation of restorations and purchases if you're using a `PurchaseController` - it's now all on you!
- Updates Objective-C sample app to use `Superwall.register` and removes legacy StoreKit code.
- Simplifies SwiftUI and RevenueCat example app.
- You can now access `device.subscriptionStatus` in a rule, which is a string that's either `ACTIVE`, `INACTIVE`, or `UNKNOWN`.
- You no longer need to have swiftlint installed to run our example apps.
- If you're not using a `PurchaseController` and a user comes across the "You're already subscribed to this product" popup, we will now correctly identify this as a restoration and not a purchase. This can happen when testing in sandbox if you purchase a product -> delete and reinstall the app -> open a paywall and purchase.
- Adds static variable `Superwall.isInitialized` which is `true` when initialization is complete and `Superwall.shared` can be accessed.
- Adds `transaction_abandon` and `transaction_fail` as potential triggers. This comes with a new `DismissState` case `closedForNextPaywall`, which is returned when dismissing one paywall for another.

### Fixes

- Fixes issue where an invalid URL provided for an "Open URL" click behavior would result in a crash.
- Exposes `PaywallPresentationHandler` as `SWKPaywallPresentationHandler` for Objective-C.

## 3.0.0-rc.2

### Enhancements

- Simplifies Superwall-UIKit-Swift example project.

### Fixes

- Fixes bug where calling Superwall.shared prior to Superwall.configure would result in a recursive loop.

## 3.0.0-rc.1

### Breaking Changes

- Adds `PaywallInfo` to `SuperwallDelegate` methods `paywallWillPresent(withInfo:)`, `paywallDidPresent(withInfo:)`, `paywallWillDismiss(withInfo:)` and `paywallDidDismiss(withInfo:)`.
- Renames `SuperwallDelegate` method `didTrackSuperwallEventInfo(_:SuperwallEventInfo)` to `handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo)` for clarity
- Renames `SuperwallDelegate` methods `willOpenURL(url:)` and `willOpenDeepLink(url:)` to `paywallWillOpenURL(url:)` and `paywallWillOpenDeepLink(url:)` respectively
- Decouples associated value of `.dismissed` in `Superwall.shared.track()` closure to `PaywallInfo` and `DismissState`.
- Changes `subscription_status_did_change` to `subscriptionStatus_didChange`.
- Renames `TrackResult` to `PresentationResult`

### Enhancements

- Introducing `Superwall.shared.register(event:params:handler:feature)`, Superwall's most powerful feature yet. Wrap your features with this method to conditionally show paywalls, lock features and more.
- Adds a drawer display option which displays the paywall at 70% screen height on iOS 16 iPhones.
- Adds warning if setting subscription status without passing through a PurchaseController during config.
- Adds `$is_feature_gatable` standard property to register and track calls
- Cleans up and reformats SDK logs

### Fixes

- Fixes a long term bug where tracking an event to show a paywall and tracking an event that results in noRuleMatch would interfere with each other and cause the trigger session to be set to `nil`. This resulted in some paywall data being incorrect on the dashboard.

## 3.0.0-beta.8

### Enhancements

- Prevents the tracking of events that have the same name as internally tracked `SuperwallEvents` like `paywall_open`.

### Fixes

- Fixes an issue with reporting in the dashboard due to a mismatch of keys between client and server.

## 3.0.0-beta.7

### Breaking Changes

- Changes Objective-C method `getTrackInfo` to `getTrackResult` to be in line with the Swift API.
- Removes the error case from the `TrackResult` and adds in `userIsSubscribed` and `paywallNotAvailable` cases.
- Moves main actor conformance to functions of PurchaseController protocol rather than the whole protocol.
- Changes Objective-C method `setUserAttributesDictionary(_:)` to `setUserAttributes(_:)`.

### Fixes

- Makes `NetworkEnvironment` Objective-C compatible.
- Fixes an issue where a manually dismissed modally presented paywall wouldn't properly dismiss.
- Fixes race condition when calling identify and tracking a paywall.

## 3.0.0-beta.6

### Breaking Changes

- `identify(userId:)` is not longer a throwing async function. Any error that occurs is logged.
- `reset` is no longer an async function.
- `presentedViewController` and `latestPaywallInfo` no longer restricted to the main actor.
- Removes `localizationOverride(localeIdentifier:)` and replaces it with the `SuperwallOption` `localeIdentifier`. You set this on configure.
- Removes delegate from `configure`. You now set the delegate via `Superwall.shared.delegate`.
- Removes `presenter` introduced in beta 5.
- Removes ASN1Swift as a package dependency.
- Changes free trial logic. Previously we'd look at just the primary product. However, we determing free trial eligibility based on the first product in the paywall that has a free trial available.

### Enhancements

- You can now target `device.isSandbox` in rules.

### Fixes

- Fixes bug where calling identify and immediately tracking a paywall would result in an error if it happened before configure returned.
- Fixes compiler bug when calling track.
- Tweaks the loading indicator.
- Fixes removing an attribute using Objective-C.
- Fixes issues where some functions tagged for the main actor weren't actually running on the main actor.
- Fixes issues with paywall product overrides.

## 3.0.0-beta.5

### Breaking Changes

- Changes `SubscriptionController` to `PurchaseController`. You now set this in `Superwall.shared.configure`, rather than via the delegate.
- Removes `isUserSubscribed()` from the `SuperwallDelegate` and replaces this with a published instance variable `subscriptionStatus`. This is enum that defaults to `.unknown` on first install and the cached value on subsequent app opens. If you're using a `SubscriptionController` to handle subscription-related logic, you must set `subscriptionStatus` every time the user's subscription status changes. If you're letting Superwall handle subscription-related logic, this value will be updated with the device receipt.
- `hasActiveSubscriptionDidChange(to:)` is replaced in favour of `subscriptionStatusDidChange(to:)`.
- Makes `Superwall.shared.options` internal so that options must be set in `configure`.

### Enhancements

- Adds a new event `SubscriptionStatusDidChange` which is logged on the dashboard.
- Adds an optional `presenter` parameter to `track`. In v2 this was known as `on`. This takes a `UIViewController` which is used to present the paywall.

## 3.0.0-beta.4

### Breaking Changes

- Moves back to using `Superwall.shared.identify(userId: userId)` and `reset()` instead of logIn/createAccount/logout/reset. This is so that it's easier for integration. However, you can now pass an `IdentityOptions` object to `identify(userId:options)`. This should only be used in advanced use cases. By setting the `restorePaywallAssignments` property of `IdentityOptions` to `true`, it prevents paywalls from showing until after paywall assignments have been restored. If you expect users of your app to switch accounts or delete/reinstall a lot, you'd set this when identifying an existing account.

### Enhancements

- Adds `hasActiveSubscriptionDidChange(to:)` delegate function. If you're letting Superwall handle subscription logic you can use this to receive a callback whenever the user's internal subscription status changes. You can also listen to the published `hasActiveSubscription` variable.
- Adds a completion handler to `Superwall.configure(...)` that lets you know when Superwall has finished configuring. You can also listen to the published `isConfigured` variable.
- If you let Superwall handle your subscription-related logic, we now assume that a non-consumable product on your paywall is a lifetime subscription. If not, you'll need to return a `SubscriptionController` from the delegate.
- `handleDeepLink(_:)` now returns a discardable `Bool` indicating whether the deep link was handled. If you're using `application(_:open:options:)` you can return its value there.
- Adds `togglePaywallSpinner(isHidden:)` to arbitrarily toggle the loading spinner on and off. This is particularly useful when you're doing async work when performing a custom action in `handleCustomPaywallAction(withName:)`.

### Fixes

- Fixes occasional thread safety related crash when loading products.
- Reverts a issue from the last beta where the paywall spinner would move up before the payment sheet appeared.

## 3.0.0-beta.3

### Fixes

- Fixes potential crash due to a using a lazy variable.

## 3.0.0-beta.2

### Breaking Changes

- Moves all functions and variables to the `shared` instance for consistency, e.g. it's now `Superwall.shared.track()` instead of `Superwall.track()`.

### Enhancements

- Readds `Superwall.shared.logLevel` as a top level static convenience variable so you can easily change the log level.
- Adds `isLoggedIn` to user properties, which means you can create a rule based on whether the user is logged in vs. whether they're anonymous.

### Fixes

- Fixes bug in `<iOS 14` where the spinner wasn't appearing when transacting.
- Fixes bug where PaywallOverrides weren't being passed in to the paywall.
- Fixes bug where purchasing, deleting then reinstalling your app, and tapping a purchase button would throw an error.
- Fixes an rare crash associated with the loading and saving of Core Data.

## 3.0.0-beta.1

Welcome to `SuperwallKit` v3.0, the framework formally known as `Paywall`!

This update is a major release, containing lots of breaking changes, enhancements and some bug fixes. We're excited for you to use it!

We understand that transitions between major SDK releases can become frustrating, so we've made a [migration guide](https://docs.superwall.com/v3.0/docs/migrating-to-v3) to make your life easier. We've also updated out [sample apps](Examples) to v3, including RevenueCat+SuperwallKit and Objective-C apps. For new users, we've created a [Quick Start Guide](https://docs.superwall.com/v3.0/docs/quick-start) to get up and running in no time. Finally, we recommend you check out our [updated docs](https://docs.superwall.com/docs).

### Breaking Changes

- Renames the package from `Paywall` to `SuperwallKit`.
- Renames the primary static class for integrating Superwall from `Paywall` to `Superwall`.
- Sets the minimum iOS version to iOS 13.
- Renames `preloadPaywalls(forTriggers:)` to `preloadPaywalls(forEvents:)`
- Renames `configure(apiKey:userId:delegate:options:)` to `configure(apiKey:delegate:options:)`. This means you no longer provide a `userId` with configure. Instead you must use the new identity API detailed below.
- Changes `PaywallOptions` to `SuperwallOptions`. This now clearly defines which of the options are explicit to paywalls vs other configuration options within the SDK.
- Renames `Superwall.trigger(event:)` to `Superwall.track(event:)`. We found that having separate implicit (`Superwall.track(event:)`) and explicit (`Superwall.trigger(event:)`) trigger functions caused confusion. So from now on, you'll just use `Superwall.track(event:)` for all events within your app.
- Renames `Paywall.EventName` to `SuperwallEvent` and removes `.manualPresent` as a `SuperwallEvent`.
- Renames `PaywallDelegate` to `SuperwallDelegate`.
- Superwall automatically handles all subscription-related logic, meaning that it's no longer a requirement to implement any of the delegate methods. Note that if you're using RevenueCat, you will still need to use the delegate methods. This is because the Superwall-handled subscription status is App Store account-specific, whereas RevenueCat is logged in user-specific. If this isn't a problem, you can just set RevenueCat in observer mode and we'll take care of the rest :)
- Moves purchasing logic from the delegate into a protocol called `SubscriptionController`. You return your `SubscriptionController` from the delegate method `subscriptionController()`.
- For Swift users, this changes the `SubscriptionController` method `purchase(product:)` to an async function that returns a `PurchaseResult`. Here, you need to return the result of the user attempting to purchase a product, making sure you handle all cases of `PurchaseResult`: `.purchased`, `.cancelled`, `.pending`, `failed(Error)`.
- For Objective-C users, this changes the delegate method `purchase(product:)` to `purchase(product:completion:)`. You call the completion block with the result of the user attempting to purchase a product, making sure you handle all cases of `PurchaseResultObjc`: `.purchased`, `.cancelled`, `.pending`, `failed`. When you have a purchasing error, you need to call the completion block with the `.failed` case along with the error.
- Changes `restorePurchases()` to an async function that returns a boolean instead of having a completion block.
- Removes `identify(userId:)` in favor of the new Identity API detailed below.
- Removes `Paywall.load(identifier:)`. This was being used to preload a paywall by identifier.
- Removes `.triggerPaywall()` for SwiftUI apps. Instead, SwiftUI users should now use the UIKit function `Superwall.track()`. Take a look at our SwiftUI example app to see how that works.
- Changes the `period` and `periodly` attributes for 2, 3 and 6 month products. Previously, the `period` would be "month", and the `periodly` would be "monthly" for all three. Now the `period` returns "2 months", "quarter", "6 months" and the `periodly` returns "every 2 months", "quarterly", and "every 6 months".

### Enhancements

- New identity API:
  - `logIn(userId:)`: Logs in a user with their `userId` to retrieve paywalls that they've been assigned to.
  - `createAccount(userId:)`: Creates an account with Superwall. This links a `userId` to Superwall's automatically generated alias.
  - `logOut(userId:)`: Logs out the user, which resets on-device paywall assignments and the `userId` stored by Superwall.
  - `reset()`: Resets the `userId`, on-device paywall assignments, and data stored by Superwall. This can be called even if the user isn't logged in.
- The identity API can be accessed using async/await or completion handlers.
- New function `Superwall.publisher(forEvent:params:overrides)` which returns a `PaywallStatePublisher` (`AnyPublisher<PaywallState, Never>`) for those Combine lovers. By subscribing to this publisher, you can receive state updates of your paywall. We've updated our sample apps to show you how to use that.
- Adds `Superwall.isLoggedIn` to check whether the user is logged in to the SDK or not. This will be true if you've previously called `logIn(userId:)` or `createAccount(userId:)`.
- Adds a new example app, UIKit+RevenueCat, which shows you how to use Superwall with RevenueCat.
- Adds a new Objective-C example app UIKit-Objc.
- Adds an Objective-C-only function `removeUserAttributes(_:)` to remove user attributes. In Swift, to remove attributes you can pass in `nil` for a specific attribute in `setUserAttributes(_:)`.
- Adds `getTrackResult(forEvent:params:)`. This returns a `TrackResult` which tells you the result of tracking an event, without actually tracking it. This is useful if you want to figure out whether a paywall will show in the future.
- Logs when products fail to load with a link to help diagnose the cause.
- Adds a published property `hasActiveSubscription`, which you can check to determine whether Superwall detects an active subscription. Its value is stored on disk and synced with the active purchases on device. If you're using Combine or SwiftUI, you can subscribe or bind to this to get notified whenever the user's subscription status changes. If you're implementing your own `SubscriptionController`, you should rely on your own logic to determine subscription status.
- Adds a published property `isConfigured`. This is a boolean which you can use to check whether Superwall is configured and ready to present paywalls.
- Adds `isFreeTrialAvailable` to `PaywallInfo`.
- Tracks whenever the paywall isn't presented for easier debugging.

### Fixes

- Fixes a caching issue where the paywall was still showing in free trial mode when it shouldn't have. This was happening if you had purchased a free trial, let it expire, then reopened the paywall. Note that in Sandbox environments this issue may still occur due to introductory offers not being added to a receipt until after a purchase.
- The API uses background threads wherever possible, dispatching to the main thread only when necessary and when returning from completion blocks.
- The API is now fully compatible with Objective-C.
- Setting the `PaywallOption` `automaticallyDismiss` to `false` now keeps the loading indicator visible after restoring and successfully purchasing until you manually dismiss the paywall.
- Improves the speed of requests by changing the cache policy of requests to our servers.
- Fixes `session_start`, `app_launch` and `first_seen` not being tracked if the SDK was initialised a few seconds after app launch.
- Stops the unnecessary retemplating of paywall variables when coming back to the paywall after visiting a link via the in-app browser.
- Removes the transaction timeout popup. This was causing a raft of issues so we now rely on overlayTimeout to cancel the transaction flow.

---

## 2.5.8

### Enhancements

- Adds `isExternalDataCollectionEnabled` data privacy `PaywallOption`. When `false`, prevents non-Superwall events and properties from being sent back to the superwall servers.
- Adds an `X-Is-Sandbox` header to all requests such that sandbox data doesn't affect your production analytics on superwall.com.

### Fixes

- Fixes a bug that prevented the correct calculation of a new app session.
- Fixes missing loading times of the webview and products.

---

## 2.5.6

### Fixes

- Fixes a bug found in the previous version. Disabling the preloading of paywalls for specific triggers via remote config now works correctly.

---

## 2.5.5

### Fixes

- Fixes a crash when all variants of a campaign rule are set to 0%.

### Enhancements

- Adds ablity to disable the preloading of paywalls from specific triggers via config.

---

## 2.5.4

### Fixes

- Fixes a crash issue where the completion blocks for triggering a paywall were being called on a background thread in a specific scenario.
- Fixes an issue where lazy properties were causing an occasional crash due to the use of multithreading.

---

## 2.5.3

### Fixes

- Fixes a bug where `Paywall.reset()` couldn't be called on a background thread.

---

## 2.5.2

### Fixes

- Fixed memory and time issues associated with the shimmer view when loading a paywall. Special thanks to Martin from Planta for spotting that one. We've rebuilt the shimmer view and only add it when the paywall is visible and loading. This means it doesn't get added to paywalls preloading in the background. After loading, we remove the shimmer view from memory.
- Moves internal operations for templating paywall variables from the main thread to a background thread. This prevents hangs on the main thread.
- Stops UIAlertViewControllers being unnecessarily created when loading a paywall.
- Removes the dependency on `TPInAppReceipt` from our podspec and replaces it with a `ASN1Swift` dependency to keep it in line with our Swift Package file.

---

## 2.5.0

### Enhancements

- Assigments of paywall variants are now performed on device, meaning reduced network calls and faster setup time for the SDK.
- Adds `Paywall.latestPaywallInfo`. You can read this to access the `PaywallInfo` object of the most recently presented view controller.
- Adds feature flags under the hood so new features can be turned on for specific organizations and apps.
- Adds the ability to specify `SKProducts` with triggers. These override products defined in the dashboard. You do this by creating a `PaywallProducts` object and calling `Paywall.trigger(event: "event", products: products)`.
- Updates sample projects to iOS 16.

### Fixes

- Shimmer view is no longer visible beneath a paywall's `WKWebView` when there is no `body` or `html` background color set
- Previously calls to `Paywall.preloadPaywalls(forTriggers:)` before `Paywall.config()` finished were ignored. This has been fixed.
- If a user had already bought a product within a subscription group, they were still being offered a free trial on other products within that group. This is incorrect logic and this update fixes that.
- # Fixed a bug where `Paywall.reset()` couldn't be called on a background thread.
- Previously, calling `Paywall.preloadPaywalls(forTriggers:)` before `Paywall.config()` finished would not work. This has been fixed.
- Previously, if a user purchases a product within a subscription group, they would still be offered a free trial on other products within that group. This has been fixed.
- Fixes a bug where `Paywall.reset()` couldn't be called on a background thread.

---

## 2.4.1

### Enhancements

- Adds `Paywall.preloadAllPaywalls()` and `Paywall.preloadPaywalls(forTriggers:)`. Use this with `Superwall.options.shouldPreloadPaywall = false` to have more control over when/what paywalls are preloaded.

### Fixes

- Paywall options specified prior to config are now respected, regardless of whether you pass an options object through to config or not.
- Ensures /config's request and response is always handled on the main thread

---

## 2.4.0

### Enhancements

- New _push_ presentation style. By selecting Push on the superwall dashboard, your paywall will push and pop in as if it's being pushed/popped from a navigation controller. If you are using UIKit, you can provide a view controller to `Paywall.trigger` like this: `Paywall.trigger(event: "MyEvent", on: self)`. This will make the push transition more realistic, by moving its view in the transition. Note: This is not backwards compatible with previous versions of the SDK.
- New _no animation_ presentation style. By selecting No Animation in the superwall dashboard, you can disable presentation/dismissal animation. This release deprecates `Paywall.shouldAnimatePaywallDismissal` and `Paywall.shouldAnimatePaywallPresentation`.
- A new `PaywallOptions` object that you configure and pass to `Paywall.configure(apiKey:userId:delegate:options) to override the default appearance and presentation of the paywall. This deprecates a lot of static variables for better organisation.
- New `shouldPreloadPaywalls` option. Set this to `false` to make paywalls load and cache in a just-in-time fashion. This replaces the old `Paywall.shouldPreloadTriggers` flag.
- New dedicated function for handling deeplinks: `Paywall.handleDeepLink(url)`.
- Deprecates old `track` functions. The only one you should use is `Superwall.track(_:_:)`, to which you pass an event name and a dictionary of parameters. Note: This is not backwards compatible with previous versions of the SDK.
- Adds a new way of internally tracking analytics associated with a paywall and the app session. This will greatly improve the Superwall dashboard analytics.
- Adds support for javascript expressions defined in rules on the Superwall dashboard.
- Updates the SDK documentation.
- Adds `trialPeriodEndDate` as a product variable. This means you can tell your users when their trial period will end, e.g. `Start your trial today — you won't be billed until {{primary.trialPeriodEndDate}}` will print out `Start your trial today — you won't be billed until June 21, 2023`.
- Adds support for having more than 3 products on your paywall.
- Exposes `Paywall.presentedViewController`. This gives you access to the `UIViewController` of the paywall incase you need to present a view controller on top of it.
- Adds `today`, `daysSinceInstall`, `minutesSinceInstall`, `daysSinceLastPaywallView`, `minutesSinceLastPaywallView` and `totalPaywallViews` as `device` parameters. These can be references in your rules and paywalls with `{{ device.paramName }}`.
- Paywalls can now be configured via the dashboard to always present, regardless of the subscription status of the user.
- Adds a `presentationStyleOverride` parameter to `Paywall.trigger()` and `Paywall.present()`. By setting this, you can override the configured presentation style on case by case basis.
- Rules can now be limited by occurrence and date. For example, you could set a rule to only match 10 times within the last 5 hours.
- Adds `Paywall.userId` to grab the id of the current user.
- Adds `$url`, `$path`, `$pathExtension`, `$lastPathComponent`, `$host`, `$query`, `$fragment` as standard parameters to the `deepLink_open` event trigger (automatically tracked).
- Parses URL parameters and adds them as trigger parameters to the `deepLink_open` event trigger (automatically tracked).
- Fixes window logic for opening the debugger and launching paywalls on `deepLink_open`.
- Launching a paywall using the `deepLink_open` Trigger now dismisses a currently presenting paywall before presenting the new one.

### Fixes

- Adds the missing Superwall events `app_install`, `paywallWebviewLoad_fail`, `paywallWebviewLoad_timeout` and `nonRecurringProduct_purchase`.
- Adds `trigger_name` to a `triggerFire` Superwall event, which can be accessed in the parameters sent back to the `trackAnalyticsEvent(name:params:)` delegate function.
- Product prices were being sent back to the dashboard with weird values like 89.999998. We fixed that.
- Modal presentation now uses `.pageSheet` instead of `.formSheet`. This results in a less compact paywall popover on iPad. Thanks to Daniel Yoo from the Daily Bible Inspirations app for spotting that!
- For SwiftUI users, we've fixed an issue where the explicitly triggered paywalls and presented paywalls would sometimes randomly dismiss. We found that state changes within the presenting view caused a rerendering of the view which temporarily reset the state of the binding that controlled the presentation of the paywall. This was causing the Paywall to dismiss.
- Fixes an issue where the wrong paywall was shown if a trigger was fired before the config was fetched from the server. Thanks to Zac from Blue Candy for help with finding that :)
- Future proofs enums internally to increase backwards compatibility.
- Fixes a bug where long term data was being stored in the cache directory. This update migrates that to the document directory. This means the data stays around until we tell it to delete, rather than the system deleting it at random.
- Prevents Paywall.configure from being called twice and logs a warning if this occurs.
- Prevents Paywall.configure from being called in the background.
- Fixes an issue where the keyboard couldn't be dismissed in the UIKit sample app.
- Mentions SwiftLint as a requirement to run the sample apps.
- Deprecates `Paywall.debugMode`. All logs are now controlled by setting the paywall option `.logLevel`. The default `logLevel` is now `.warn`.
- Fixes broken webview based deeplinks and closes the paywall view before calling the delegate handler.
- Deprecates `Paywall.present` for `Paywall.trigger`.
- Fixes issue where preloaded paywalls would be cleared upon calling `Paywall.identify()` if config was called without a `userId`.
- Fixes logic for grabbing the active view controller.

## 2.3.0

### Enhancements

- New [UIKit Example App](Examples/SuperwallUIKitExample).
- Better [SDK documentation](https://sdk.superwall.me/documentation/paywall/). This is built from the ground up using DocC which means you view it directly in Xcode by selecting **Product ▸ Build Documentation**.
- New Pull Request and Bug Report templates for the repo.
- Added a setup file that installs GitHooks as well as SwiftLint if you don't already have it. This is located at `scripts/setup.sh` and can be run from anywhere.
- Added a [CONTIBUTING.md](CONTRIBUTING.md) file for detailed instructions on how to get set up and contribute to the codebase.
- Added a [Code of Conduct](CODE_OF_CONDUCT.md) file to the repo.
- Added a CHANGELOG.md file.
- Removed the `TPInnAppReceipt` dependency for the SDK.

### Fixes

- All readme links for the UIKit example app now work.
- Adds an `experiment` parameter to `PaywallInfo`. This will be useful in the next version of Triggers, where you can see details about the experiment that triggered the presentation of the paywall.
- When triggering or presenting a paywall, if the default value for `isPresented` was `true`, the paywall would not present/trigger. It now works as expected.
