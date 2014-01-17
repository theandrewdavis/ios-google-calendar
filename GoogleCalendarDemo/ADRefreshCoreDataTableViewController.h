//
//  ADRefreshTableViewController.h
//  GoogleCalendarDemo
//
//  Created by Andrew Davis on 1/12/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ADCoreDataTableViewController.h"

typedef enum {
    ADRefreshStateHidden = 0,
    ADRefreshStateLoading,
    ADRefreshStateSuccess,
    ADRefreshStateError
}  ADRefreshState;

@interface ADRefreshCoreDataTableViewController : ADCoreDataTableViewController
@property (strong, nonatomic) NSString *noResultsText;
@property (strong, nonatomic) NSString *loadingStateText;
@property (strong, nonatomic) NSString *successStateText;
@property (strong, nonatomic) NSString *errorStateText;
@property (strong, nonatomic) UIImage *successImage;
@property (strong, nonatomic) UIImage *errorImage;

- (void)setRefreshTarget:(id)target action:(SEL)action;
- (void)beginRefreshing;
- (void)endRefreshingSuccess;
- (void)endRefreshingError;
@end
