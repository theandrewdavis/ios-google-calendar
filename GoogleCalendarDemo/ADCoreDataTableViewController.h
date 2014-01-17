//
//  ADCoreDataViewController.h
//  GoogleCalendarDemo
//
//  Created by Andrew Davis on 1/16/14.
//  Copyright (c) 2014 Andrew Davis. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ADCoreDateTableDelegate <NSObject>
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath*)indexPath;
- (NSFetchedResultsController *)fetchedResultsController;
@end

@interface ADCoreDataTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>
@property (weak, nonatomic) id<ADCoreDateTableDelegate> coreDataDelegate;
@end
