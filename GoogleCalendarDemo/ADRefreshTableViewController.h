//
//  ADRefreshTableViewController.h
//  GoogleCalendarDemo
//
//  Created by Andrew Davis on 1/12/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ADRefreshStateHidden = 0,
    ADRefreshStateLoading,
    ADRefreshStateSuccess,
    ADRefreshStateError
}  ADRefreshState;

@interface ADRefreshTableViewController : UITableViewController
@property (strong, nonatomic) UIImage *successImage;
@property (strong, nonatomic) UIImage *errorImage;

- (void)setText:(NSString *)text forRefreshState:(ADRefreshState)state;
- (void)setRefreshTarget:(id)target action:(SEL)action;
- (void)beginRefreshing;
- (void)endRefreshingSuccess;
- (void)endRefreshingError;
@end
