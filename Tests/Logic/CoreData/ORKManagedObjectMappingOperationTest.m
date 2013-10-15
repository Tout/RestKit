//
//  ORKManagedObjectMappingOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ORKTestEnvironment.h"
#import "ORKManagedObjectMapping.h"
#import "ORKManagedObjectMappingOperation.h"
#import "ORKCat.h"
#import "ORKHuman.h"
#import "ORKChild.h"
#import "ORKParent.h"
#import "ORKBenchmark.h"

@interface ORKManagedObjectMappingOperationTest : ORKTestCase {

}

@end

@implementation ORKManagedObjectMappingOperationTest

- (void)testShouldOverloadInitializationOfORKObjectMappingOperationToReturnInstancesOfORKManagedObjectMappingOperationWhenAppropriate
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *managedMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    NSDictionary *sourceObject = [NSDictionary dictionary];
    ORKHuman *human = [ORKHuman createEntity];
    ORKObjectMappingOperation *operation = [ORKObjectMappingOperation mappingOperationFromObject:sourceObject toObject:human withMapping:managedMapping];
    assertThat(operation, is(instanceOf([ORKManagedObjectMappingOperation class])));
}

- (void)testShouldOverloadInitializationOfORKObjectMappingOperationButReturnUnmanagedMappingOperationWhenAppropriate
{
    ORKObjectMapping *vanillaMapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    NSDictionary *sourceObject = [NSDictionary dictionary];
    NSMutableDictionary *destinationObject = [NSMutableDictionary dictionary];
    ORKObjectMappingOperation *operation = [ORKObjectMappingOperation mappingOperationFromObject:sourceObject toObject:destinationObject withMapping:vanillaMapping];
    assertThat(operation, is(instanceOf([ORKObjectMappingOperation class])));
}

- (void)testShouldConnectRelationshipsByPrimaryKey
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];

    ORKManagedObjectMapping *catMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];

    // Create a cat to connect
    ORKCat *cat = [ORKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    ORKHuman *human = [ORKHuman object];
    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testConnectRelationshipsDoesNotLeakMemory
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];

    ORKManagedObjectMapping *catMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];

    // Create a cat to connect
    ORKCat *cat = [ORKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    ORKHuman *human = [ORKHuman object];
    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.queue = [ORKMappingOperationQueue new];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatInteger([operation retainCount], is(equalToInteger(1)));
}

- (void)testConnectionOfHasManyRelationshipsByPrimaryKey
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];

    ORKManagedObjectMapping *catMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];

    // Create a cat to connect
    ORKCat *cat = [ORKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    ORKHuman *human = [ORKHuman object];
    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyWithDifferentSourceAndDestinationKeyPaths
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];

    ORKManagedObjectMapping *catMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", @"catIDs", nil];
    [humanMapping mapRelationship:@"cats" withMapping:catMapping];
    [humanMapping connectRelationship:@"cats" withObjectForPrimaryKeyAttribute:@"catIDs"];

    // Create a couple of cats to connect
    ORKCat *asia = [ORKCat object];
    asia.name = @"Asia";
    asia.railsID = [NSNumber numberWithInt:31337];

    ORKCat *roy = [ORKCat object];
    roy.name = @"Reginald Royford Williams III";
    roy.railsID = [NSNumber numberWithInt:31338];

    [objectStore save:nil];

    NSArray *catIDs = [NSArray arrayWithObjects:[NSNumber numberWithInt:31337], [NSNumber numberWithInt:31338], nil];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"catIDs", catIDs, nil];
    ORKHuman *human = [ORKHuman object];

    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, isNot(nilValue()));
    assertThat([human.cats valueForKeyPath:@"name"], containsInAnyOrder(@"Asia", @"Reginald Royford Williams III", nil));
}

- (void)testShouldLoadNestedHasManyRelationship
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *catMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasMany:@"cats" withMapping:catMapping];

    NSArray *catsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Asia" forKey:@"name"]];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], @"cats", catsData, nil];
    ORKHuman *human = [ORKHuman object];
    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
}

- (void)testShouldLoadOrderedHasManyRelationship
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *catMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping mapKeyPath:@"cats" toRelationship:@"catsInOrderByAge" withMapping:catMapping];

    NSArray *catsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Asia" forKey:@"name"]];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], @"cats", catsData, nil];
    ORKHuman *human = [ORKHuman object];
    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat([human catsInOrderByAge], isNot(empty()));
}

