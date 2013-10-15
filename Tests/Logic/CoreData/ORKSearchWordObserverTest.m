//
//  ORKSearchWordObserverTest.m
//  RestKit
//
//  Created by Blake Watters on 7/26/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "ORKSearchWordObserver.h"
#import "ORKSearchable.h"

@interface ORKSearchWordObserverTest : ORKTestCase

@end

@implementation ORKSearchWordObserverTest

- (void)testInstantiateASearchWordObserverOnObjectStoreInit
{
    [ORKTestFactory managedObjectStore];
    assertThat([ORKSearchWordObserver sharedObserver], isNot(nil));
}

- (void)testTriggerSearchWordRegenerationForChagedSearchableValuesAtObjectContextSaveTime
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKSearchable *searchable = [ORKSearchable createEntity];
    searchable.title = @"This is the title of my new object";
    assertThat(searchable.searchWords, is(empty()));
    [store save:nil];
    assertThat(searchable.searchWords, isNot(empty()));
    assertThat(searchable.searchWords, hasCountOf(8));
}

@end
