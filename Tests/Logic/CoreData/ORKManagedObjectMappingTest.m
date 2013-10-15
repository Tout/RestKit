//
//  ORKManagedObjectMappingTest.m
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
#import "ORKHuman.h"
#import "ORKMappableObject.h"
#import "ORKChild.h"
#import "ORKParent.h"
#import "NSEntityDescription+ORKAdditions.h"

@interface ORKManagedObjectMappingTest : ORKTestCase

@end

@implementation ORKManagedObjectMappingTest

- (void)setUp
{
    [ORKTestFactory setUp];
}

- (void)tearDown
{
    [ORKTestFactory tearDown];
}

- (void)testShouldReturnTheDefaultValueForACoreDataAttribute
{
    // Load Core Data
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];

    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForEntityWithName:@"ORKCat" inManagedObjectStore:store];
    id value = [mapping defaultValueForMissingAttribute:@"name"];
    assertThat(value, is(equalTo(@"Kitty Cat!")));
}

- (void)testShouldCreateNewInstancesOfUnmanagedObjects
{
    [ORKTestFactory managedObjectStore];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKMappableObject class]];
    id object = [mapping mappableObjectForData:[NSDictionary dictionary]];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([ORKMappableObject class])));
}

- (void)testShouldCreateNewInstancesOfManagedObjectsWhenTheMappingIsAnORKObjectMapping
{
    [ORKTestFactory managedObjectStore];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKMappableObject class]];
    id object = [mapping mappableObjectForData:[NSDictionary dictionary]];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([ORKMappableObject class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyInTheData
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    mapping.primaryKeyAttribute = @"railsID";

    NSDictionary *data = [NSDictionary dictionary];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([ORKHuman class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyAttribute
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];

    NSDictionary *data = [NSDictionary dictionary];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([ORKHuman class])));
}

- (void)testShouldCreateANewManagedObjectWhenThePrimaryKeyValueIsNSNull
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];

    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"id"];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([ORKHuman class])));
}

- (void)testShouldMapACollectionOfObjectsWithDynamicKeys
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    mapping.forceCollectionMapping = YES;
    mapping.primaryKeyAttribute = @"name";
    [mapping mapKeyOfNestedDictionaryToAttribute:@"name"];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"(name).id" toKeyPath:@"railsID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"users"];

    id mockCacheStrategy = [OCMockObject partialMockForObject:objectStore.cacheStrategy];
    [[[mockCacheStrategy expect] andForwardToRealObject] findInstanceOfEntity:OCMOCK_ANY
                                                      withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                                        value:@"blake"
                                                       inManagedObjectContext:objectStore.primaryManagedObjectContext];
    [[[mockCacheStrategy expect] andForwardToRealObject] findInstanceOfEntity:mapping.entity
                                                      withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                                        value:@"rachit"
                                                       inManagedObjectContext:objectStore.primaryManagedObjectContext];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeys.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [mapper performMapping];
    [mockCacheStrategy verify];
}

- (void)testShouldPickTheAppropriateMappingBasedOnAnAttributeValue
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    ORKManagedObjectMapping *childMapping = [ORKManagedObjectMapping mappingForClass:[ORKChild class] inManagedObjectStore:objectStore];
    childMapping.primaryKeyAttribute = @"railsID";
    [childMapping mapAttributes:@"name", nil];

    ORKManagedObjectMapping *parentMapping = [ORKManagedObjectMapping mappingForClass:[ORKParent class] inManagedObjectStore:objectStore];
    parentMapping.primaryKeyAttribute = @"railsID";
    [parentMapping mapAttributes:@"name", @"age", nil];

    [dynamicMapping setObjectMapping:parentMapping whenValueOfKeyPath:@"type" isEqualTo:@"Parent"];
    [dynamicMapping setObjectMapping:childMapping whenValueOfKeyPath:@"type" isEqualTo:@"Child"];

    ORKObjectMapping *mapping = [dynamicMapping objectMappingForDictionary:[ORKTestFixture parsedObjectWithContentsOfFixture:@"parent.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThatBool([mapping isKindOfClass:[ORKManagedObjectMapping class]], is(equalToBool(YES)));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"ORKParent")));
    mapping = [dynamicMapping objectMappingForDictionary:[ORKTestFixture parsedObjectWithContentsOfFixture:@"child.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThatBool([mapping isKindOfClass:[ORKManagedObjectMapping class]], is(equalToBool(YES)));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"ORKChild")));
}

- (void)testShouldIncludeTransformableAttributesInPropertyNamesAndTypes
{
    [ORKTestFactory managedObjectStore];
    NSDictionary *attributesByName = [[ORKHuman entity] attributesByName];
    NSDictionary *propertiesByName = [[ORKHuman entity] propertiesByName];
    NSDictionary *relationshipsByName = [[ORKHuman entity] relationshipsByName];
    assertThat([attributesByName objectForKey:@"favoriteColors"], is(notNilValue()));
    assertThat([propertiesByName objectForKey:@"favoriteColors"], is(notNilValue()));
    assertThat([relationshipsByName objectForKey:@"favoriteColors"], is(nilValue()));

    NSDictionary *propertyNamesAndTypes = [[ORKObjectPropertyInspector sharedInspector] propertyNamesAndTypesForEntity:[ORKHuman entity]];
    assertThat([propertyNamesAndTypes objectForKey:@"favoriteColors"], is(notNilValue()));
}

- (void)testThatAssigningAnEntityWithANonNilPrimaryKeyAttributeSetsTheDefaultValueForTheMapping
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKCat" inManagedObjectContext:store.primaryManagedObjectContext];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForEntity:entity inManagedObjectStore:store];
    assertThat(mapping.primaryKeyAttribute, is(equalTo(@"railsID")));
}

- (void)testThatAssigningAPrimaryKeyAttributeToAMappingWhoseEntityHasANilPrimaryKeyAttributeAssignsItToTheEntity
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKCloud" inManagedObjectContext:store.primaryManagedObjectContext];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForEntity:entity inManagedObjectStore:store];
    assertThat(mapping.primaryKeyAttribute, is(nilValue()));
    mapping.primaryKeyAttribute = @"name";
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"name")));
    assertThat(entity.primaryKeyAttribute, is(notNilValue()));
}

