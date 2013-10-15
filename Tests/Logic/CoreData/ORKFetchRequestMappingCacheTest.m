//
//  ORKFetchRequestMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 3/20/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "ORKCat.h"
#import "ORKEvent.h"

@interface ORKFetchRequestMappingCacheTest : ORKTestCase

@end

@implementation ORKFetchRequestMappingCacheTest

- (void)testFetchRequestMappingCacheReturnsObjectsWithNumericPrimaryKey
{
    // ORKCat entity. Integer prinmary key.
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    ORKFetchRequestManagedObjectCache *cache = [ORKFetchRequestManagedObjectCache new];
    NSEntityDescription *entity = [ORKCat entityDescription];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:objectStore];
    mapping.primaryKeyAttribute = @"railsID";

    ORKCat *reginald = [ORKCat createInContext:objectStore.primaryManagedObjectContext];
    reginald.name = @"Reginald";
    reginald.railsID = [NSNumber numberWithInt:123456];
    [objectStore.primaryManagedObjectContext save:nil];

    NSManagedObject *cachedObject = [cache findInstanceOfEntity:entity
                                        withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                          value:[NSNumber numberWithInt:123456]
                                         inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(reginald)));
}

- (void)testFetchRequestMappingCacheReturnsObjectsWithStringPrimaryKey
{
    // ORKEvent entity. String primary key
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    ORKFetchRequestManagedObjectCache *cache = [ORKFetchRequestManagedObjectCache new];
    NSEntityDescription *entity = [ORKEvent entityDescription];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKEvent class] inManagedObjectStore:objectStore];
    mapping.primaryKeyAttribute = @"eventID";

    ORKEvent *birthday = [ORKEvent createInContext:objectStore.primaryManagedObjectContext];
    birthday.eventID = @"e-1234-a8-b12";
    [objectStore.primaryManagedObjectContext save:nil];

    NSManagedObject *cachedObject = [cache findInstanceOfEntity:entity
                                        withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                          value:@"e-1234-a8-b12"
                                         inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(birthday)));
}

@end
