//
//  ORKManagedObjectLoaderTest.m
//  RestKit
//
//  Created by Blake Watters on 4/28/11.
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
#import "ORKManagedObjectLoader.h"
#import "ORKManagedObjectMapping.h"
#import "ORKHuman.h"
#import "ORKCat.h"
#import "NSManagedObject+ActiveRecord.h"
#import "ORKObjectMappingProvider+CoreData.h"

@interface ORKManagedObjectLoaderTest : ORKTestCase {

}

@end

@implementation ORKManagedObjectLoaderTest

- (void)testShouldDeleteObjectFromLocalStoreOnDELETE
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    [store save:nil];
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.objectStore = store;
    ORKHuman *human = [ORKHuman object];
    human.name = @"Blake Watters";
    human.railsID = [NSNumber numberWithInt:1];
    [objectManager.objectStore save:nil];

    assertThat(objectManager.objectStore.primaryManagedObjectContext, is(equalTo(store.primaryManagedObjectContext)));

    ORKManagedObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/humans/1"];
    ORKManagedObjectLoader *objectLoader = [ORKManagedObjectLoader loaderWithURL:URL mappingProvider:objectManager.mappingProvider objectStore:store];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodDELETE;
    objectLoader.objectMapping = mapping;
    objectLoader.targetObject = human;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThatBool([human isDeleted], equalToBool(YES));
}

- (void)testShouldLoadAnObjectWithAToOneRelationship
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.objectStore = store;

    ORKObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    [humanMapping mapAttributes:@"name", nil];
    ORKObjectMapping *catMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:store];
    [catMapping mapAttributes:@"name", nil];
    [humanMapping mapKeyPath:@"favorite_cat" toRelationship:@"favoriteCat" withMapping:catMapping];
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/JSON/humans/with_to_one_relationship.json"];
    ORKManagedObjectLoader *objectLoader = [ORKManagedObjectLoader loaderWithURL:URL mappingProvider:objectManager.mappingProvider objectStore:store];
    objectLoader.delegate = responseLoader;
    [objectLoader send];
    [responseLoader waitForResponse];
    ORKHuman *human = [responseLoader.objects lastObject];
    assertThat(human, isNot(nilValue()));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldDeleteObjectsMissingFromPayloadReturnedByObjectCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForEntityWithName:@"ORKHuman"
                                                                       inManagedObjectStore:store];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";
    humanMapping.rootKeyPath = @"human";

    // Create 3 objects, we will expect 2 after the load
    [ORKHuman truncateAll];
    assertThatUnsignedInteger([ORKHuman count:nil], is(equalToInt(0)));
    ORKHuman *blake = [ORKHuman createEntity];
    blake.railsID = [NSNumber numberWithInt:123];
    ORKHuman *other = [ORKHuman createEntity];
    other.railsID = [NSNumber numberWithInt:456];
    ORKHuman *deleteMe = [ORKHuman createEntity];
    deleteMe.railsID = [NSNumber numberWithInt:9999];
    [store save:nil];
    assertThatUnsignedInteger([ORKHuman count:nil], is(equalToInt(3)));

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.mappingProvider setObjectMapping:humanMapping
                             forResourcePathPattern:@"/JSON/humans/all.json"
                              withFetchRequestBlock:^ (NSString *resourcePath) {
                                  return [ORKHuman fetchRequest];
                              }];
    objectManager.objectStore = store;

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    responseLoader.timeout = 25;
    ORKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/JSON/humans/all.json"];
    ORKManagedObjectLoader *objectLoader = [ORKManagedObjectLoader loaderWithURL:URL mappingProvider:objectManager.mappingProvider objectStore:store];
    objectLoader.delegate = responseLoader;
    [objectLoader send];
    [responseLoader waitForResponse];

    assertThatUnsignedInteger([ORKHuman count:nil], is(equalToInt(2)));
    assertThatBool([blake isDeleted], is(equalToBool(NO)));
    assertThatBool([other isDeleted], is(equalToBool(NO)));
    assertThatBool([deleteMe isDeleted], is(equalToBool(YES)));
}

