//
//  NSManagedObjectContext+ORKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <objc/runtime.h>
#import "NSManagedObjectContext+ORKAdditions.h"

static char NSManagedObject_ORKManagedObjectStoreAssociatedKey;

@implementation NSManagedObjectContext (ORKAdditions)

- (ORKManagedObjectStore *)managedObjectStore
{
    return (ORKManagedObjectStore *)objc_getAssociatedObject(self, &NSManagedObject_ORKManagedObjectStoreAssociatedKey);
}

- (void)setManagedObjectStore:(ORKManagedObjectStore *)managedObjectStore
{
    objc_setAssociatedObject(self, &NSManagedObject_ORKManagedObjectStoreAssociatedKey, managedObjectStore, OBJC_ASSOCIATION_ASSIGN);
}

@end
