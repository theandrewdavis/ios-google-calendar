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
@property (nonatomic, strong) UIView *errorTableHeader;
@property (nonatomic, strong) UIView *successTableHeader;
@property (nonatomic, strong) NSTimer *tableHeaderTimer;
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
        
        //
        self.errorTableHeader = [self createTableHeader:@"Error updating calendar" withImage:@"Close"];
        self.successTableHeader = [self createTableHeader:@"Calendar updated successfully" withImage:@"Checkmark"];
    }
    return self;
}

// Programmatically call the "pull to refresh" control. Only appears to work in the viewDidAppear method.
// See http://stackoverflow.com/questions/17930730/uirefreshcontrol-on-viewdidload
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];

    // Programmatically call the "pull to refresh" control.
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:NO];
    [self.refreshControl beginRefreshing];
    [self updateEntries];
}


#pragma mark - Custom table headers

- (UIView *)createTableHeader:(NSString *)text withImage:(NSString *)imageName
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 82)];
    
    // Add image subview.
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    imageView.center = CGPointMake(self.tableView.frame.size.width / 2, 40);
    imageView.image = [UIImage imageNamed:imageName];
    [view addSubview:imageView];
    
    // Add text subview.
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
    label.center = CGPointMake(self.tableView.frame.size.width / 2, 65);
    label.text = text;
    label.font = [UIFont systemFontOfSize:12];
    label.textColor = [UIColor grayColor];
    label.textAlignment = NSTextAlignmentCenter;
    [view addSubview:label];
    
    return view;
}

- (void)showTableHeader:(UIView *)tableHeaderView
{
    self.tableView.tableHeaderView = tableHeaderView;
    self.tableHeaderTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(hideTableHeader) userInfo:nil repeats:NO];
}

- (void)hideTableHeader
{
    [self.tableView beginUpdates];
    self.tableView.tableHeaderView = nil;
    [self.tableView endUpdates];
}

- (void)cancelTableHeader
{
    if (self.tableHeaderTimer) {
        [self.tableHeaderTimer invalidate];
    }
    self.tableView.tableHeaderView = nil;
}

#pragma mark - Google Calendar updates

// Start an asynchronous fetch of calendar events. Shows a pull-down spinner while updating and shows an error notification in the spnner window if updating fails.
- (void)updateEntries
{
//    [self cancelTableHeader];

    NSString *apiKey = @"AIzaSyBNDX9ZvvrzcY75UEKuUpewPOwSn9BB5gs";
//    NSString *apiKey = @"";
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
//    [self showTableHeader:self.successTableHeader];
}

- (void)updateFailure
{
    // Stop the "updating" spinner and show an error in the table header.
    [self.refreshControl endRefreshing];
//    [self showTableHeader:self.errorTableHeader];
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
