//
//  NSManagedObjectContext+ORKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ORKManagedObjectStore;

/**
 Provides extensions to NSManagedObjectContext for various common tasks.
 */
@interface NSManagedObjectContext (ORKAdditions)

/**
 The receiver's managed object store.
 */
@property (nonatomic, assign) ORKManagedObjectStore *managedObjectStore;

@end
