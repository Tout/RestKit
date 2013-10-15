//
//  ORKObjectMappingNextGenTest.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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

#import <OCMock/OCMock.h>
#import <OCMock/NSNotificationCenter+OCMAdditions.h>
#import "ORKTestEnvironment.h"
#import "ORKObjectMapping.h"
#import "ORKObjectMappingOperation.h"
#import "ORKObjectAttributeMapping.h"
#import "ORKObjectRelationshipMapping.h"
#import "ORKLog.h"
#import "ORKObjectMapper.h"
#import "ORKObjectMapper_Private.h"
#import "ORKObjectMapperError.h"
#import "ORKDynamicMappingModels.h"
#import "ORKTestAddress.h"
#import "ORKTestUser.h"
#import "ORKObjectMappingProvider+Contexts.h"

// Managed Object Serialization Testific
#import "ORKHuman.h"
#import "ORKCat.h"

@interface ORKExampleGroupWithUserArray : NSObject {
    NSString *_name;
    NSArray *_users;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSArray *users;

@end

@implementation ORKExampleGroupWithUserArray

@synthesize name = _name;
@synthesize users = _users;

+ (ORKExampleGroupWithUserArray *)group
{
    return [[self new] autorelease];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ORKExampleGroupWithUserArray class]]) {
        return [[(ORKExampleGroupWithUserArray *)object name] isEqualToString:self.name];
    } else {
        return NO;
    }
}

@end

@interface ORKExampleGroupWithUserSet : NSObject {
    NSString *_name;
    NSSet *_users;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *users;

@end

@implementation ORKExampleGroupWithUserSet

@synthesize name = _name;
@synthesize users = _users;

+ (ORKExampleGroupWithUserSet *)group
{
    return [[self new] autorelease];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ORKExampleGroupWithUserSet class]]) {
        return [[(ORKExampleGroupWithUserSet *)object name] isEqualToString:self.name];
    } else {
        return NO;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////

#pragma mark -

@interface ORKObjectMappingNextGenTest : ORKTestCase {

}

@end

@implementation ORKObjectMappingNextGenTest

#pragma mark - ORKObjectKeyPathMapping Tests

- (void)testShouldDefineElementToPropertyMapping
{
    ORKObjectAttributeMapping *elementMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    assertThat(elementMapping.sourceKeyPath, is(equalTo(@"id")));
    assertThat(elementMapping.destinationKeyPath, is(equalTo(@"userID")));
}

- (void)testShouldDescribeElementMappings
{
    ORKObjectAttributeMapping *elementMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    assertThat([elementMapping description], is(equalTo(@"ORKObjectKeyPathMapping: id => userID")));
}

#pragma mark - ORKObjectMapping Tests

- (void)testShouldDefineMappingFromAnElementToAProperty
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    assertThat([mapping mappingForKeyPath:@"id"], is(sameInstance(idMapping)));
}

- (void)testShouldAddMappingsToAttributeMappings
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    assertThatBool([mapping.mappings containsObject:idMapping], is(equalToBool(YES)));
    assertThatBool([mapping.attributeMappings containsObject:idMapping], is(equalToBool(YES)));
}

- (void)testShouldAddMappingsToRelationshipMappings
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectRelationshipMapping *idMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"id" toKeyPath:@"userID" withMapping:nil];
    [mapping addRelationshipMapping:idMapping];
    assertThatBool([mapping.mappings containsObject:idMapping], is(equalToBool(YES)));
    assertThatBool([mapping.relationshipMappings containsObject:idMapping], is(equalToBool(YES)));
}

- (void)testShouldGenerateAttributeMappings
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    assertThat([mapping mappingForKeyPath:@"name"], is(nilValue()));
    [mapping mapKeyPath:@"name" toAttribute:@"name"];
    assertThat([mapping mappingForKeyPath:@"name"], isNot(nilValue()));
}

- (void)testShouldGenerateRelationshipMappings
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMapping *anotherMapping = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    assertThat([mapping mappingForKeyPath:@"another"], is(nilValue()));
    [mapping mapRelationship:@"another" withMapping:anotherMapping];
    assertThat([mapping mappingForKeyPath:@"another"], isNot(nilValue()));
}

- (void)testShouldRemoveMappings
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    assertThat(mapping.mappings, hasItem(idMapping));
    [mapping removeMapping:idMapping];
    assertThat(mapping.mappings, isNot(hasItem(idMapping)));
}

- (void)testShouldRemoveMappingsByKeyPath
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    assertThat(mapping.mappings, hasItem(idMapping));
    [mapping removeMappingForKeyPath:@"id"];
    assertThat(mapping.mappings, isNot(hasItem(idMapping)));
}

- (void)testShouldRemoveAllMappings
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    [mapping mapAttributes:@"one", @"two", @"three", nil];
    assertThat(mapping.mappings, hasCountOf(3));
    [mapping removeAllMappings];
    assertThat(mapping.mappings, is(empty()));
}

- (void)testShouldGenerateAnInverseMappings
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    [mapping mapKeyPath:@"first_name" toAttribute:@"firstName"];
    [mapping mapAttributes:@"city", @"state", @"zip", nil];
    ORKObjectMapping *otherMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    [otherMapping mapAttributes:@"street", nil];
    [mapping mapRelationship:@"address" withMapping:otherMapping];
    ORKObjectMapping *inverse = [mapping inverseMapping];
    assertThat(inverse.objectClass, is(equalTo([NSMutableDictionary class])));
    assertThat([inverse mappingForKeyPath:@"firstName"], isNot(nilValue()));
}

- (void)testShouldLetYouRetrieveMappingsByAttribute
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *attributeMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"nameAttribute"];
    [mapping addAttributeMapping:attributeMapping];
    assertThat([mapping mappingForAttribute:@"nameAttribute"], is(equalTo(attributeMapping)));
}

- (void)testShouldLetYouRetrieveMappingsByRelationship
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectRelationshipMapping *relationshipMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"friend" toKeyPath:@"friendRelationship" withMapping:mapping];
    [mapping addRelationshipMapping:relationshipMapping];
    assertThat([mapping mappingForRelationship:@"friendRelationship"], is(equalTo(relationshipMapping)));
}

#pragma mark - ORKObjectMapper Tests