#pragma mark - Fetched Results Cache

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyWithFetchedResultsCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    store.cacheStrategy = [ORKFetchRequestManagedObjectCache new];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];

    ORKHuman *human = [ORKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [store save:nil];
    assertThatBool([ORKHuman hasAtLeastOneEntity], is(equalToBool(YES)));

    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithFetchedResultsCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    store.cacheStrategy = [ORKFetchRequestManagedObjectCache new];
    [ORKHuman truncateAll];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];

    [ORKHuman truncateAll];
    ORKHuman *human = [ORKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [store save:nil];
    assertThatBool([ORKHuman hasAtLeastOneEntity], is(equalToBool(YES)));

    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    id object = [mapping mappableObjectForData:nestedDictionary];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

#pragma mark - In Memory Cache

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyWithInMemoryCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    [ORKHuman truncateAllInContext:store.primaryManagedObjectContext];
    store.cacheStrategy = [ORKInMemoryManagedObjectCache new];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];

    ORKHuman *human = [ORKHuman createInContext:store.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [store save:nil];
    assertThatBool([ORKHuman hasAtLeastOneEntity], is(equalToBool(YES)));

    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSManagedObject *object = [mapping mappableObjectForData:data];
    assertThat([object managedObjectContext], is(equalTo(store.primaryManagedObjectContext)));
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithInMemoryCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    [ORKHuman truncateAllInContext:store.primaryManagedObjectContext];
    store.cacheStrategy = [ORKInMemoryManagedObjectCache new];
    [ORKHuman truncateAll];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];

    [ORKHuman truncateAll];
    ORKHuman *human = [ORKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [store save:nil];
    assertThatBool([ORKHuman hasAtLeastOneEntity], is(equalToBool(YES)));

    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    id object = [mapping mappableObjectForData:nestedDictionary];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testMappingWithFetchRequestCacheWherePrimaryKeyAttributeOfMappingDisagreesWithEntity
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    store.cacheStrategy = [ORKFetchRequestManagedObjectCache new];
    [ORKHuman truncateAll];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    mapping.primaryKeyAttribute = @"name";
    [ORKHuman entity].primaryKeyAttributeName = @"railsID";
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];

    [ORKHuman truncateAll];
    ORKHuman *human = [ORKHuman object];
    human.name = @"Testing";
    [store save:nil];
    assertThatBool([ORKHuman hasAtLeastOneEntity], is(equalToBool(YES)));

    NSDictionary *data = [NSDictionary dictionaryWithObject:@"Testing" forKey:@"name"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    id object = [mapping mappableObjectForData:nestedDictionary];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));

    id cachedObject = [store.cacheStrategy findInstanceOfEntity:[ORKHuman entity] withPrimaryKeyAttribute:@"name" value:@"Testing" inManagedObjectContext:store.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(human)));
}

- (void)testMappingWithInMemoryCacheWherePrimaryKeyAttributeOfMappingDisagreesWithEntity
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    store.cacheStrategy = [ORKInMemoryManagedObjectCache new];
    [ORKHuman truncateAll];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    mapping.primaryKeyAttribute = @"name";
    [ORKHuman entity].primaryKeyAttributeName = @"railsID";
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];

    [ORKHuman truncateAll];
    ORKHuman *human = [ORKHuman object];
    human.name = @"Testing";
    [store save:nil];
    assertThatBool([ORKHuman hasAtLeastOneEntity], is(equalToBool(YES)));

    NSDictionary *data = [NSDictionary dictionaryWithObject:@"Testing" forKey:@"name"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    id object = [mapping mappableObjectForData:nestedDictionary];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));

    id cachedObject = [store.cacheStrategy findInstanceOfEntity:[ORKHuman entity] withPrimaryKeyAttribute:@"name" value:@"Testing" inManagedObjectContext:store.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(human)));
}

- (void)testThatCreationOfNewObjectWithIncorrectTypeValueForPrimaryKeyAddsToCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    store.cacheStrategy = [ORKInMemoryManagedObjectCache new];
    [ORKHuman truncateAll];
    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    mapping.primaryKeyAttribute = @"railsID";
    [ORKHuman entity].primaryKeyAttributeName = @"railsID";
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    [mapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"monkey.railsID" toKeyPath:@"railsID"]];

    [ORKHuman truncateAll];
    ORKHuman *human = [ORKHuman object];
    human.name = @"Testing";
    human.railsID = [NSNumber numberWithInteger:12345];
    [store save:nil];
    assertThatBool([ORKHuman hasAtLeastOneEntity], is(equalToBool(YES)));

    NSDictionary *data = [NSDictionary dictionaryWithObject:@"12345" forKey:@"railsID"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    ORKHuman *object = [mapping mappableObjectForData:nestedDictionary];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
    assertThatInteger([object.railsID integerValue], is(equalToInteger(12345)));
}

@end
