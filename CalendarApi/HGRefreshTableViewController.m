//
//  HGRefreshTableViewController.m
//  CalendarApi
//
//  Created by Andrew Davis on 1/12/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import "HGRefreshTableViewController.h"

static CGFloat kHeight = 82;
static CGFloat kIconSize = 32;
static CGFloat kAnimationTime = 0.3;
static CGFloat kAnimationDelay = 1.5;

@interface HGRefreshTableViewController ()
@property (strong, nonatomic) UIView *refreshView;
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSMutableDictionary *strings;
@property (nonatomic) HGRefreshState state;
@property (weak, nonatomic) id target;
@property (nonatomic) SEL action;
@end

@implementation HGRefreshTableViewController

// Set up the text, images, and state.
- (id)init {
    self = [super init];
    if (self) {
        self.state = HGRefreshStateHidden;
        self.strings = [[NSMutableDictionary alloc] init];
        [self text:@"Pull to refresh" forRefreshState:HGRefreshStateHidden];
        [self text:@"Loading..." forRefreshState:HGRefreshStateLoading];
        [self text:@"Update complete" forRefreshState:HGRefreshStateSuccess];
        [self text:@"Update failed" forRefreshState:HGRefreshStateError];
        self.successImage = [UIImage imageNamed:@"Checkmark"];
        self.errorImage = [UIImage imageNamed:@"Close"];
    }
    return self;
}

// TODO Get the default UIRefreshControl strings
- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create success and error image views.
    CGFloat imageY = kHeight / 2 - kIconSize / 2;
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kIconSize, kIconSize)];
    self.imageView.center = CGPointMake(self.tableView.frame.size.width / 2, imageY);
    self.imageView.hidden = YES;
    
    // Create activity indicator.
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.frame = CGRectMake(0, 0, kIconSize, kIconSize);
    self.activityIndicator.center = CGPointMake(self.tableView.frame.size.width / 2, imageY);
    
    // Create text label.
    NSString *labelText = [self textForRefreshState:HGRefreshStateHidden];
    UIFont *labelFont = [UIFont systemFontOfSize:12];
    CGFloat labelHeight = [labelText sizeWithFont:labelFont constrainedToSize:CGSizeMake(self.tableView.frame.size.width, kHeight)].height;
    CGFloat labelY = self.imageView.frame.origin.y + self.imageView.frame.size.height + labelHeight / 2;
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, labelY, self.tableView.frame.size.width, labelHeight)];
    self.label.text = labelText;
    self.label.font = labelFont;
    self.label.textColor = [UIColor grayColor];
    self.label.textAlignment = NSTextAlignmentCenter;
    
    // Create refresh control view.
    self.refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, -kHeight, self.tableView.frame.size.width, kHeight)];
    [self.refreshView addSubview:self.activityIndicator];
    [self.refreshView addSubview:self.imageView];
    [self.refreshView addSubview:self.label];
    [self.tableView addSubview:self.refreshView];
}

// Trigger a refresh when the table is pulled to reveal the refresh header.
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView.contentOffset.y <= -kHeight && self.state == HGRefreshStateHidden) {
        [self beginRefresh];
    }
}

#pragma mark -
#pragma mark Setup

- (void)setRefreshTarget:(id)target action:(SEL)action
{
    self.target = target;
    self.action = action;
}

-(void)text:(NSString *)text forRefreshState:(HGRefreshState)state
{
    self.strings[[NSNumber numberWithInt:state]] = text;
}

-(NSString *)textForRefreshState:(HGRefreshState)state
{
    return self.strings[[NSNumber numberWithInt:state]];
}

#pragma mark -
#pragma mark Control state

- (void)beginRefresh
{
    [self transitionToState:HGRefreshStateLoading];
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.action withObject:nil];
    #pragma clang diagnostic pop
}

- (void)endRefreshSuccess
{
    [self transitionToState:HGRefreshStateSuccess];
}

- (void)endRefreshError
{
    [self transitionToState:HGRefreshStateError];
}

// Slide the refresh control to the given height by manipulating the table's contentInset.
- (void)animateTableViewInsetToHeight:(CGFloat)height completion:(void (^)(BOOL finished))completion
{
    [UIView animateWithDuration:kAnimationTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(height, 0, 0, 0);
    } completion:completion];
}

- (void)transitionToState:(HGRefreshState)state
{
    self.state = state;
    self.label.text = [self textForRefreshState:state];
    switch (state) {
        case HGRefreshStateHidden: {
            self.tableView.contentInset = UIEdgeInsetsZero;
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = NO;
            self.imageView.hidden = YES;
            break;
        }
        case HGRefreshStateLoading: {
            [self.activityIndicator startAnimating];
            self.activityIndicator.hidden = NO;
            self.imageView.hidden = YES;
            [self animateTableViewInsetToHeight:kHeight completion:nil];
            break;
        }
        case HGRefreshStateSuccess:
        case HGRefreshStateError: {
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = YES;
            self.imageView.image = (state == HGRefreshStateSuccess) ? self.successImage : self.errorImage;
            self.imageView.hidden = NO;
            [self animateTableViewInsetToHeight:kHeight completion:nil];
            
            // Briefly display the success or error message then hide the refresh control with animation. Using the UIView
            // method animateWithDuration:delay:options:animations:completion: to cause the delay instead of dispatch_after
            // seems to interfere with the scroll inertia of the containing scroll view causing the message to stop in the
            // wrong place when the refresh control is pulled very far down the screen.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kAnimationDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self animateTableViewInsetToHeight:0 completion:^(BOOL finished) {
                    [self transitionToState:HGRefreshStateHidden];
                }];
            });
            break;
        }
    }
}

@end