- (void)testShouldMapNullToAHasManyRelationship
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *catMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:objectStore];
    [catMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasMany:@"cats" withMapping:catMapping];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"cats", [NSNull null], nil];
    ORKHuman *human = [ORKHuman object];
    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, is(empty()));
}

- (void)testShouldLoadNestedHasManyRelationshipWithoutABackingClass
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *cloudMapping = [ORKManagedObjectMapping mappingForEntityWithName:@"ORKCloud" inManagedObjectStore:objectStore];
    [cloudMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *stormMapping = [ORKManagedObjectMapping mappingForEntityWithName:@"ORKStorm" inManagedObjectStore:objectStore];
    [stormMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [stormMapping hasMany:@"clouds" withMapping:cloudMapping];

    NSArray *cloudsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Nimbus" forKey:@"name"]];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Hurricane", @"clouds", cloudsData, nil];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKStorm" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    NSManagedObject *storm = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:objectStore.primaryManagedObjectContext];
    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:storm mapping:stormMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
}

- (void)testShouldDynamicallyConnectRelationshipsByPrimaryKeyWhenMatchingSucceeds
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];

    ORKManagedObjectMapping *catMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID" whenValueOfKeyPath:@"name" isEqualTo:@"Blake"];

    // Create a cat to connect
    ORKCat *cat = [ORKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    ORKHuman *human = [ORKHuman object];
    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldNotDynamicallyConnectRelationshipsByPrimaryKeyWhenMatchingFails
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];

    ORKManagedObjectMapping *catMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID" whenValueOfKeyPath:@"name" isEqualTo:@"Jeff"];

    // Create a cat to connect
    ORKCat *cat = [ORKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    ORKHuman *human = [ORKHuman object];
    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, is(nilValue()));
}

