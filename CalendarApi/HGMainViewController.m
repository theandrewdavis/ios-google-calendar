//
//  HGMainViewController.m
//  CalendarApi
//
//  Created by Andrew Davis on 1/7/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "HGMainViewController.h"
#import "AFNetworking.h"
#import "HGDefaultRefreshViewController.h"

static NSString *kCustomRefreshCellIdentifier = @"HGMainViewControllerCell";

@interface HGMainViewController ()
@property (nonatomic, strong) NSArray *events;
@end

@implementation HGMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.events = @[@"Summary Number One", @"Summary Number Two", @"Summary Number Three"];
    
    // In iOS 7+, don't extend the table view underneath the navigation bar.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Create button for the next view in the navigation controller hierarchy.
    self.navigationItem.title = @"Custom";
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Default" style:UIBarButtonItemStylePlain target:self action:@selector(nextView)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    [self setRefreshTarget:self action:@selector(updateCalendar)];
    [self beginRefreshing];
}

- (void)nextView {
    [self.navigationController pushViewController:[[HGDefaultRefreshViewController alloc] init] animated:YES];
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
    self.events = [apiResponse[@"items"] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id event, NSDictionary *bindings) {
        return ((NSString *)event[@"summary"]).length > 0 && ![((NSString *)event[@"status"]) isEqualToString:@"cancelled"];
    }]];
    [self.tableView reloadData];
    [self endRefreshingSuccess];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.events) ? self.events.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCustomRefreshCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCustomRefreshCellIdentifier];
    }
    cell.textLabel.text = self.events[indexPath.row];

    return cell;
}

@end
