//
//  ORKTableControllerTestDelegate.m
//  RestKit
//
//  Created by Blake Watters on 5/23/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "ORKTableControllerTestDelegate.h"
#import "ORKLog.h"

#if TARGET_OS_IPHONE

@implementation ORKAbstractTableControllerTestDelegate

@synthesize timeout = _timeout;
@synthesize awaitingResponse = _awaitingResponse;
@synthesize cancelled = _cancelled;

+ (id)tableControllerDelegate
{
    return [[self new] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        _timeout = 1.0;
        _awaitingResponse = NO;
        _cancelled = NO;
    }

    return self;
}

- (void)waitForLoad
{
    _awaitingResponse = YES;
    NSDate *startDate = [NSDate date];

    while (_awaitingResponse) {
        ORKLogTrace(@"Awaiting response = %d", _awaitingResponse);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        if ([[NSDate date] timeIntervalSinceDate:startDate] > self.timeout) {
            NSLog(@"%@: Timed out!!!", self);
            _awaitingResponse = NO;
            [NSException raise:nil format:@"*** Operation timed out after %f seconds...", self.timeout];
        }
    }
}

#pragma ORKTableControllerDelegate methods

- (void)tableControllerDidFinishLoad:(ORKAbstractTableController *)tableController
{
    _awaitingResponse = NO;
}

- (void)tableController:(ORKAbstractTableController *)tableController didFailLoadWithError:(NSError *)error
{
    _awaitingResponse = NO;
}

- (void)tableControllerDidCancelLoad:(ORKAbstractTableController *)tableController
{
    _awaitingResponse = NO;
    _cancelled = YES;
}

- (void)tableControllerDidFinalizeLoad:(ORKAbstractTableController *)tableController
{
    _awaitingResponse = NO;
}

// NOTE - Delegate methods below are implemented to allow trampoline through
// OCMock expectations

- (void)tableControllerDidStartLoad:(ORKAbstractTableController *)tableController
{}

- (void)tableControllerDidBecomeEmpty:(ORKAbstractTableController *)tableController
{}

- (void)tableController:(ORKAbstractTableController *)tableController willLoadTableWithObjectLoader:(ORKObjectLoader *)objectLoader
{}

- (void)tableController:(ORKAbstractTableController *)tableController didLoadTableWithObjectLoader:(ORKObjectLoader *)objectLoader
{}

- (void)tableController:(ORKAbstractTableController *)tableController willBeginEditing:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(ORKAbstractTableController *)tableController didEndEditing:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(ORKAbstractTableController *)tableController didInsertSection:(ORKTableSection *)section atIndex:(NSUInteger)sectionIndex
{}

- (void)tableController:(ORKAbstractTableController *)tableController didRemoveSection:(ORKTableSection *)section atIndex:(NSUInteger)sectionIndex
{}

- (void)tableController:(ORKAbstractTableController *)tableController didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(ORKAbstractTableController *)tableController didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(ORKAbstractTableController *)tableController didDeleteObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(ORKAbstractTableController *)tableController willAddSwipeView:(UIView *)swipeView toCell:(UITableViewCell *)cell forObject:(id)object
{}

- (void)tableController:(ORKAbstractTableController *)tableController willRemoveSwipeView:(UIView *)swipeView fromCell:(UITableViewCell *)cell forObject:(id)object
{}

- (void)tableController:(ORKTableController *)tableController didLoadObjects:(NSArray *)objects inSection:(NSUInteger)sectionIndex
{}

- (void)tableController:(ORKAbstractTableController *)tableController willDisplayCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(ORKAbstractTableController *)tableController didSelectCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

@end

@implementation ORKTableControllerTestDelegate

- (void)tableController:(ORKTableController *)tableController didLoadObjects:(NSArray *)objects inSection:(ORKTableSection *)section
{}

@end

@implementation ORKFetchedResultsTableControllerTestDelegate

- (void)tableController:(ORKFetchedResultsTableController *)tableController didInsertSectionAtIndex:(NSUInteger)sectionIndex
{}

- (void)tableController:(ORKFetchedResultsTableController *)tableController didDeleteSectionAtIndex:(NSUInteger)sectionIndex
{}

@end

#endif
