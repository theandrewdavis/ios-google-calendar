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

// TODO: Fix today to actually be today.
+ (void)updateEvents:(NSArray *)events {
    static NSDateFormatter *dayFormatter, *timeFormatter;
    if (!dayFormatter || !timeFormatter) {
        dayFormatter = [[NSDateFormatter alloc] init];
        dayFormatter.dateFormat = @"yyyy-mm-dd";
        timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.dateFormat = @"yyyy-mm-dd'T'HH:mm:ssZZZZZ";
    }

    NSManagedObjectContext *context = [ADManagedObjectContext sharedContext];
    [context performBlock:^{
        // Add all new events.
        for (NSDictionary *eventData in events) {
            // Find an event if it is already stored or create it otherwise.
            NSManagedObject *event;
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"googleid == %@", eventData[@"id"]];
            NSArray *results = [context executeFetchRequest:fetchRequest error:nil];
            event = (results.count > 0) ? results[0] : [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:context];

            // Find the start date of the event.
            NSDate *date;
            if ([eventData[@"start"] objectForKey:@"date"]) {
                date = [dayFormatter dateFromString:eventData[@"start"][@"date"]];
            } else if ([eventData[@"start"] objectForKey:@"dateTime"]) {
                date = [timeFormatter dateFromString:eventData[@"start"][@"dateTime"]];
            }

            // Update event properties.
            [event setValue:eventData[@"id"] forKey:@"googleid"];
            [event setValue:eventData[@"summary"] forKey:@"summary"];
            [event setValue:date forKey:@"date"];

            // Delete cancelled events.
            if ([eventData[@"status"] isEqualToString:@"cancelled"]) {
                [context deleteObject:event];
            }
        }

        // Delete old events.
        NSDate *today = [[NSDate date] dateByAddingTimeInterval:-1 * 60 * 60 * 24 * 365];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date < %@", today];
        NSArray *oldEvents = [context executeFetchRequest:fetchRequest error:nil];
        for (NSManagedObject *oldEvent in oldEvents) {
            [context deleteObject:oldEvent];
        }

        [context save:nil];
    }];
}

// TODO: Adjust this to the current year starting today.
+ (NSFetchedResultsController *)createEventResultsController {
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
