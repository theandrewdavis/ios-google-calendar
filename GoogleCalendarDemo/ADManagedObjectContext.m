//
//  ADManagedObjectContext.m
//  GoogleCalendarDemo
//
//  Created by Andrew Davis on 1/14/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "ADManagedObjectContext.h"

@implementation ADManagedObjectContext

+ (NSManagedObjectContext *)sharedContext {
    static NSManagedObjectContext *context;
    if (!context) {
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [context performBlockAndWait:^{
            NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
            NSString *applicationDocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSURL *persistentStoreUrl = [NSURL fileURLWithPath:[applicationDocumentsDirectory stringByAppendingPathComponent:@"store.sqlite"]];
            NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];

            NSError *error;
            [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:persistentStoreUrl options:nil error:&error];
            context.persistentStoreCoordinator = persistentStoreCoordinator;
        }];
    }
    return context;
}

+ (void)updateEvents:(NSArray *)newEvents {
    static NSDateFormatter *dayFormatter, *timeFormatter;
    if (!dayFormatter || !timeFormatter) {
        dayFormatter = [[NSDateFormatter alloc] init];
        dayFormatter.dateFormat = @"yyyy-mm-dd";
        timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.dateFormat = @"yyyy-mm-dd'T'HH:mm:ssZZZZZ";
    }

    NSManagedObjectContext *context = [ADManagedObjectContext sharedContext];
    [context performBlock:^{
        // Delete all existing events.
        NSArray *oldEvents = [context executeFetchRequest:[[NSFetchRequest alloc] initWithEntityName:@"Event"] error:nil];
        for (NSManagedObject *oldEvent in oldEvents) {
            [context deleteObject:oldEvent];
        }

        // Add all new events.
        for (NSDictionary *eventData in newEvents) {
            NSManagedObject *newEvent = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:context];
            [newEvent setValue:eventData[@"summary"] forKey:@"summary"];
            [newEvent setValue:eventData[@"id"] forKey:@"googleid"];
            if ([eventData[@"start"] objectForKey:@"date"]) {
                [newEvent setValue:[dayFormatter dateFromString:eventData[@"start"][@"date"]] forKey:@"date"];
            } else if ([eventData[@"start"] objectForKey:@"dateTime"]) {
                [newEvent setValue:[timeFormatter dateFromString:eventData[@"start"][@"dateTime"]] forKey:@"date"];
            }
        }
        [context save:nil];
    }];
}

// TODO: Adjust this to the current year starting today.
+ (NSFetchedResultsController *)eventResultsController {
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-mm-dd";
    }

    NSCalendar *calendar = [NSCalendar currentCalendar];
//    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
//    NSDate *today = [calendar dateFromComponents:components];

    NSDate *today = [[NSDate date] dateByAddingTimeInterval:-1 * 60 * 60 * 24 * 365];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    offsetComponents.year = 1;
    NSDate *nextYear = [calendar dateByAddingComponents:offsetComponents toDate:today options:0];
    NSLog(@"Dates between %@ and %@", today, nextYear);

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
    request.predicate = [NSPredicate predicateWithFormat:@"(date >= %@) AND (date < %@)", today, nextYear];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES]];
    NSManagedObjectContext *context = [ADManagedObjectContext sharedContext];
    return [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:@"EventCache"];
}

@end