- (void)testShouldPerformBasicMapping
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    ORKObjectMapper *mapper = [ORKObjectMapper new];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:mapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThatInt([user.userID intValue], is(equalToInt(31337)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapACollectionOfSimpleObjectDictionaries
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    ORKObjectMapper *mapper = [ORKObjectMapper new];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    NSArray *users = [mapper mapCollection:userInfo atKeyPath:@"" usingMapping:mapping];
    assertThatUnsignedInteger([users count], is(equalToInt(3)));
    ORKTestUser *blake = [users objectAtIndex:0];
    assertThat(blake.name, is(equalTo(@"Blake Watters")));
    [mapper release];
}

- (void)testShouldDetermineTheObjectMappingByConsultingTheMappingProviderWhenThereIsATargetObject
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    mapper.targetObject = [ORKTestUser user];
    [mapper performMapping];

    [mockProvider verify];
}

- (void)testShouldAddAnErrorWhenTheKeyPathMappingAndObjectClassDoNotAgree
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    mapper.targetObject = [NSDictionary new];
    [mapper performMapping];
    assertThatUnsignedInteger([mapper errorCount], is(equalToInt(1)));
}

- (void)testShouldMapToATargetObject
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    ORKTestUser *user = [ORKTestUser user];
    mapper.targetObject = user;
    ORKObjectMappingResult *result = [mapper performMapping];

    [mockProvider verify];
    assertThat(result, isNot(nilValue()));
    assertThatBool([result asObject] == user, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldCreateANewInstanceOfTheAppropriateDestinationObjectWhenThereIsNoTargetObject
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    id mappingResult = [[mapper performMapping] asObject];
    assertThatBool([mappingResult isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
}

- (void)testShouldDetermineTheMappingClassForAKeyPathByConsultingTheMappingProviderWhenMappingADictionaryWithoutATargetObject
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    [[mockProvider expect] valueForContext:ORKObjectMappingProviderContextObjectsByKeyPath];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    [mapper performMapping];
    [mockProvider verify];
}

- (void)testShouldMapWithoutATargetMapping
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    ORKTestUser *user = [[mapper performMapping] asObject];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapACollectionOfObjects
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    ORKObjectMappingResult *result = [mapper performMapping];
    NSArray *users = [result asCollection];
    assertThatBool([users isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([users count], is(equalToInt(3)));
    ORKTestUser *user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapACollectionOfObjectsWithDynamicKeys
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    mapping.forceCollectionMapping = YES;
    [mapping mapKeyOfNestedDictionaryToAttribute:@"name"];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"(name).id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"users"];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeys.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    ORKObjectMappingResult *result = [mapper performMapping];
    NSArray *users = [result asCollection];
    assertThatBool([users isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([users count], is(equalToInt(2)));
    ORKTestUser *user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = [users objectAtIndex:1];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"rachit")));
}

- (void)testShouldMapACollectionOfObjectsWithDynamicKeysAndRelationships
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    mapping.forceCollectionMapping = YES;
    [mapping mapKeyOfNestedDictionaryToAttribute:@"name"];

    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    [addressMapping mapAttributes:@"city", @"state", nil];
    [mapping mapKeyPath:@"(name).address" toRelationship:@"address" withMapping:addressMapping];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"users"];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithRelationship.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    ORKObjectMappingResult *result = [mapper performMapping];
    NSArray *users = [result asCollection];
    assertThatBool([users isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([users count], is(equalToInt(2)));
    ORKTestUser *user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = [users objectAtIndex:1];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"rachit")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"New York")));
}

- (void)testShouldMapANestedArrayOfObjectsWithDynamicKeysAndArrayRelationships
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKExampleGroupWithUserArray class]];
    [mapping mapAttributes:@"name", nil];


    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    userMapping.forceCollectionMapping = YES;
    [userMapping mapKeyOfNestedDictionaryToAttribute:@"name"];
    [mapping mapKeyPath:@"users" toRelationship:@"users" withMapping:userMapping];

    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    [addressMapping mapAttributes:
        @"city", @"city",
        @"state", @"state",
        @"country", @"country",
        nil
     ];
    [userMapping mapKeyPath:@"(name).address" toRelationship:@"address" withMapping:addressMapping];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"groups"];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithNestedRelationship.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    ORKObjectMappingResult *result = [mapper performMapping];

    NSArray *groups = [result asCollection];
    assertThatBool([groups isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([groups count], is(equalToInt(2)));

    ORKExampleGroupWithUserArray *group = [groups objectAtIndex:0];
    assertThatBool([group isKindOfClass:[ORKExampleGroupWithUserArray class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"restkit")));
    NSArray *users = group.users;
    ORKTestUser *user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = [users objectAtIndex:1];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"rachit")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"New York")));

    group = [groups objectAtIndex:1];
    assertThatBool([group isKindOfClass:[ORKExampleGroupWithUserArray class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"others")));
    users = group.users;
    assertThatUnsignedInteger([users count], is(equalToInt(1)));
    user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"bjorn")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"Gothenburg")));
    assertThat(user.address.country, is(equalTo(@"Sweden")));
}

- (void)testShouldMapANestedArrayOfObjectsWithDynamicKeysAndSetRelationships
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKExampleGroupWithUserSet class]];
    [mapping mapAttributes:@"name", nil];


    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    userMapping.forceCollectionMapping = YES;
    [userMapping mapKeyOfNestedDictionaryToAttribute:@"name"];
    [mapping mapKeyPath:@"users" toRelationship:@"users" withMapping:userMapping];

    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    [addressMapping mapAttributes:
        @"city", @"city",
        @"state", @"state",
        @"country", @"country",
        nil
    ];
    [userMapping mapKeyPath:@"(name).address" toRelationship:@"address" withMapping:addressMapping];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"groups"];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithNestedRelationship.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    ORKObjectMappingResult *result = [mapper performMapping];

    NSArray *groups = [result asCollection];
    assertThatBool([groups isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([groups count], is(equalToInt(2)));

    ORKExampleGroupWithUserSet *group = [groups objectAtIndex:0];
    assertThatBool([group isKindOfClass:[ORKExampleGroupWithUserSet class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"restkit")));


    NSSortDescriptor *sortByName = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
    NSArray *descriptors = [NSArray arrayWithObject:sortByName];;
    NSArray *users = [group.users sortedArrayUsingDescriptors:descriptors];
    ORKTestUser *user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = [users objectAtIndex:1];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"rachit")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"New York")));

    group = [groups objectAtIndex:1];
    assertThatBool([group isKindOfClass:[ORKExampleGroupWithUserSet class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"others")));
    users = [group.users sortedArrayUsingDescriptors:descriptors];
    assertThatUnsignedInteger([users count], is(equalToInt(1)));
    user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[ORKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"bjorn")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"Gothenburg")));
    assertThat(user.address.country, is(equalTo(@"Sweden")));
}


