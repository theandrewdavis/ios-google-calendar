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
#import "ADCalendarEventCell.h"

@interface ADCalendarViewController ()
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@end

@implementation ADCalendarViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // In iOS 7+, don't extend the table view underneath the navigation bar.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    // Add a navigation bar title.
    self.navigationItem.title = @"US Federal Holidays";

    // Set up an NSFetchedResultsController to respond to changes in Core Data storage.
    self.fetchedResultsController = [ADManagedObjectContext createEventResultsController];
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:nil];

    // Set up the refresh control and start a refresh action.
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(updateCalendar) forControlEvents:UIControlEventValueChanged];
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:NO];
    [self.refreshControl beginRefreshing];
    [self updateCalendar];
}

// Fetch calendar events. Show a pull-down spinner while updating.
- (void)updateCalendar {
    NSString *calendarId = @"47ou48fasc70l0758i9lh76sr8@group.calendar.google.com";
    NSString *apiKey = @"AIzaSyCAkVQVwMzmPHxbaLUAqvb6dYUwjKU5qnM";
    NSString *urlFormat = @"https://www.googleapis.com/calendar/v3/calendars/%@/events?key=%@&fields=items(id,start,summary,status)";
    NSString *calendarUrl = [NSString stringWithFormat:urlFormat, calendarId, apiKey];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:calendarUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [ADManagedObjectContext updateEvents:responseObject[@"items"]];
        [self.refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.refreshControl endRefreshing];
    }];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [(ADCalendarEventCell *)cell setSummary:[event valueForKey:@"summary"] andDate:[event valueForKey:@"date"]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ADCalendarViewControllerCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[ADCalendarEventCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
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
