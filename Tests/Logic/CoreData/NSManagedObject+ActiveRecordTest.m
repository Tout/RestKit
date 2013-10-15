//
//  NSManagedObject+ActiveRecordTest.m
//  RestKit
//
//  Created by Blake Watters on 3/22/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "NSEntityDescription+ORKAdditions.h"
#import "ORKHuman.h"

@interface NSManagedObject_ActiveRecordTest : SenTestCase

@end

@implementation NSManagedObject_ActiveRecordTest

- (void)testFindByPrimaryKey
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [ORKHuman entityDescription];
    entity.primaryKeyAttributeName = @"railsID";

    ORKHuman *human = [ORKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:12345];
    [store save:nil];

    ORKHuman *foundHuman = [ORKHuman findByPrimaryKey:[NSNumber numberWithInt:12345] inContext:store.primaryManagedObjectContext];
    assertThat(foundHuman, is(equalTo(human)));
}

- (void)testFindByPrimaryKeyInContext
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    NSManagedObjectContext *context = [[ORKTestFactory managedObjectStore] newManagedObjectContext];
    NSEntityDescription *entity = [ORKHuman entityDescription];
    entity.primaryKeyAttributeName = @"railsID";

    ORKHuman *human = [ORKHuman createInContext:context];
    human.railsID = [NSNumber numberWithInt:12345];
    [context save:nil];

    ORKHuman *foundHuman = [ORKHuman findByPrimaryKey:[NSNumber numberWithInt:12345] inContext:store.primaryManagedObjectContext];
    assertThat(foundHuman, is(nilValue()));

    foundHuman = [ORKHuman findByPrimaryKey:[NSNumber numberWithInt:12345] inContext:context];
    assertThat(foundHuman, is(equalTo(human)));
}

- (void)testFindByPrimaryKeyWithStringValueForNumericProperty
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [ORKHuman entityDescription];
    entity.primaryKeyAttributeName = @"railsID";

    ORKHuman *human = [ORKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:12345];
    [store save:nil];

    ORKHuman *foundHuman = [ORKHuman findByPrimaryKey:@"12345" inContext:store.primaryManagedObjectContext];
    assertThat(foundHuman, is(equalTo(human)));
}

@end