- (void)testShouldBeAbleToMapFromAUserObjectToADictionary
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"userID" toKeyPath:@"id"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    ORKTestUser *user = [ORKTestUser user];
    user.name = @"Blake Watters";
    user.userID = [NSNumber numberWithInt:123];

    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:user mappingProvider:provider];
    ORKObjectMappingResult *result = [mapper performMapping];
    NSDictionary *userInfo = [result asObject];
    assertThatBool([userInfo isKindOfClass:[NSDictionary class]], is(equalToBool(YES)));
    assertThat([userInfo valueForKey:@"name"], is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapRegisteredSubKeyPathsOfAnUnmappableDictionaryAndReturnTheResults
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"user"];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"nested_user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    NSDictionary *dictionary = [[mapper performMapping] asDictionary];
    assertThatBool([dictionary isKindOfClass:[NSDictionary class]], is(equalToBool(YES)));
    ORKTestUser *user = [dictionary objectForKey:@"user"];
    assertThat(user, isNot(nilValue()));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

#pragma mark Mapping Error States

- (void)testShouldAddAnErrorWhenYouTryToMapAnArrayToATargetObject
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = [ORKTestUser user];
    [mapper performMapping];
    assertThatUnsignedInteger([mapper errorCount], is(equalToInt(1)));
    assertThatInteger([[mapper.errors objectAtIndex:0] code], is(equalToInt(ORKObjectMapperErrorObjectMappingTypeMismatch)));
}

- (void)testShouldAddAnErrorWhenAttemptingToMapADictionaryWithoutAnObjectMapping
{
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [mapper performMapping];
    assertThatUnsignedInteger([mapper errorCount], is(equalToInt(1)));
    assertThat([[mapper.errors objectAtIndex:0] localizedDescription], is(equalTo(@"Could not find an object mapping for keyPath: ''")));
}

- (void)testShouldAddAnErrorWhenAttemptingToMapACollectionWithoutAnObjectMapping
{
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [mapper performMapping];
    assertThatUnsignedInteger([mapper errorCount], is(equalToInt(1)));
    assertThat([[mapper.errors objectAtIndex:0] localizedDescription], is(equalTo(@"Could not find an object mapping for keyPath: ''")));
}

#pragma mark ORKObjectMapperDelegate Tests

- (void)testShouldInformTheDelegateWhenMappingBegins
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKObjectMapperDelegate)];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapperWillBeginMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenMappingEnds
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKObjectMapperDelegate)];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate stub] objectMapperWillBeginMapping:mapper];
    [[mockDelegate expect] objectMapperDidFinishMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsSuccessful
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKObjectMapperDelegate)];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper didFindMappableObject:[OCMArg any] atKeyPath:@""withMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsNotSuccessful
{
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    [provider setMapping:mapping forKeyPath:@"users"];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKObjectMapperDelegate)];
    [[mockDelegate expect] objectMapper:mapper didNotFindMappableObjectAtKeyPath:@"users"];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateOfError
{
    id mockProvider = [OCMockObject niceMockForClass:[ORKObjectMappingProvider class]];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKObjectMapperDelegate)];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    [[mockDelegate expect] objectMapper:mapper didAddError:[OCMArg isNotNil]];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldNotifyTheDelegateWhenItWillMapAnObject
{
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    [provider setMapping:mapping forKeyPath:@""];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKObjectMapperDelegate)];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper willMapFromObject:userInfo toObject:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldNotifyTheDelegateWhenItDidMapAnObject
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKObjectMapperDelegate)];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper didMapFromObject:userInfo toObject:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (BOOL)fakeValidateValue:(inout id *)ioValue forKeyPath:(NSString *)inKey error:(out NSError **)outError
{
    *outError = [NSError errorWithDomain:ORKErrorDomain code:1234 userInfo:nil];
    return NO;
}

- (void)testShouldNotifyTheDelegateWhenItFailedToMapAnObject
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKObjectMapperDelegate)];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:NSClassFromString(@"OCPartialMockObject")];
    [mapping mapAttributes:@"name", nil];
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    ORKTestUser *exampleUser = [[ORKTestUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:exampleUser];
    [[[mockObject expect] andCall:@selector(fakeValidateValue:forKeyPath:error:) onObject:self] validateValue:[OCMArg anyPointer] forKeyPath:OCMOCK_ANY error:[OCMArg anyPointer]];
    mapper.targetObject = mockObject;
    [[mockDelegate expect] objectMapper:mapper didFailMappingFromObject:userInfo toObject:[OCMArg any] withError:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockObject verify];
    [mockDelegate verify];
}

#pragma mark - ORKObjectMappingOperationTests

- (void)testShouldBeAbleToMapADictionaryToAUser
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:123], @"id", @"Blake Watters", @"name", nil];
    ORKTestUser *user = [ORKTestUser user];

    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    [operation performMapping:nil];
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThatInt([user.userID intValue], is(equalToInt(123)));
    [operation release];
}

- (void)testShouldConsiderADictionaryContainingOnlyNullValuesForKeysMappable
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"name", nil];
    ORKTestUser *user = [ORKTestUser user];

    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(nilValue()));
    [operation release];
}

- (void)testShouldBeAbleToMapAUserToADictionary
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"userID" toKeyPath:@"id"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    ORKTestUser *user = [ORKTestUser user];
    user.name = @"Blake Watters";
    user.userID = [NSNumber numberWithInt:123];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:user destinationObject:dictionary mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat([dictionary valueForKey:@"name"], is(equalTo(@"Blake Watters")));
    assertThatInt([[dictionary valueForKey:@"id"] intValue], is(equalToInt(123)));
    [operation release];
}

