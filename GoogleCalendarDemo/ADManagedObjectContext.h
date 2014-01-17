//
//  ADManagedObjectContext.h
//  GoogleCalendarDemo
//
//  Created by Andrew Davis on 1/14/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADManagedObjectContext : NSObject

+ (NSManagedObjectContext *)sharedContext;
+ (void)updateEvents:(NSArray *)newEvents;
+ (NSFetchedResultsController *)eventResultsController;

@end
