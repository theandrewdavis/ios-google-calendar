//
//  ADRefreshTableViewController.m
//  GoogleCalendarDemo
//
//  Created by Andrew Davis on 1/12/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "ADRefreshTableViewController.h"

static CGFloat kRefreshControlMarginY = 8;
static CGFloat kRefreshControlIconSize = 32;
static CGFloat kRefreshControlAnimationTime = 0.3;
static CGFloat kRefreshControlAnimationDelay = 1.5;

@interface ADRefreshTableViewController ()
@property (strong, nonatomic) UIView *refreshView;
@property (nonatomic) CGFloat refreshViewHeight;
@property (strong, nonatomic) UILabel *refreshLabel;
@property (strong, nonatomic) UIImageView *refreshImageView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) ADRefreshState state;
@property (weak, nonatomic) id target;
@property (nonatomic) SEL action;
@end

@implementation ADRefreshTableViewController

// Set up the text, images, and state.
- (id)init {
    self = [super init];
    if (self) {
        self.state = ADRefreshStateHidden;
        self.noResultsText = @"No results found.";
        self.loadingStateText = @"Loading...";
        self.successStateText = @"Update complete";
        self.errorStateText = @"Update failed";
        self.successImage = [UIImage imageNamed:@"Checkmark"];
        self.errorImage = [UIImage imageNamed:@"Close"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create success and error image views.
    CGFloat refreshImageViewX = self.tableView.frame.size.width / 2 - kRefreshControlIconSize / 2;
    self.refreshImageView = [[UIImageView alloc] initWithFrame:CGRectMake(refreshImageViewX, kRefreshControlMarginY, kRefreshControlIconSize, kRefreshControlIconSize)];
    self.refreshImageView.hidden = YES;

    // Create activity indicator.
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.frame = self.refreshImageView.frame;

    // Create text label.
    self.refreshLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.refreshLabel.text = self.loadingStateText;
    self.refreshLabel.font = [UIFont systemFontOfSize:12];
    self.refreshLabel.textColor = [UIColor grayColor];
    self.refreshLabel.textAlignment = NSTextAlignmentCenter;
    CGFloat refreshLabelY = self.refreshImageView.frame.origin.y + self.refreshImageView.frame.size.height + kRefreshControlMarginY / 2;
    CGFloat refreshLabelHeight = [self.refreshLabel.text sizeWithFont:self.refreshLabel.font constrainedToSize:self.tableView.frame.size].height;
    self.refreshLabel.frame = CGRectMake(0, refreshLabelY, self.tableView.frame.size.width, refreshLabelHeight);

    // Create refresh control view.
    self.refreshViewHeight = refreshLabelY + refreshLabelHeight + kRefreshControlMarginY;
    self.refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.refreshViewHeight)];
    [self.refreshView addSubview:self.activityIndicator];
    [self.refreshView addSubview:self.refreshImageView];
    [self.refreshView addSubview:self.refreshLabel];
    self.refreshView.hidden = YES;

    // Add the "No results" label and the refresh control view to the table background.
    self.tableView.backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
    [self.tableView.backgroundView addSubview:self.refreshView];
}

// Trigger a refresh when the table is pulled to reveal the refresh header.
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y <= -self.refreshViewHeight && self.state == ADRefreshStateHidden) {
        [self beginRefreshing];
    }
}

#pragma mark -
#pragma mark Customization

- (void)setRefreshTarget:(id)target action:(SEL)action {
    self.target = target;
    self.action = action;
}

#pragma mark -
#pragma mark Control state

- (void)beginRefreshing {
    [self transitionToState:ADRefreshStateLoading];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.action withObject:nil];
#pragma clang diagnostic pop
}

- (void)endRefreshingSuccess {
    [self transitionToState:ADRefreshStateSuccess];
}

- (void)endRefreshingError {
    [self transitionToState:ADRefreshStateError];
}

// Slide the refresh control to the given height by manipulating the table's contentInset.
- (void)animateTableViewInsetToHeight:(CGFloat)height completion:(void (^)(BOOL finished))completion {
    [UIView animateWithDuration:kRefreshControlAnimationTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(height, 0, 0, 0);
    } completion:completion];
}

- (void)transitionToState:(ADRefreshState)state {
    self.state = state;
    switch (state) {
        case ADRefreshStateHidden: {
            self.refreshView.hidden = YES;
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = NO;
            self.refreshImageView.hidden = YES;
            [self animateTableViewInsetToHeight:0 completion:nil];
            break;
        }
        case ADRefreshStateLoading: {
            self.refreshLabel.text = self.loadingStateText;
            [self.activityIndicator startAnimating];
            self.activityIndicator.hidden = NO;
            self.refreshImageView.hidden = YES;
            self.refreshView.hidden = NO;
            [self animateTableViewInsetToHeight:self.refreshViewHeight completion:nil];
            break;
        }
        case ADRefreshStateSuccess:
        case ADRefreshStateError: {
            self.refreshLabel.text = (state == ADRefreshStateSuccess) ? self.successStateText : self.errorStateText;
            self.refreshImageView.image = (state == ADRefreshStateSuccess) ? self.successImage : self.errorImage;
            self.refreshImageView.hidden = NO;
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = YES;
            self.refreshView.hidden = NO;
            [self animateTableViewInsetToHeight:self.refreshViewHeight completion:nil];

            // Briefly display the success or error message then hide the refresh control with animation. Using the UIView
            // method animateWithDuration:delay:options:animations:completion: to cause the delay instead of dispatch_after
            // seems to interfere with the scroll inertia of the containing scroll view causing the message to stop in the
            // wrong place when the refresh control is pulled very far down the screen.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kRefreshControlAnimationDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                self.refreshView.hidden = YES;
                [self animateTableViewInsetToHeight:0 completion:^(BOOL finished) {
                    [self transitionToState:ADRefreshStateHidden];
                }];
            });
            break;
        }
    }
}

@end
