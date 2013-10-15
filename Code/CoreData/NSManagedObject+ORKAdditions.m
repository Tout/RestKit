//
//  NSManagedObject+ORKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "NSManagedObject+ORKAdditions.h"
#import "NSManagedObjectContext+ORKAdditions.h"

@implementation NSManagedObject (ORKAdditions)

- (ORKManagedObjectStore *)managedObjectStore
{
    return self.managedObjectContext.managedObjectStore;
}

@end
