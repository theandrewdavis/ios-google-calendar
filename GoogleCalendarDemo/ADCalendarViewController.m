//
//  ADCalendarViewController.m
//  GoogleCalendarDemo
//
//  Created by Andrew Davis on 1/13/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "ADCalendarViewController.h"
#import "AFNetworking.h"
#import "ADManagedObjectContext.h"

@interface ADCalendarViewController ()
@property (strong, nonatomic) NSFetchedResultsController *eventResultsController;
@end

@implementation ADCalendarViewController

- (id)init {
    self = [super init];
    if (self) {
        self.coreDataDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // In iOS 7+, don't extend the table view underneath the navigation bar.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.navigationItem.title = @"Custom";
    [self setRefreshTarget:self action:@selector(updateCalendar)];
    [self beginRefreshing];

}

#pragma mark - Google Calendar updates

// Start an asynchronous fetch of calendar events. Shows a pull-down spinner while updating and shows an error notification in the spnner window if updating fails.
- (void)updateCalendar {
    NSString *apiKey = @"AIzaSyBNDX9ZvvrzcY75UEKuUpewPOwSn9BB5gs";
    NSString *baseUrl = @"https://www.googleapis.com/calendar/v3/calendars/uqug2vcr34i6ao749n5vfb8vks@group.calendar.google.com/events?key=";
    NSString *fullUrl = [baseUrl stringByAppendingString:apiKey];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:fullUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [ADManagedObjectContext updateEvents:responseObject[@"items"]];
        [self endRefreshingSuccess];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self endRefreshingError];
    }];
}

#pragma mark ADCoreDateTableDelegate

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath*)indexPath {
    NSManagedObject *event = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    cell.textLabel.text = [event valueForKey:@"summary"];
}

- (NSFetchedResultsController *)fetchedResultsController {
    static NSFetchedResultsController *fetchedResultsController;
    if (!fetchedResultsController) {
        fetchedResultsController = [ADManagedObjectContext createEventResultsController];
    }
    return fetchedResultsController;
}

@end