- (void)testShouldConnectManyToManyRelationships
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *childMapping = [ORKManagedObjectMapping mappingForClass:[ORKChild class] inManagedObjectStore:store];
    childMapping.primaryKeyAttribute = @"railsID";
    [childMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *parentMapping = [ORKManagedObjectMapping mappingForClass:[ORKParent class] inManagedObjectStore:store];
    parentMapping.primaryKeyAttribute = @"railsID";
    [parentMapping mapAttributes:@"name", @"age", nil];
    [parentMapping hasMany:@"children" withMapping:childMapping];

    NSArray *childMappableData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithKeysAndObjects:@"name", @"Maya", nil],
                                  [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Brady", nil], nil];
    NSDictionary *parentMappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Win",
                                        @"age", [NSNumber numberWithInt:34],
                                        @"children", childMappableData, nil];
    ORKParent *parent = [ORKParent object];
    ORKManagedObjectMappingOperation *operation = [[ORKManagedObjectMappingOperation alloc] initWithSourceObject:parentMappableData destinationObject:parent mapping:parentMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(parent.children, isNot(nilValue()));
    assertThatUnsignedInteger([parent.children count], is(equalToInt(2)));
    assertThat([[parent.children anyObject] parents], isNot(nilValue()));
    assertThatBool([[[parent.children anyObject] parents] containsObject:parent], is(equalToBool(YES)));
    assertThatUnsignedInteger([[[parent.children anyObject] parents] count], is(equalToInt(1)));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyRegardlessOfOrder
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *parentMapping = [ORKManagedObjectMapping mappingForClass:[ORKParent class] inManagedObjectStore:store];
    [parentMapping mapAttributes:@"parentID", nil];
    parentMapping.primaryKeyAttribute = @"parentID";

    ORKManagedObjectMapping *childMapping = [ORKManagedObjectMapping mappingForClass:[ORKChild class] inManagedObjectStore:store];
    [childMapping mapAttributes:@"fatherID", nil];
    [childMapping mapRelationship:@"father" withMapping:parentMapping];
    [childMapping connectRelationship:@"father" withObjectForPrimaryKeyAttribute:@"fatherID"];

    ORKObjectMappingProvider *mappingProvider = [ORKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setMapping:parentMapping forKeyPath:@"parents"];
    [mappingProvider setMapping:childMapping  forKeyPath:@"children"];

    NSDictionary *JSON = [ORKTestFixture parsedObjectWithContentsOfFixture:@"ConnectingParents.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    ORKObjectMappingResult *result = [mapper performMapping];
    NSArray *children = [[result asDictionary] valueForKey:@"children"];
    assertThat(children, hasCountOf(1));
    ORKChild *child = [children lastObject];
    assertThat(child.father, is(notNilValue()));
}

- (void)testMappingAPayloadContainingRepeatedObjectsDoesNotYieldDuplicatesWithFetchRequestMappingCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    store.cacheStrategy = [ORKFetchRequestManagedObjectCache new];

    ORKManagedObjectMapping *childMapping = [ORKManagedObjectMapping mappingForClass:[ORKChild class] inManagedObjectStore:store];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    ORKManagedObjectMapping *parentMapping = [ORKManagedObjectMapping mappingForClass:[ORKParent class] inManagedObjectStore:store];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    ORKObjectMappingProvider *mappingProvider = [ORKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [ORKTestFixture parsedObjectWithContentsOfFixture:@"parents_and_children.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    [mapper performMapping];

    NSUInteger parentCount = [ORKParent count:nil];
    NSUInteger childrenCount = [ORKChild count:nil];
    assertThatInteger(parentCount, is(equalToInteger(2)));
    assertThatInteger(childrenCount, is(equalToInteger(4)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsDoesNotYieldDuplicatesWithInMemoryMappingCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    store.cacheStrategy = [ORKInMemoryManagedObjectCache new];

    ORKManagedObjectMapping *childMapping = [ORKManagedObjectMapping mappingForClass:[ORKChild class] inManagedObjectStore:store];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    ORKManagedObjectMapping *parentMapping = [ORKManagedObjectMapping mappingForClass:[ORKParent class] inManagedObjectStore:store];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    ORKObjectMappingProvider *mappingProvider = [ORKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [ORKTestFixture parsedObjectWithContentsOfFixture:@"parents_and_children.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    [mapper performMapping];

    NSUInteger parentCount = [ORKParent count:nil];
    NSUInteger childrenCount = [ORKChild count:nil];
    assertThatInteger(parentCount, is(equalToInteger(2)));
    assertThatInteger(childrenCount, is(equalToInteger(4)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsPerformsAcceptablyWithFetchRequestMappingCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    store.cacheStrategy = [ORKFetchRequestManagedObjectCache new];

    ORKManagedObjectMapping *childMapping = [ORKManagedObjectMapping mappingForClass:[ORKChild class] inManagedObjectStore:store];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    ORKManagedObjectMapping *parentMapping = [ORKManagedObjectMapping mappingForClass:[ORKParent class] inManagedObjectStore:store];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    ORKObjectMappingProvider *mappingProvider = [ORKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [ORKTestFixture parsedObjectWithContentsOfFixture:@"benchmark_parents_and_children.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];

    ORKLogConfigureByName("RestKit/ObjectMapping", ORKLogLevelOff);
    ORKLogConfigureByName("RestKit/CoreData", ORKLogLevelOff);

    [ORKBenchmark report:@"Mapping with Fetch Request Cache" executionBlock:^{
        for (NSUInteger i = 0; i < 50; i++) {
            [mapper performMapping];
        }
    }];
    NSUInteger parentCount = [ORKParent count:nil];
    NSUInteger childrenCount = [ORKChild count:nil];
    assertThatInteger(parentCount, is(equalToInteger(25)));
    assertThatInteger(childrenCount, is(equalToInteger(51)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsPerformsAcceptablyWithInMemoryMappingCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    store.cacheStrategy = [ORKInMemoryManagedObjectCache new];

    ORKManagedObjectMapping *childMapping = [ORKManagedObjectMapping mappingForClass:[ORKChild class] inManagedObjectStore:store];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    ORKManagedObjectMapping *parentMapping = [ORKManagedObjectMapping mappingForClass:[ORKParent class] inManagedObjectStore:store];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    ORKObjectMappingProvider *mappingProvider = [ORKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [ORKTestFixture parsedObjectWithContentsOfFixture:@"benchmark_parents_and_children.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];

    ORKLogConfigureByName("RestKit/ObjectMapping", ORKLogLevelOff);
    ORKLogConfigureByName("RestKit/CoreData", ORKLogLevelOff);

    [ORKBenchmark report:@"Mapping with In Memory Cache" executionBlock:^{
        for (NSUInteger i = 0; i < 50; i++) {
            [mapper performMapping];
        }
    }];
    NSUInteger parentCount = [ORKParent count:nil];
    NSUInteger childrenCount = [ORKChild count:nil];
    assertThatInteger(parentCount, is(equalToInteger(25)));
    assertThatInteger(childrenCount, is(equalToInteger(51)));
}

@end
