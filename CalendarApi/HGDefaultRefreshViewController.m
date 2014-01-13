//
//  HGDefaultRefreshViewController.m
//  CalendarApi
//
//  Created by Andrew Davis on 1/12/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "HGDefaultRefreshViewController.h"
#import "AFNetworking.h"

static NSString *kDefaultRefreshCellIdentifier = @"HGDefaultRefreshViewControllerCellIdentifier";

@interface HGDefaultRefreshViewController ()
@property (strong, nonatomic) NSArray *events;
@end

@implementation HGDefaultRefreshViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // In iOS 7+, don't extend the table view underneath the navigation bar.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.navigationItem.title = @"Default";
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(updateCalendar) forControlEvents:UIControlEventValueChanged];

}

// Programmatically call the "pull to refresh" control. Only appears to work in the viewDidAppear method.
// See http://stackoverflow.com/questions/17930730/uirefreshcontrol-on-viewdidload
- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    // Programmatically call the "pull to refresh" control.
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:NO];
    [self.refreshControl beginRefreshing];
    [self updateCalendar];
}

- (void)updateCalendar {
    NSString *apiKey = @"AIzaSyBNDX9ZvvrzcY75UEKuUpewPOwSn9BB5gs";
    NSString *baseUrl = @"https://www.googleapis.com/calendar/v3/calendars/uqug2vcr34i6ao749n5vfb8vks@group.calendar.google.com/events?key=";
    NSString *fullUrl = [baseUrl stringByAppendingString:apiKey];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:fullUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self updateSuccess:responseObject];
        [self.refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.refreshControl endRefreshing];
    }];
}

- (void)updateSuccess:(NSDictionary *)apiResponse {
    self.events = [apiResponse[@"items"] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id event, NSDictionary *bindings) {
        return ((NSString *)event[@"summary"]).length > 0 && ![((NSString *)event[@"status"]) isEqualToString:@"cancelled"];
    }]];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.events) ? self.events.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDefaultRefreshCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDefaultRefreshCellIdentifier];
    }
    cell.textLabel.text = self.events[indexPath.row][@"summary"];
    
    return cell;
}

@end