- (void)testShouldReturnNoWithoutErrorWhenGivenASourceObjectThatContainsNoMappableKeys
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
    ORKTestUser *user = [ORKTestUser user];

    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(NO)));
    assertThat(error, is(nilValue()));
    [operation release];
}

- (void)testShouldInformTheDelegateOfAnErrorWhenMappingFailsBecauseThereIsNoMappableContent
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKObjectMappingOperationDelegate)];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
    ORKTestUser *user = [ORKTestUser user];

    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    operation.delegate = mockDelegate;
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(NO)));
    [mockDelegate verify];
}

- (void)testShouldSetTheErrorWhenMappingOperationFails
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"FAILURE", @"id", nil];
    ORKTestUser *user = [ORKTestUser user];
    id mockObject = [OCMockObject partialMockForObject:user];
    [[[mockObject expect] andCall:@selector(fakeValidateValue:forKeyPath:error:) onObject:self] validateValue:[OCMArg anyPointer] forKeyPath:OCMOCK_ANY error:[OCMArg anyPointer]];

    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockObject mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];
    assertThat(error, isNot(nilValue()));
    [operation release];
}

#pragma mark - Attribute Mapping

- (void)testShouldMapAStringToADateAttribute
{
    [ORKObjectMapping setDefaultDateFormatters:nil];

    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *birthDateMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"birthdate" toKeyPath:@"birthDate"];
    [mapping addAttributeMapping:birthDateMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    assertThat([dateFormatter stringFromDate:user.birthDate], is(equalTo(@"11/27/1982")));
}

- (void)testShouldMapStringToURL
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *websiteMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"website" toKeyPath:@"website"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.website, isNot(nilValue()));
    assertThatBool([user.website isKindOfClass:[NSURL class]], is(equalToBool(YES)));
    assertThat([user.website absoluteString], is(equalTo(@"http://restkit.org/")));
}

- (void)testShouldMapAStringToANumberBool
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *websiteMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(YES)));
}

- (void)testShouldMapAShortTrueStringToANumberBool
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *websiteMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    ORKTestUser *user = [ORKTestUser user];
    [dictionary setValue:@"T" forKey:@"is_developer"];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(YES)));
}

- (void)testShouldMapAShortFalseStringToANumberBool
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *websiteMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    ORKTestUser *user = [ORKTestUser user];
    [dictionary setValue:@"f" forKey:@"is_developer"];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(NO)));
}

- (void)testShouldMapAYesStringToANumberBool
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *websiteMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    ORKTestUser *user = [ORKTestUser user];
    [dictionary setValue:@"yes" forKey:@"is_developer"];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(YES)));
}

- (void)testShouldMapANoStringToANumberBool
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *websiteMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    ORKTestUser *user = [ORKTestUser user];
    [dictionary setValue:@"NO" forKey:@"is_developer"];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(NO)));
}

- (void)testShouldMapAStringToANumber
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *websiteMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"lucky_number" toKeyPath:@"luckyNumber"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatInt([user.luckyNumber intValue], is(equalToInt(187)));
}

- (void)testShouldMapAStringToADecimalNumber
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *websiteMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"weight" toKeyPath:@"weight"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSDecimalNumber *weight = user.weight;
    assertThatBool([weight isKindOfClass:[NSDecimalNumber class]], is(equalToBool(YES)));
    assertThatInteger([weight compare:[NSDecimalNumber decimalNumberWithString:@"131.3"]], is(equalToInt(NSOrderedSame)));
}

- (void)testShouldMapANumberToAString
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *websiteMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"lucky_number" toKeyPath:@"name"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.name, is(equalTo(@"187")));
}

- (void)testShouldMapANumberToANSDecimalNumber
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *websiteMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"lucky_number" toKeyPath:@"weight"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSDecimalNumber *weight = user.weight;
    assertThatBool([weight isKindOfClass:[NSDecimalNumber class]], is(equalToBool(YES)));
    assertThatInteger([weight compare:[NSDecimalNumber decimalNumberWithString:@"187"]], is(equalToInt(NSOrderedSame)));
}

- (void)testShouldMapANumberToADate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *date = [dateFormatter dateFromString:@"11/27/1982"];

    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *birthDateMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"dateAsNumber" toKeyPath:@"birthDate"];
    [mapping addAttributeMapping:birthDateMapping];

    NSMutableDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNumber numberWithInt:[date timeIntervalSince1970]] forKey:@"dateAsNumber"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat([dateFormatter stringFromDate:user.birthDate], is(equalTo(@"11/27/1982")));
}

- (void)testShouldMapANestedKeyPathToAnAttribute
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *countryMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"address.country" toKeyPath:@"country"];
    [mapping addAttributeMapping:countryMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.country, is(equalTo(@"USA")));
}

- (void)testShouldMapANestedArrayOfStringsToAnAttribute
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *countryMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"interests" toKeyPath:@"interests"];
    [mapping addAttributeMapping:countryMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSArray *interests = [NSArray arrayWithObjects:@"Hacking", @"Running", nil];
    assertThat(user.interests, is(equalTo(interests)));
}

- (void)testShouldMapANestedDictionaryToAnAttribute
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *countryMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"address" toKeyPath:@"addressDictionary"];
    [mapping addAttributeMapping:countryMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSDictionary *address = [NSDictionary dictionaryWithKeysAndObjects:
                             @"city", @"Carrboro",
                             @"state", @"North Carolina",
                             @"id", [NSNumber numberWithInt:1234],
                             @"country", @"USA", nil];
    assertThat(user.addressDictionary, is(equalTo(address)));
}

- (void)testShouldNotSetAPropertyWhenTheValueIsTheSame
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:OCMOCK_ANY];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];
}

- (void)testShouldNotSetTheDestinationPropertyWhenBothAreNil
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    ORKTestUser *user = [ORKTestUser user];
    user.name = nil;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:OCMOCK_ANY];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];
}

- (void)testShouldSetNilForNSNullValues
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    ORKTestUser *user = [ORKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setName:nil];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)testDelegateIsInformedWhenANilValueIsMappedForNSNullWithExistingValue
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    ORKTestUser *user = [ORKTestUser user];
    user.name = @"Blake Watters";
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(ORKObjectMappingOperationDelegate)];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    operation.delegate = mockDelegate;
    NSError *error = nil;
    [[mockDelegate expect] objectMappingOperation:operation didFindMapping:nameMapping forKeyPath:@"name"];
    [[mockDelegate expect] objectMappingOperation:operation didSetValue:nil forKeyPath:@"name" usingMapping:nameMapping];
    [operation performMapping:&error];
    [mockDelegate verify];
}

