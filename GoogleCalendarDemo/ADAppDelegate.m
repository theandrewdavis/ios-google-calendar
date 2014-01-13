//
//  ADAppDelegate.m
//  GoogleCalendarDemo
//
//  Created by Andrew Davis on 1/12/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "ADAppDelegate.h"
#import "ADCalendarViewController.h"

@implementation ADAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[ADCalendarViewController alloc] init]];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
