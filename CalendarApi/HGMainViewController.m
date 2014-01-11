//
//  HGMainViewController.m
//  CalendarApi
//
//  Created by Andrew Davis on 1/7/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "HGMainViewController.h"
#import "AFNetworking.h"

static NSString *kMainViewCellIdentifier = @"HGMainViewControllerCell";

@interface HGMainViewController ()
@property (nonatomic, strong) NSArray *events;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@end

@implementation HGMainViewController

- (id)init
{
    self = [super init];
    if (self) {
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
    NSString *apiKey = @"AIzaSyBNDX9ZvvrzcY75UEKuUpewPOwSn9BB5gs";
    NSString *baseUrl = @"https://www.googleapis.com/calendar/v3/calendars/uqug2vcr34i6ao749n5vfb8vks@group.calendar.google.com/events?key=";
    NSString *fullUrl = [baseUrl stringByAppendingString:apiKey];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:fullUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self updateSuccess:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self updateFailure];
    }];
}

- (void)updateSuccess:(NSDictionary *)apiResponse
{
    self.events = [apiResponse[@"items"] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id event, NSDictionary *bindings) {
        return ((NSString *)event[@"summary"]).length > 0 && ![((NSString *)event[@"status"]) isEqualToString:@"cancelled"];
    }]];
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
    return (self.events) ? self.events.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMainViewCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMainViewCellIdentifier];
    }
    cell.textLabel.text = self.events[indexPath.row][@"summary"];

    return cell;
}

@end
