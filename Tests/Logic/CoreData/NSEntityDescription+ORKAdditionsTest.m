//
//  NSEntityDescription+ORKAdditionsTest.m
//  RestKit
//
//  Created by Blake Watters on 3/22/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "NSEntityDescription+ORKAdditions.h"

@interface NSEntityDescription_ORKAdditionsTest : ORKTestCase

@end

@implementation NSEntityDescription_ORKAdditionsTest

- (void)testRetrievalOfPrimaryKeyFromXcdatamodel
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
}

- (void)testRetrievalOfUnconfiguredPrimaryKeyAttributeReturnsNil
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKHuman" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttribute, is(nilValue()));
}

- (void)testSettingPrimaryKeyAttributeNameProgramatically
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"houseID";
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"houseID")));
}

- (void)testSettingExistingPrimaryKeyAttributeNameProgramatically
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    entity.primaryKeyAttributeName = @"catID";
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"catID")));
}

- (void)testSettingPrimaryKeyAttributeCreatesCachedPredicate
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    assertThat([entity.predicateForPrimaryKeyAttribute predicateFormat], is(equalTo(@"railsID == $PRIMARY_KEY_VALUE")));
}

- (void)testThatPredicateForPrimaryKeyAttributeWithValueReturnsUsablePredicate
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    NSNumber *primaryKeyValue = [NSNumber numberWithInt:12345];
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:primaryKeyValue];
    assertThat([predicate predicateFormat], is(equalTo(@"railsID == 12345")));
}

- (void)testThatPredicateForPrimaryKeyAttributeCastsStringValueToNumber
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:@"12345"];
    assertThat([predicate predicateFormat], is(equalTo(@"railsID == 12345")));
}

- (void)testThatPredicateForPrimaryKeyAttributeCastsNumberToString
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"city";
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:[NSNumber numberWithInteger:12345]];
    assertThat([predicate predicateFormat], is(equalTo(@"city == \"12345\"")));
}

- (void)testThatPredicateForPrimaryKeyAttributeReturnsNilForEntityWithoutPrimaryKey
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = nil;
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:@"12345"];
    assertThat([predicate predicateFormat], is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeReturnsNilIfNotSet
{
    NSEntityDescription *entity = [NSEntityDescription new];
    assertThat(entity.primaryKeyAttribute, is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeReturnsNilWhenSetToInvalidAttributeName
{
    NSEntityDescription *entity = [NSEntityDescription new];
    entity.primaryKeyAttributeName = @"invalidName!";
    assertThat(entity.primaryKeyAttribute, is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeForValidAttributeName
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"railsID";
    NSAttributeDescription *attribute = entity.primaryKeyAttribute;
    assertThat(attribute, is(notNilValue()));
    assertThat(attribute.name, is(equalTo(@"railsID")));
    assertThat(attribute.attributeValueClassName, is(equalTo(@"NSNumber")));
}

- (void)testRetrievalOfPrimaryKeyAttributeClassReturnsNilIfNotSet
{
    NSEntityDescription *entity = [NSEntityDescription new];
    assertThat([entity primaryKeyAttributeClass], is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeClassReturnsNilWhenSetToInvalidAttributeName
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"invalid";
    assertThat([entity primaryKeyAttributeClass], is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeClassForValidAttributeName
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ORKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"railsID";
    assertThat([entity primaryKeyAttributeClass], is(equalTo([NSNumber class])));
}

@end