- (void)testDelegateIsInformedWhenUnchangedValueIsSkipped
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:@"Blake Watters" forKey:@"name"];
    ORKTestUser *user = [ORKTestUser user];
    user.name = @"Blake Watters";
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(ORKObjectMappingOperationDelegate)];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    operation.delegate = mockDelegate;
    NSError *error = nil;
    [[mockDelegate expect] objectMappingOperation:operation didFindMapping:nameMapping forKeyPath:@"name"];
    [[mockDelegate expect] objectMappingOperation:operation didNotSetUnchangedValue:@"Blake Watters" forKeyPath:@"name" usingMapping:nameMapping];
    [operation performMapping:&error];
    [mockDelegate verify];
}

- (void)testShouldOptionallySetDefaultValueForAMissingKeyPath
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    ORKTestUser *user = [ORKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setName:nil];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    id mockMapping = [OCMockObject partialMockForObject:mapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetDefaultValueForMissingAttributes];
    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)testShouldOptionallyIgnoreAMissingSourceKeyPath
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    ORKTestUser *user = [ORKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:nil];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    id mockMapping = [OCMockObject partialMockForObject:mapping];
    BOOL returnValue = NO;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetDefaultValueForMissingAttributes];
    NSError *error = nil;
    [operation performMapping:&error];
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

#pragma mark - Relationship Mapping

- (void)testShouldMapANestedObject
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    ORKObjectAttributeMapping *cityMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addAttributeMapping:cityMapping];

    ORKObjectRelationshipMapping *hasOneMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];

    ORKObjectMapper *mapper = [ORKObjectMapper new];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.address, isNot(nilValue()));
}

- (void)testShouldMapANestedObjectToCollection
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    ORKObjectAttributeMapping *cityMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addAttributeMapping:cityMapping];

    ORKObjectRelationshipMapping *hasOneMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"friends" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];

    ORKObjectMapper *mapper = [ORKObjectMapper new];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friends, isNot(nilValue()));
    assertThatUnsignedInteger([user.friends count], is(equalToInt(1)));
}

- (void)testShouldMapANestedObjectToOrderedSetCollection
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    ORKObjectAttributeMapping *cityMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addAttributeMapping:cityMapping];

    ORKObjectRelationshipMapping *hasOneMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"friendsOrderedSet" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];

    ORKObjectMapper *mapper = [ORKObjectMapper new];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friendsOrderedSet, isNot(nilValue()));
    assertThatUnsignedInteger([user.friendsOrderedSet count], is(equalToInt(1)));
}

- (void)testShouldMapANestedObjectCollection
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];

    ORKObjectRelationshipMapping *hasManyMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];

    ORKObjectMapper *mapper = [ORKObjectMapper new];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friends, isNot(nilValue()));
    assertThatUnsignedInteger([user.friends count], is(equalToInt(2)));
    NSArray *names = [NSArray arrayWithObjects:@"Jeremy Ellison", @"Rachit Shukla", nil];
    assertThat([user.friends valueForKey:@"name"], is(equalTo(names)));
}

- (void)testShouldMapANestedArrayIntoASet
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];

    ORKObjectRelationshipMapping *hasManyMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friendsSet" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];

    ORKObjectMapper *mapper = [ORKObjectMapper new];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friendsSet, isNot(nilValue()));
    assertThatBool([user.friendsSet isKindOfClass:[NSSet class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([user.friendsSet count], is(equalToInt(2)));
    NSSet *names = [NSSet setWithObjects:@"Jeremy Ellison", @"Rachit Shukla", nil];
    assertThat([user.friendsSet valueForKey:@"name"], is(equalTo(names)));
}

- (void)testShouldMapANestedArrayIntoAnOrderedSet
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];

    ORKObjectRelationshipMapping *hasManyMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friendsOrderedSet" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];

    ORKObjectMapper *mapper = [ORKObjectMapper new];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friendsOrderedSet, isNot(nilValue()));
    assertThatBool([user.friendsOrderedSet isKindOfClass:[NSOrderedSet class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([user.friendsOrderedSet count], is(equalToInt(2)));
    NSOrderedSet *names = [NSOrderedSet orderedSetWithObjects:@"Jeremy Ellison", @"Rachit Shukla", nil];
    assertThat([user.friendsOrderedSet valueForKey:@"name"], is(equalTo(names)));
}

- (void)testShouldNotSetThePropertyWhenTheNestedObjectIsIdentical
{
    ORKTestUser *user = [ORKTestUser user];
    ORKTestAddress *address = [ORKTestAddress address];
    address.addressID = [NSNumber numberWithInt:1234];
    user.address = address;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setAddress:OCMOCK_ANY];

    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];

    ORKObjectRelationshipMapping *hasOneMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];

    ORKObjectMapper *mapper = [ORKObjectMapper new];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
}

- (void)testSkippingOfIdenticalObjectsInformsDelegate
{
    ORKTestUser *user = [ORKTestUser user];
    ORKTestAddress *address = [ORKTestAddress address];
    address.addressID = [NSNumber numberWithInt:1234];
    user.address = address;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setAddress:OCMOCK_ANY];

    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];

    ORKObjectRelationshipMapping *hasOneMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKObjectMappingOperation *operation = [ORKObjectMappingOperation mappingOperationFromObject:userInfo toObject:user withMapping:userMapping];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKObjectMappingOperationDelegate)];
    [[mockDelegate expect] objectMappingOperation:operation didNotSetUnchangedValue:address forKeyPath:@"address" usingMapping:hasOneMapping];
    operation.delegate = mockDelegate;
    [operation performMapping:nil];
    [mockDelegate verify];
}

