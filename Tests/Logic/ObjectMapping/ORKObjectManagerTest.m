//
//  ORKObjectManagerTest.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
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
#import "ORKObjectManager.h"
#import "ORKManagedObjectStore.h"
#import "ORKTestResponseLoader.h"
#import "ORKManagedObjectMapping.h"
#import "ORKObjectMappingProvider.h"
#import "ORKHuman.h"
#import "ORKCat.h"
#import "ORKObjectMapperTestModel.h"

@interface ORKObjectManagerTest : ORKTestCase {
    ORKObjectManager *_objectManager;
}

@end

@implementation ORKObjectManagerTest

- (void)setUp
{
    [ORKTestFactory setUp];

    _objectManager = [ORKTestFactory objectManager];
    _objectManager.objectStore = [ORKManagedObjectStore objectStoreWithStoreFilename:@"ORKTests.sqlite"];
    [ORKObjectManager setSharedManager:_objectManager];
    [_objectManager.objectStore deletePersistentStore];

    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];

    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForClass:[ORKHuman class] inManagedObjectStore:_objectManager.objectStore];
    humanMapping.rootKeyPath = @"human";
    [humanMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [humanMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [humanMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [humanMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [humanMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [humanMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [humanMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [humanMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];

    ORKManagedObjectMapping *catObjectMapping = [ORKManagedObjectMapping mappingForClass:[ORKCat class] inManagedObjectStore:_objectManager.objectStore];
    [catObjectMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [catObjectMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [catObjectMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [catObjectMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [catObjectMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [catObjectMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [catObjectMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [catObjectMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];

    [catObjectMapping addRelationshipMapping:[ORKObjectRelationshipMapping mappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catObjectMapping]];

    [provider setMapping:humanMapping forKeyPath:@"human"];
    [provider setMapping:humanMapping forKeyPath:@"humans"];

    ORKObjectMapping *humanSerialization = [ORKObjectMapping mappingForClass:[NSDictionary class]];
    [humanSerialization addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [provider setSerializationMapping:humanSerialization forClass:[ORKHuman class]];
    _objectManager.mappingProvider = provider;

    ORKObjectRouter *router = [[[ORKObjectRouter alloc] init] autorelease];
    [router routeClass:[ORKHuman class] toResourcePath:@"/humans" forMethod:ORKRequestMethodPOST];
    _objectManager.router = router;
}

- (void)tearDown
{
    [ORKTestFactory tearDown];
}

- (void)testShouldSetTheAcceptHeaderAppropriatelyForTheFormat
{

    assertThat([_objectManager.client.HTTPHeaders valueForKey:@"Accept"], is(equalTo(@"application/json")));
}

// TODO: Move to Core Data specific spec file...
- (void)testShouldUpdateACoreDataBackedTargetObject
{
    ORKHuman *temporaryHuman = [[ORKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"ORKHuman" inManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext] insertIntoManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext];
    temporaryHuman.name = @"My Name";

    // TODO: We should NOT have to save the object store here to make this
    // spec pass. Without it we are crashing inside the mapper internals. Believe
    // that we just need a way to save the context before we begin mapping or something
    // on success. Always saving means that we can abandon objects on failure...
    [_objectManager.objectStore save:nil];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [_objectManager postObject:temporaryHuman delegate:loader];
    [loader waitForResponse];

    assertThat(loader.objects, isNot(empty()));
    ORKHuman *human = (ORKHuman *)[loader.objects objectAtIndex:0];
    assertThat(human, is(equalTo(temporaryHuman)));
    assertThat(human.railsID, is(equalToInt(1)));
}

- (void)testShouldDeleteACoreDataBackedTargetObjectOnError
{
    ORKHuman *temporaryHuman = [[ORKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"ORKHuman" inManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext] insertIntoManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext];
    temporaryHuman.name = @"My Name";
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping mapAttributes:@"name", nil];

    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    NSString *resourcePath = @"/humans/fail";
    ORKObjectLoader *objectLoader = [_objectManager loaderWithResourcePath:resourcePath];
    objectLoader.delegate = loader;
    objectLoader.method = ORKRequestMethodPOST;
    objectLoader.targetObject = temporaryHuman;
    objectLoader.serializationMapping = mapping;
    [objectLoader send];
    [loader waitForResponse];

    assertThat(temporaryHuman.managedObjectContext, is(equalTo(nil)));
}

- (void)testShouldNotDeleteACoreDataBackedTargetObjectOnErrorIfItWasAlreadySaved
{
    ORKHuman *temporaryHuman = [[ORKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"ORKHuman" inManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext] insertIntoManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext];
    temporaryHuman.name = @"My Name";
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping mapAttributes:@"name", nil];

    // Save it to suppress deletion
    [_objectManager.objectStore save:nil];

    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    NSString *resourcePath = @"/humans/fail";
    ORKObjectLoader *objectLoader = [_objectManager loaderWithResourcePath:resourcePath];
    objectLoader.delegate = loader;
    objectLoader.method = ORKRequestMethodPOST;
    objectLoader.targetObject = temporaryHuman;
    objectLoader.serializationMapping = mapping;
    [objectLoader send];
    [loader waitForResponse];

    assertThat(temporaryHuman.managedObjectContext, is(equalTo(_objectManager.objectStore.primaryManagedObjectContext)));
}

// TODO: Move to Core Data specific spec file...
- (void)testShouldLoadAHuman
{
    assertThatBool([ORKClient sharedClient].isNetworkReachable, is(equalToBool(YES)));
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [_objectManager loadObjectsAtResourcePath:@"/JSON/humans/1.json" delegate:loader];
    [loader waitForResponse];
    assertThat(loader.error, is(nilValue()));
    assertThat(loader.objects, isNot(empty()));
    ORKHuman *blake = (ORKHuman *)[loader.objects objectAtIndex:0];
    assertThat(blake.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldLoadAllHumans
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [_objectManager loadObjectsAtResourcePath:@"/JSON/humans/all.json" delegate:loader];
    [loader waitForResponse];
    NSArray *humans = (NSArray *)loader.objects;
    assertThatUnsignedInteger([humans count], is(equalToInt(2)));
    assertThat([humans objectAtIndex:0], is(instanceOf([ORKHuman class])));
}

- (void)testShouldHandleConnectionFailures
{
    NSString *localBaseURL = [NSString stringWithFormat:@"http://127.0.0.1:3001"];
    ORKObjectManager *modelManager = [ORKObjectManager managerWithBaseURLString:localBaseURL];
    modelManager.client.requestQueue.suspended = NO;
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [modelManager loadObjectsAtResourcePath:@"/JSON/humans/1" delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(NO)));
}

- (void)testShouldPOSTAnObject
{
    ORKObjectManager *manager = [ORKTestFactory objectManager];

    ORKObjectRouter *router = [[ORKObjectRouter new] autorelease];
    [router routeClass:[ORKObjectMapperTestModel class] toResourcePath:@"/humans" forMethod:ORKRequestMethodPOST];
    manager.router = router;

    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKObjectMapperTestModel class]];
    mapping.rootKeyPath = @"human";
    [mapping mapAttributes:@"name", @"age", nil];
    [manager.mappingProvider setMapping:mapping forKeyPath:@"human"];
    [manager.mappingProvider setSerializationMapping:mapping forClass:[ORKObjectMapperTestModel class]];

    ORKObjectMapperTestModel *human = [[ORKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];

    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [manager postObject:human delegate:loader];
    [loader waitForResponse];

    // NOTE: The /humans endpoint returns a canned response, we are testing the plumbing
    // of the object manager here.
    assertThat(human.name, is(equalTo(@"My Name")));
}

- (void)testShouldNotSetAContentBodyOnAGET
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.router routeClass:[ORKObjectMapperTestModel class] toResourcePath:@"/humans/1"];

    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectMapperTestModel *human = [[ORKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    __block ORKObjectLoader *objectLoader = nil;
    [objectManager getObject:human usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = responseLoader;
        objectLoader = loader;
    }];
    [responseLoader waitForResponse];
    ORKLogCritical(@"%@", [objectLoader.URLRequest allHTTPHeaderFields]);
    assertThat([objectLoader.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldNotSetAContentBodyOnADELETE
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.router routeClass:[ORKObjectMapperTestModel class] toResourcePath:@"/humans/1"];

    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectMapperTestModel *human = [[ORKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    __block ORKObjectLoader *objectLoader = nil;
    [objectManager deleteObject:human usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = responseLoader;
        objectLoader = loader;
    }];
    [responseLoader waitForResponse];
    ORKLogCritical(@"%@", [objectLoader.URLRequest allHTTPHeaderFields]);
    assertThat([objectLoader.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

#pragma mark - Block Helpers

- (void)testShouldLetYouLoadObjectsWithABlock
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/JSON/humans/1.json" usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = responseLoader;
        loader.objectMapping = mapping;
    }];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
    assertThat(responseLoader.objects, hasCountOf(1));
}

- (void)testShouldAllowYouToOverrideTheRoutedResourcePath
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.router routeClass:[ORKObjectMapperTestModel class] toResourcePath:@"/humans/2"];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectMapperTestModel *human = [[ORKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    [objectManager deleteObject:human usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = responseLoader;
        loader.resourcePath = @"/humans/1";
    }];
    [responseLoader waitForResponse];
    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
}

- (void)testShouldAllowYouToUseObjectHelpersWithoutRouting
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectMapperTestModel *human = [[ORKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    [objectManager sendObject:human toResourcePath:@"/humans/1" usingBlock:^(ORKObjectLoader *loader) {
        loader.method = ORKRequestMethodDELETE;
        loader.delegate = responseLoader;
        loader.resourcePath = @"/humans/1";
    }];
    [responseLoader waitForResponse];
    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
}

- (void)testShouldAllowYouToSkipTheMappingProvider
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKObjectMapperTestModel class]];
    mapping.rootKeyPath = @"human";
    [mapping mapAttributes:@"name", @"age", nil];

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectMapperTestModel *human = [[ORKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    [objectManager sendObject:human toResourcePath:@"/humans/1" usingBlock:^(ORKObjectLoader *loader) {
        loader.method = ORKRequestMethodDELETE;
        loader.delegate = responseLoader;
        loader.objectMapping = mapping;
    }];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
}

- (void)testShouldLetYouOverloadTheParamsOnAnObjectLoaderRequest
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKObjectMapperTestModel class]];
    mapping.rootKeyPath = @"human";
    [mapping mapAttributes:@"name", @"age", nil];

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectMapperTestModel *human = [[ORKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    NSDictionary *myParams = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
    __block ORKObjectLoader *objectLoader = nil;
    [objectManager sendObject:human toResourcePath:@"/humans/1" usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = responseLoader;
        loader.method = ORKRequestMethodPOST;
        loader.objectMapping = mapping;
        loader.params = myParams;
        objectLoader = loader;
    }];
    [responseLoader waitForResponse];
    assertThat(objectLoader.params, is(equalTo(myParams)));
}

- (void)testInitializationOfObjectLoaderViaManagerConfiguresSerializationMIMEType
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.serializationMIMEType = ORKMIMETypeJSON;
    ORKObjectLoader *loader = [objectManager loaderWithResourcePath:@"/test"];
    assertThat(loader.serializationMIMEType, isNot(nilValue()));
    assertThat(loader.serializationMIMEType, is(equalTo(ORKMIMETypeJSON)));
}

- (void)testInitializationOfRoutedPathViaSendObjectMethodUsingBlock
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKObjectMapperTestModel class]];
    mapping.rootKeyPath = @"human";
    [objectManager.mappingProvider registerObjectMapping:mapping withRootKeyPath:@"human"];
    [objectManager.router routeClass:[ORKObjectMapperTestModel class] toResourcePath:@"/human/1"];
    objectManager.serializationMIMEType = ORKMIMETypeJSON;
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];

    ORKObjectMapperTestModel *object = [ORKObjectMapperTestModel new];
    [objectManager putObject:object usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = responseLoader;
    }];
    [responseLoader waitForResponse];
}

- (void)testThatInitializationOfObjectManagerInitializesNetworkStatusFromClient
{
    ORKReachabilityObserver *observer = [[ORKReachabilityObserver alloc] initWithHost:@"google.com"];
    id mockObserver = [OCMockObject partialMockForObject:observer];
    BOOL yes = YES;
    [[[mockObserver stub] andReturnValue:OCMOCK_VALUE(yes)] isReachabilityDetermined];
    [[[mockObserver stub] andReturnValue:OCMOCK_VALUE(yes)] isNetworkReachable];
    ORKClient *client = [ORKTestFactory client];
    client.reachabilityObserver = mockObserver;
    ORKObjectManager *manager = [[ORKObjectManager alloc] init];
    manager.client = client;
    assertThatInteger(manager.networkStatus, is(equalToInteger(ORKObjectManagerNetworkStatusOnline)));
}

- (void)testThatMutationOfUnderlyingClientReachabilityObserverUpdatesManager
{
    ORKObjectManager *manager = [ORKTestFactory objectManager];
    ORKReachabilityObserver *observer = [[ORKReachabilityObserver alloc] initWithHost:@"google.com"];
    assertThatInteger(manager.networkStatus, is(equalToInteger(ORKObjectManagerNetworkStatusOnline)));
    manager.client.reachabilityObserver = observer;
    assertThatInteger(manager.networkStatus, is(equalToInteger(ORKObjectManagerNetworkStatusUnknown)));
}

- (void)testThatReplacementOfUnderlyingClientUpdatesManagerReachabilityObserver
{
    ORKObjectManager *manager = [ORKTestFactory objectManager];
    ORKReachabilityObserver *observer = [[ORKReachabilityObserver alloc] initWithHost:@"google.com"];
    ORKClient *client = [ORKTestFactory client];
    client.reachabilityObserver = observer;
    assertThatInteger(manager.networkStatus, is(equalToInteger(ORKObjectManagerNetworkStatusOnline)));
    manager.client = client;
    assertThatInteger(manager.networkStatus, is(equalToInteger(ORKObjectManagerNetworkStatusUnknown)));
}

@end