- (void)testShouldNotAssertDuringObjectMappingOnSynchronousRequest
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.objectStore = store;

    ORKObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    ORKManagedObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/humans/1"];
    objectLoader.objectMapping = mapping;
    ORKResponse *response = [objectLoader sendSynchronously];

    NSArray *humans = [ORKHuman findAll];
    assertThatUnsignedInteger([humans count], is(equalToInt(1)));
    assertThatInteger(response.statusCode, is(equalToInt(200)));
}

- (void)testShouldSkipObjectMappingOnRequestCacheHitWhenObjectCachePresent
{
    [ORKTestFactory clearCacheDirectory];

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKManagedObjectStore *objectStore = [ORKTestFactory managedObjectStore];
    objectManager.objectStore = objectStore;
    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForEntityWithName:@"ORKHuman" inManagedObjectStore:objectStore];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";
    humanMapping.rootKeyPath = @"human";

    [ORKHuman truncateAll];
    assertThatInteger([ORKHuman count:nil], is(equalToInteger(0)));
    ORKHuman *blake = [ORKHuman createEntity];
    blake.railsID = [NSNumber numberWithInt:123];
    ORKHuman *other = [ORKHuman createEntity];
    other.railsID = [NSNumber numberWithInt:456];
    [objectStore save:nil];
    assertThatInteger([ORKHuman count:nil], is(equalToInteger(2)));

    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    [objectManager.mappingProvider setObjectMapping:humanMapping forResourcePathPattern:@"/coredata/etag" withFetchRequestBlock:^NSFetchRequest *(NSString *resourcePath) {
        return [ORKHuman fetchRequest];
    }];

    {
        ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
        ORKManagedObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/coredata/etag"];
        objectLoader.delegate = responseLoader;
        id mockLoader = [OCMockObject partialMockForObject:objectLoader];
        [[[mockLoader expect] andForwardToRealObject] performMapping:[OCMArg setTo:OCMOCK_ANY]];

        [mockLoader send];
        [responseLoader waitForResponse];

        STAssertNoThrow([mockLoader verify], nil);
        assertThatInteger([ORKHuman count:nil], is(equalToInteger(2)));
        assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
        assertThatBool([responseLoader.response wasLoadedFromCache], is(equalToBool(NO)));
        assertThatInteger([responseLoader.objects count], is(equalToInteger(2)));
    }
    {
        ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
        ORKManagedObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/coredata/etag"];
        objectLoader.delegate = responseLoader;
        id mockLoader = [OCMockObject partialMockForObject:objectLoader];
        [[mockLoader reject] performMapping:[OCMArg setTo:OCMOCK_ANY]];

        [mockLoader send];
        [responseLoader waitForResponse];

        STAssertNoThrow([mockLoader verify], nil);
        assertThatInteger([ORKHuman count:nil], is(equalToInteger(2)));
        assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
        assertThatBool([responseLoader.response wasLoadedFromCache], is(equalToBool(YES)));
        assertThatInteger([responseLoader.objects count], is(equalToInteger(2)));
    }
}

- (void)testTheOnDidFailBlockIsInvokedOnFailure
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKManagedObjectLoader *loader = [objectManager loaderWithResourcePath:@"/fail"];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    __block BOOL invoked = NO;
    loader.onDidFailWithError = ^ (NSError *error) {
        invoked = YES;
    };
    loader.delegate = responseLoader;
    [loader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatBool(invoked, is(equalToBool(YES)));
}

- (void)testThatObjectLoadedDidFinishLoadingIsCalledOnStoreSaveFailure
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.objectStore = store;
    id mockStore = [OCMockObject partialMockForObject:store];
    BOOL success = NO;
    [[[mockStore stub] andReturnValue:OCMOCK_VALUE(success)] save:[OCMArg anyPointer]];

    ORKObjectMapping *mapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:store];
    ORKManagedObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/humans/1"];
    objectLoader.objectMapping = mapping;

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    id mockResponseLoader = [OCMockObject partialMockForObject:responseLoader];
    [[mockResponseLoader expect] objectLoaderDidFinishLoading:objectLoader];
    objectLoader.delegate = responseLoader;
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    [mockResponseLoader verify];
}

@end
