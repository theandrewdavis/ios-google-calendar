//
//  HGAppDelegate.m
//  CalendarApi
//
//  Created by Andrew Davis on 1/6/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "HGAppDelegate.h"
#import "HGMainViewController.h"

@implementation HGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[HGMainViewController alloc] init]];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
