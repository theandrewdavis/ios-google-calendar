//
//  ADManagedObjectContext.m
//  GoogleCalendarDemo
//
//  Created by Andrew Davis on 1/14/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "ADManagedObjectContext.h"

@implementation ADManagedObjectContext

// Get or create a managed object context.
+ (NSManagedObjectContext *)sharedContext {
    static NSManagedObjectContext *context;
    if (!context) {
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [context performBlockAndWait:^{
            NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
            NSString *applicationDocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSURL *persistentStoreUrl = [NSURL fileURLWithPath:[applicationDocumentsDirectory stringByAppendingPathComponent:@"store.sqlite"]];
            NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
            [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:persistentStoreUrl options:nil error:nil];
            context.persistentStoreCoordinator = persistentStoreCoordinator;
        }];
    }
    return context;
}

// Parse a dictionary of events and add new events to the Core Data store.
+ (void)updateEvents:(NSArray *)events {
    static NSDateFormatter *dayFormatter, *timeFormatter;
    if (!dayFormatter || !timeFormatter) {
        dayFormatter = [[NSDateFormatter alloc] init];
        dayFormatter.dateFormat = @"yyyy-MM-dd";
        timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    }

    NSManagedObjectContext *context = [ADManagedObjectContext sharedContext];
    [context performBlockAndWait:^{
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
            if (eventData[@"start"][@"date"]) {
                date = [dayFormatter dateFromString:eventData[@"start"][@"date"]];
            } else if (eventData[@"start"][@"dateTime"]) {
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
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date < %@", [self today]];
        NSArray *oldEvents = [context executeFetchRequest:fetchRequest error:nil];
        for (NSManagedObject *oldEvent in oldEvents) {
            [context deleteObject:oldEvent];
        }

        [context save:nil];
    }];
}

// Create a fetched results controller to get events that will occur in the next year.
+ (NSFetchedResultsController *)createEventResultsController {
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
    }

    // Get the date of today and one year from today.
    NSDate *today = [self today];
    NSDate *nextYear = [self yearFromDate:today];

    // The fetched results controller should show events in the next year sorted by date.
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
    request.predicate = [NSPredicate predicateWithFormat:@"(date >= %@) AND (date < %@)", today, nextYear];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES]];
    NSManagedObjectContext *context = [ADManagedObjectContext sharedContext];
    return [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:@"EventCache"];
}

// Get the beginning of today's date in GMT.
+ (NSDate *)today {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
    return [calendar dateFromComponents:components];
}

// Get a date in GMT by adding one year to the given date.
+ (NSDate *)yearFromDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    offsetComponents.year = 1;
    return [calendar dateByAddingComponents:offsetComponents toDate:date options:0];
}

@end
