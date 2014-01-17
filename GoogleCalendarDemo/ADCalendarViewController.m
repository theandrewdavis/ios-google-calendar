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

- (void)viewDidLoad {
    [super viewDidLoad];

    // In iOS 7+, don't extend the table view underneath the navigation bar.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.navigationItem.title = @"Custom";

    self.eventResultsController = [ADManagedObjectContext eventResultsController];
    self.eventResultsController.delegate = self;
    [self.eventResultsController performFetch:nil];

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
        [self updateSuccess:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self endRefreshingError];
    }];
}

- (void)updateSuccess:(NSDictionary *)apiResponse
{
    NSArray *events = [apiResponse[@"items"] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id event, NSDictionary *bindings) {
        return ((NSString *)event[@"summary"]).length > 0 && ![((NSString *)event[@"status"]) isEqualToString:@"cancelled"];
    }]];
    NSLog(@"%@", events);
    [ADManagedObjectContext updateEvents:events];

    [self.tableView reloadData];
    [self endRefreshingSuccess];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.eventResultsController.sections objectAtIndex:section] numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath*)indexPath {
    cell.textLabel.text = [[self.eventResultsController objectAtIndexPath:indexPath] valueForKey:@"summary"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCustomRefreshCellIdentifier = @"ADCalendarViewControllerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCustomRefreshCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCustomRefreshCellIdentifier];
    }
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

@end