- (void)testShouldNotSetThePropertyWhenTheNestedObjectCollectionIsIdentical
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:idMapping];
    [userMapping addAttributeMapping:nameMapping];

    ORKObjectRelationshipMapping *hasManyMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];

    ORKObjectMapper *mapper = [ORKObjectMapper new];
    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];

    // Set the friends up
    ORKTestUser *jeremy = [ORKTestUser user];
    jeremy.name = @"Jeremy Ellison";
    jeremy.userID = [NSNumber numberWithInt:187];
    ORKTestUser *rachit = [ORKTestUser user];
    rachit.name = @"Rachit Shukla";
    rachit.userID = [NSNumber numberWithInt:7];
    user.friends = [NSArray arrayWithObjects:jeremy, rachit, nil];

    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setFriends:OCMOCK_ANY];
    [mapper mapFromObject:userInfo toObject:mockUser atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    [mockUser verify];
}

- (void)testShouldOptionallyNilOutTheRelationshipIfItIsMissing
{
    ORKTestUser *user = [ORKTestUser user];
    ORKTestAddress *address = [ORKTestAddress address];
    address.addressID = [NSNumber numberWithInt:1234];
    user.address = address;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setAddress:nil];

    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];
    ORKObjectRelationshipMapping *relationshipMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:relationshipMapping];

    NSMutableDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"address"];
    id mockMapping = [OCMockObject partialMockForObject:userMapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] setNilForMissingRelationships];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser mapping:mockMapping];

    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)testShouldNotNilOutTheRelationshipIfItIsMissingAndCurrentlyNilOnTheTargetObject
{
    ORKTestUser *user = [ORKTestUser user];
    user.address = nil;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setAddress:nil];

    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *nameMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    ORKObjectAttributeMapping *idMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];
    ORKObjectRelationshipMapping *relationshipMapping = [ORKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:relationshipMapping];

    NSMutableDictionary *dictionary = [[ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"address"];
    id mockMapping = [OCMockObject partialMockForObject:userMapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] setNilForMissingRelationships];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser mapping:mockMapping];

    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

#pragma mark - ORKObjectMappingProvider

- (void)testShouldRegisterRailsIdiomaticObjects
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    [mapping mapAttributes:@"name", @"website", nil];
    [mapping mapKeyPath:@"id" toAttribute:@"userID"];

    [objectManager.router routeClass:[ORKTestUser class] toResourcePath:@"/humans/:userID"];
    [objectManager.router routeClass:[ORKTestUser class] toResourcePath:@"/humans" forMethod:ORKRequestMethodPOST];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    ORKTestUser *user = [ORKTestUser new];
    user.userID = [NSNumber numberWithInt:1];

    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    loader.timeout = 5;
    [objectManager getObject:user delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));

    [objectManager postObject:user delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"My Name")));
    assertThat(user.website, is(equalTo([NSURL URLWithString:@"http://restkit.org/"])));
}

- (void)testShouldReturnAllMappingsForAClass
{
    ORKObjectMapping *firstMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMapping *secondMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMapping *thirdMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMappingProvider *mappingProvider = [[ORKObjectMappingProvider new] autorelease];
    [mappingProvider addObjectMapping:firstMapping];
    [mappingProvider addObjectMapping:secondMapping];
    [mappingProvider setMapping:thirdMapping forKeyPath:@"third"];
    assertThat([mappingProvider objectMappingsForClass:[ORKTestUser class]], is(equalTo([NSArray arrayWithObjects:firstMapping, secondMapping, thirdMapping, nil])));
}

- (void)testShouldReturnAllMappingsForAClassAndNotExplodeWithRegisteredDynamicMappings
{
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    ORKObjectMapping *girlMapping = [ORKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];
    [provider setMapping:dynamicMapping forKeyPath:@"dynamic"];
    ORKObjectMapping *firstMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectMapping *secondMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    [provider addObjectMapping:firstMapping];
    [provider setMapping:secondMapping forKeyPath:@"second"];
    NSException *exception = nil;
    NSArray *actualMappings = nil;
    @try {
        actualMappings = [provider objectMappingsForClass:[ORKTestUser class]];
    }
    @catch (NSException *e) {
        exception = e;
    }
    assertThat(exception, is(nilValue()));
    assertThat(actualMappings, is(equalTo([NSArray arrayWithObjects:firstMapping, secondMapping, nil])));
}

#pragma mark - ORKDynamicObjectMapping

- (void)testShouldMapASingleObjectDynamically
{
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    ORKObjectMapping *girlMapping = [ORKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ ORKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            return girlMapping;
        }

        return nil;
    };

    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapASingleObjectDynamicallyWithADeclarativeMatcher
{
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    ORKObjectMapping *girlMapping = [ORKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];

    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldACollectionOfObjectsDynamically
{
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    ORKObjectMapping *girlMapping = [ORKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];

    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"mixed.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    NSArray *objects = [[mapper performMapping] asCollection];
    assertThat(objects, hasCountOf(2));
    assertThat([objects objectAtIndex:0], is(instanceOf([Boy class])));
    assertThat([objects objectAtIndex:1], is(instanceOf([Girl class])));
    Boy *boy = [objects objectAtIndex:0];
    Girl *girl = [objects objectAtIndex:1];
    assertThat(boy.name, is(equalTo(@"Blake Watters")));
    assertThat(girl.name, is(equalTo(@"Sarah")));
}

- (void)testShouldMapARelationshipDynamically
{
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    ORKObjectMapping *girlMapping = [ORKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];
    [boyMapping mapKeyPath:@"friends" toRelationship:@"friends" withMapping:dynamicMapping];

    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"friends.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy *blake = [[mapper performMapping] asObject];
    NSArray *friends = blake.friends;

    assertThat(friends, hasCountOf(2));
    assertThat([friends objectAtIndex:0], is(instanceOf([Boy class])));
    assertThat([friends objectAtIndex:1], is(instanceOf([Girl class])));
    Boy *boy = [friends objectAtIndex:0];
    Girl *girl = [friends objectAtIndex:1];
    assertThat(boy.name, is(equalTo(@"John Doe")));
    assertThat(girl.name, is(equalTo(@"Jane Doe")));
}

- (void)testShouldBeAbleToDeclineMappingAnObjectByReturningANilObjectMapping
{
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    ORKObjectMapping *girlMapping = [ORKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ ORKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            // NO GIRLS ALLOWED(*$!)(*
            return nil;
        }

        return nil;
    };

    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"mixed.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    NSArray *boys = [[mapper performMapping] asCollection];
    assertThat(boys, hasCountOf(1));
    Boy *user = [boys objectAtIndex:0];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldBeAbleToDeclineMappingObjectsInARelationshipByReturningANilObjectMapping
{
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    ORKObjectMapping *girlMapping = [ORKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ ORKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            // NO GIRLS ALLOWED(*$!)(*
            return nil;
        }

        return nil;
    };
    [boyMapping mapKeyPath:@"friends" toRelationship:@"friends" withMapping:dynamicMapping];

    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"friends.json"];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy *blake = [[mapper performMapping] asObject];
    assertThat(blake, is(notNilValue()));
    assertThat(blake.name, is(equalTo(@"Blake Watters")));
    assertThat(blake, is(instanceOf([Boy class])));
    NSArray *friends = blake.friends;

    assertThat(friends, hasCountOf(1));
    assertThat([friends objectAtIndex:0], is(instanceOf([Boy class])));
    Boy *boy = [friends objectAtIndex:0];
    assertThat(boy.name, is(equalTo(@"John Doe")));
}

