//
//  ORKObjectManager+ORKTableController.m
//  RestKit
//
//  Created by Blake Watters on 2/23/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKObjectManager+ORKTableController.h"

#if TARGET_OS_IPHONE

#import "ORKTableController.h"
#import "ORKFetchedResultsTableController.h"

@implementation ORKObjectManager (ORKTableController)

- (ORKTableController *)tableControllerForTableViewController:(UITableViewController *)tableViewController
{
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:tableViewController];
    tableController.objectManager = self;
    return tableController;
}

- (ORKTableController *)tableControllerWithTableView:(UITableView *)tableView forViewController:(UIViewController *)viewController
{
    ORKTableController *tableController = [ORKTableController tableControllerWithTableView:tableView forViewController:viewController];
    tableController.objectManager = self;
    return tableController;
}

- (ORKFetchedResultsTableController *)fetchedResultsTableControllerForTableViewController:(UITableViewController *)tableViewController
{
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerForTableViewController:tableViewController];
    tableController.objectManager = self;
    return tableController;
}

- (ORKFetchedResultsTableController *)fetchedResultsTableControllerWithTableView:(UITableView *)tableView forViewController:(UIViewController *)viewController
{
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerWithTableView:tableView forViewController:viewController];
    return tableController;
}

@end

#endif
