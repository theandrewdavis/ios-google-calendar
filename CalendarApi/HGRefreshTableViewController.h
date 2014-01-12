//
//  HGRefreshTableViewController.h
//  CalendarApi
//
//  Created by Andrew Davis on 1/12/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    HGRefreshStateHidden = 0,
    HGRefreshStateLoading,
    HGRefreshStateSuccess,
    HGRefreshStateError
}  HGRefreshState;

@interface HGRefreshTableViewController : UITableViewController
@property (strong, nonatomic) UIImage *successImage;
@property (strong, nonatomic) UIImage *errorImage;

- (void)text:(NSString *)text forRefreshState:(HGRefreshState)state;
- (void)setRefreshTarget:(id)target action:(SEL)action;
- (void)beginRefresh;
- (void)endRefreshSuccess;
- (void)endRefreshError;
@end