- (void)testShouldMapATargetObjectWithADynamicMapping
{
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ ORKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        }

        return nil;
    };

    ORKObjectMappingProvider *provider = [ORKObjectMappingProvider objectMappingProvider];
    [provider setMapping:dynamicMapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    Boy *blake = [[Boy new] autorelease];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = blake;
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldBeBackwardsCompatibleWithTheOldClassName
{
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    ORKObjectDynamicMapping *dynamicMapping = (ORKObjectDynamicMapping *)[ORKObjectDynamicMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ ORKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        }

        return nil;
    };

    ORKObjectMappingProvider *provider = [ORKObjectMappingProvider objectMappingProvider];
    [provider setMapping:dynamicMapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    Boy *blake = [[Boy new] autorelease];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = blake;
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldFailWithAnErrorIfATargetObjectIsProvidedAndTheDynamicMappingReturnsNil
{
    ORKObjectMapping *boyMapping = [ORKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ ORKObjectMapping *(id mappableData) {
        return nil;
    };

    ORKObjectMappingProvider *provider = [ORKObjectMappingProvider objectMappingProvider];
    [provider setMapping:dynamicMapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    Boy *blake = [[Boy new] autorelease];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = blake;
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(nilValue()));
    assertThat(mapper.errors, hasCountOf(1));
}

- (void)testShouldFailWithAnErrorIfATargetObjectIsProvidedAndTheDynamicMappingReturnsTheIncorrectType
{
    ORKObjectMapping *girlMapping = [ORKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    ORKDynamicObjectMapping *dynamicMapping = [ORKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ ORKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            return girlMapping;
        }

        return nil;
    };

    ORKObjectMappingProvider *provider = [ORKObjectMappingProvider objectMappingProvider];
    [provider setMapping:dynamicMapping forKeyPath:@""];

    id userInfo = [ORKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"];
    Boy *blake = [[Boy new] autorelease];
    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = blake;
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(nilValue()));
    assertThat(mapper.errors, hasCountOf(1));
}

#pragma mark - Date and Time Formatting

- (void)testShouldAutoConfigureDefaultDateFormatters
{
    [ORKObjectMapping setDefaultDateFormatters:nil];
    NSArray *dateFormatters = [ORKObjectMapping defaultDateFormatters];
    assertThat(dateFormatters, hasCountOf(3));
    assertThat([[dateFormatters objectAtIndex:0] dateFormat], is(equalTo(@"yyyy-MM-dd'T'HH:mm:ss'Z'")));
    assertThat([[dateFormatters objectAtIndex:1] dateFormat], is(equalTo(@"MM/dd/yyyy")));
    NSTimeZone *UTCTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    assertThat([[dateFormatters objectAtIndex:0] timeZone], is(equalTo(UTCTimeZone)));
    assertThat([[dateFormatters objectAtIndex:1] timeZone], is(equalTo(UTCTimeZone)));
}

- (void)testShouldLetYouSetTheDefaultDateFormatters
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    NSArray *dateFormatters = [NSArray arrayWithObject:dateFormatter];
    [ORKObjectMapping setDefaultDateFormatters:dateFormatters];
    assertThat([ORKObjectMapping defaultDateFormatters], is(equalTo(dateFormatters)));
}

- (void)testShouldLetYouAppendADateFormatterToTheList
{
    [ORKObjectMapping setDefaultDateFormatters:nil];
    assertThat([ORKObjectMapping defaultDateFormatters], hasCountOf(3));
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [ORKObjectMapping addDefaultDateFormatter:dateFormatter];
    assertThat([ORKObjectMapping defaultDateFormatters], hasCountOf(4));
}

- (void)testShouldAllowNewlyAddedDateFormatterToRunFirst
{
    [ORKObjectMapping setDefaultDateFormatters:nil];
    NSDateFormatter *newDateFormatter = [[NSDateFormatter new] autorelease];
    [newDateFormatter setDateFormat:@"dd/MM/yyyy"];
    [ORKObjectMapping addDefaultDateFormatter:newDateFormatter];

    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *birthDateMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"favorite_date" toKeyPath:@"favoriteDate"];
    [mapping addAttributeMapping:birthDateMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];

    /*
     If ORKObjectMappingOperation is using the date formatter set above, we're
     going to get a really wonky date, which is what we are testing for.
     */
    assertThat([dateFormatter stringFromDate:user.favoriteDate], is(equalTo(@"01/03/2012")));
}

- (void)testShouldLetYouConfigureANewDateFormatterFromAStringAndATimeZone
{
    [ORKObjectMapping setDefaultDateFormatters:nil];
    assertThat([ORKObjectMapping defaultDateFormatters], hasCountOf(3));
    NSTimeZone *EDTTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"EDT"];
    [ORKObjectMapping addDefaultDateFormatterForString:@"mm/dd/YYYY" inTimeZone:EDTTimeZone];
    assertThat([ORKObjectMapping defaultDateFormatters], hasCountOf(4));
    NSDateFormatter *dateFormatter = [[ORKObjectMapping defaultDateFormatters] objectAtIndex:0];
    assertThat(dateFormatter.timeZone, is(equalTo(EDTTimeZone)));
}

