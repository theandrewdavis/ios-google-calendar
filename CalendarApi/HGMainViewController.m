//
//  HGMainViewController.m
//  CalendarApi
//
//  Created by Andrew Davis on 1/7/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "HGMainViewController.h"
#import "AFNetworking.h"
#import "GTLCalendar.h"

static NSString *kMainViewCellIdentifier = @"HGMainViewControllerCell";

@interface HGMainViewController ()
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@end

@implementation HGMainViewController

- (id)init
{
    self = [super init];
    if (self) {
//        self.calendarService.APIKey = @"AIzaSyBNDX9ZvvrzcY75UEKuUpewPOwSn9BB5gs";
        
        // Set up the "pull to refresh" control.
        self.refreshControl = [[UIRefreshControl alloc] init];
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Updating calendar"];
        [self.refreshControl addTarget:self action:@selector(updateEntries) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Programmatically call the "pull to refresh" control.
    [self.refreshControl beginRefreshing];
    [self updateEntries];
}

#pragma mark - Google API calls

// Start an asynchronous fetch of calendar events. Shows a pull-down spinner while updating and shows an error notification in the spnner window if updating fails.
- (void)updateEntries
{
    GTLQueryCalendar *query = [GTLQueryCalendar queryForEventsListWithCalendarId:@"uqug2vcr34i6ao749n5vfb8vks@group.calendar.google.com"];
    [self.calendarService executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id events, NSError *error) {
        if (error == nil) {
            [self updateSuccess:events];
        } else {
            [self updateFailure];
        }
    }];
}

- (void)updateSuccess:(GTLCalendarEvents *)events
{
    NSLog(@"Update success!");
    self.events = events;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)updateFailure
{
    NSLog(@"Update failed!");
    [self.refreshControl endRefreshing];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"%d items!", self.events.items.count);
    return self.events.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMainViewCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMainViewCellIdentifier];
    }
    GTLCalendarEvent *event = (GTLCalendarEvent *)self.events.items[indexPath.row];
    cell.textLabel.text = event.summary;
//    NSLog(@"Property %@", event.descriptionProperty);

    return cell;
}

@end
