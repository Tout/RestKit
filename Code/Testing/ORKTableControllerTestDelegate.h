//
//  ORKTableControllerTestDelegate.h
//  RestKit
//
//  Created by Blake Watters on 5/23/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "ORKTableController.h"
#import "ORKFetchedResultsTableController.h"

@interface ORKAbstractTableControllerTestDelegate : NSObject <ORKAbstractTableControllerDelegate>

@property (nonatomic, readonly, getter = isCancelled) BOOL cancelled;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, assign) BOOL awaitingResponse;

+ (id)tableControllerDelegate;
- (void)waitForLoad;

@end

@interface ORKTableControllerTestDelegate : ORKAbstractTableControllerTestDelegate <ORKTableControllerDelegate>
@end

@interface ORKFetchedResultsTableControllerTestDelegate : ORKAbstractTableControllerTestDelegate <ORKFetchedResultsTableControllerDelegate>

@end

#endif