- (void)testShouldReturnNilForEmptyDateValues
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    ORKObjectAttributeMapping *birthDateMapping = [ORKObjectAttributeMapping mappingFromKeyPath:@"birthdate" toKeyPath:@"birthDate"];
    [mapping addAttributeMapping:birthDateMapping];

    NSDictionary *dictionary = [ORKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
    [mutableDictionary setValue:@"" forKey:@"birthdate"];
    ORKTestUser *user = [ORKTestUser user];
    ORKObjectMappingOperation *operation = [[ORKObjectMappingOperation alloc] initWithSourceObject:mutableDictionary destinationObject:user mapping:mapping];
    [mutableDictionary release];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.birthDate, is(equalTo(nil)));
}

- (void)testShouldConfigureANewDateFormatterInTheUTCTimeZoneIfPassedANilTimeZone
{
    [ORKObjectMapping setDefaultDateFormatters:nil];
    assertThat([ORKObjectMapping defaultDateFormatters], hasCountOf(3));
    [ORKObjectMapping addDefaultDateFormatterForString:@"mm/dd/YYYY" inTimeZone:nil];
    assertThat([ORKObjectMapping defaultDateFormatters], hasCountOf(4));
    NSDateFormatter *dateFormatter = [[ORKObjectMapping defaultDateFormatters] objectAtIndex:0];
    NSTimeZone *UTCTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    assertThat(dateFormatter.timeZone, is(equalTo(UTCTimeZone)));
}

#pragma mark - Object Serialization
// TODO: Move to ORKObjectSerializerTest

- (void)testShouldSerializeHasOneRelatioshipsToJSON
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    [userMapping mapAttributes:@"name", nil];
    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    [addressMapping mapAttributes:@"city", @"state", nil];
    [userMapping hasOne:@"address" withMapping:addressMapping];

    ORKTestUser *user = [ORKTestUser new];
    user.name = @"Blake Watters";
    ORKTestAddress *address = [ORKTestAddress new];
    address.state = @"North Carolina";
    user.address = address;

    ORKObjectMapping *serializationMapping = [userMapping inverseMapping];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:user mapping:serializationMapping];
    NSError *error = nil;
    NSString *JSON = [serializer serializedObjectForMIMEType:ORKMIMETypeJSON error:&error];
    assertThat(error, is(nilValue()));
    assertThat(JSON, is(equalTo(@"{\"name\":\"Blake Watters\",\"address\":{\"state\":\"North Carolina\"}}")));
}

- (void)testShouldSerializeHasManyRelationshipsToJSON
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class]];
    [userMapping mapAttributes:@"name", nil];
    ORKObjectMapping *addressMapping = [ORKObjectMapping mappingForClass:[ORKTestAddress class]];
    [addressMapping mapAttributes:@"city", @"state", nil];
    [userMapping hasMany:@"friends" withMapping:addressMapping];

    ORKTestUser *user = [ORKTestUser new];
    user.name = @"Blake Watters";
    ORKTestAddress *address1 = [ORKTestAddress new];
    address1.city = @"Carrboro";
    ORKTestAddress *address2 = [ORKTestAddress new];
    address2.city = @"New York City";
    user.friends = [NSArray arrayWithObjects:address1, address2, nil];


    ORKObjectMapping *serializationMapping = [userMapping inverseMapping];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:user mapping:serializationMapping];
    NSError *error = nil;
    NSString *JSON = [serializer serializedObjectForMIMEType:ORKMIMETypeJSON error:&error];
    assertThat(error, is(nilValue()));
    assertThat(JSON, is(equalTo(@"{\"name\":\"Blake Watters\",\"friends\":[{\"city\":\"Carrboro\"},{\"city\":\"New York City\"}]}")));
}

- (void)testShouldSerializeManagedHasManyRelationshipsToJSON
{
    [ORKTestFactory managedObjectStore];
    ORKObjectMapping *humanMapping = [ORKObjectMapping mappingForClass:[ORKHuman class]];
    [humanMapping mapAttributes:@"name", nil];
    ORKObjectMapping *catMapping = [ORKObjectMapping mappingForClass:[ORKCat class]];
    [catMapping mapAttributes:@"name", nil];
    [humanMapping hasMany:@"cats" withMapping:catMapping];

    ORKHuman *blake = [ORKHuman object];
    blake.name = @"Blake Watters";
    ORKCat *asia = [ORKCat object];
    asia.name = @"Asia";
    ORKCat *roy = [ORKCat object];
    roy.name = @"Roy";
    blake.cats = [NSSet setWithObjects:asia, roy, nil];

    ORKObjectMapping *serializationMapping = [humanMapping inverseMapping];
    ORKObjectSerializer *serializer = [ORKObjectSerializer serializerWithObject:blake mapping:serializationMapping];
    NSError *error = nil;
    NSString *JSON = [serializer serializedObjectForMIMEType:ORKMIMETypeJSON error:&error];
    NSDictionary *parsedJSON = [JSON performSelector:@selector(objectFromJSONString)];
    assertThat(error, is(nilValue()));
    assertThat([parsedJSON valueForKey:@"name"], is(equalTo(@"Blake Watters")));
    NSArray *catNames = [[parsedJSON valueForKeyPath:@"cats.name"] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    assertThat(catNames, is(equalTo([NSArray arrayWithObjects:@"Asia", @"Roy", nil])));
}

- (void)testUpdatingArrayOfExistingCats
{
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    NSArray *array = [ORKTestFixture parsedObjectWithContentsOfFixture:@"ArrayOfHumans.json"];
    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:objectStore];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    humanMapping.primaryKeyAttribute = @"railsID";
    ORKObjectMappingProvider *provider = [ORKObjectMappingProvider mappingProvider];
    [provider setObjectMapping:humanMapping forKeyPath:@"human"];

    // Create instances that should match the fixture
    ORKHuman *human1 = [ORKHuman createInContext:objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInt:201];
    ORKHuman *human2 = [ORKHuman createInContext:objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInt:202];
    [objectStore save:nil];

    ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:array mappingProvider:provider];
    ORKObjectMappingResult *result = [mapper performMapping];
    assertThat(result, is(notNilValue()));

    NSArray *humans = [result asCollection];
    assertThat(humans, hasCountOf(2));
    assertThat([humans objectAtIndex:0], is(equalTo(human1)));
    assertThat([humans objectAtIndex:1], is(equalTo(human2)));
}

@end
