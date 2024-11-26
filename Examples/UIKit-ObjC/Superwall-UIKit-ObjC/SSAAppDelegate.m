//
//  SSAAppDelegate.m
//  Superwall-UIKit-ObjC
//
//  Created by Nest 22, Inc. on 11/1/22.
//

#import "SSAAppDelegate.h"

// frameworks
@import SuperwallKit;

#pragma mark - Constants

/// Notification name for posting a change to the subscribe state.
NSNotificationName const SSAAppDelegateEntitlementStatusDidChange = @"SSAAppDelegateEntitlementStatusDidChange";

@interface SSAAppDelegate () <SWKSuperwallDelegate>

@end

@implementation SSAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Initialize the Superwall service.
  [Superwall configureWithApiKey:@"pk_e361c8a9662281f4249f2fa11d1a63854615fa80e15e7a4d"];
  [[Superwall sharedInstance] setDelegate:self];
  
  return YES;
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
  return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

#pragma mark - SuperwallDelegate

- (void)entitlementStatusDidChangeTo:(enum SWKEntitlementStatus)newValue {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:SSAAppDelegateEntitlementStatusDidChange object:self];
  });
}

@end
