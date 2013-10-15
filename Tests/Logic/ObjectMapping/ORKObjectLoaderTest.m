//
//  ORKObjectLoaderTest.m
//  RestKit
//
//  Created by Blake Watters on 4/27/11.
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
#import "ORKObjectMappingProvider.h"
#import "ORKErrorMessage.h"
#import "ORKJSONParserJSONKit.h"

// Models
#import "ORKObjectLoaderTestResultModel.h"

@interface ORKTestComplexUser : NSObject {
    NSNumber *_userID;
    NSString *_firstname;
    NSString *_lastname;
    NSString *_email;
    NSString *_phone;
}

@property (nonatomic, retain) NSNumber *userID;
@property (nonatomic, retain) NSString *firstname;
@property (nonatomic, retain) NSString *lastname;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *phone;

@end

@implementation ORKTestComplexUser

@synthesize userID = _userID;
@synthesize firstname = _firstname;
@synthesize lastname = _lastname;
@synthesize phone = _phone;
@synthesize email = _email;

- (void)willSendWithObjectLoader:(ORKObjectLoader *)objectLoader
{
    return;
}

@end

@interface ORKTestResponseLoaderWithWillMapData : ORKTestResponseLoader {
    id _mappableData;
}

@property (nonatomic, readonly) id mappableData;

@end

@implementation ORKTestResponseLoaderWithWillMapData

@synthesize mappableData = _mappableData;

- (void)dealloc
{
    [_mappableData release];
    [super dealloc];
}

- (void)objectLoader:(ORKObjectLoader *)loader willMapData:(inout id *)mappableData
{
    [*mappableData setValue:@"monkey!" forKey:@"newKey"];
    _mappableData = [*mappableData retain];
}

@end

/////////////////////////////////////////////////////////////////////////////

@interface ORKObjectLoaderTest : ORKTestCase {

}

@end

@implementation ORKObjectLoaderTest

- (void)setUp
{
    [ORKTestFactory setUp];
}

- (void)tearDown
{
    [ORKTestFactory tearDown];
}

- (ORKObjectMappingProvider *)providerForComplexUser
{
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    [userMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"firstname" toKeyPath:@"firstname"]];
    [provider setMapping:userMapping forKeyPath:@"data.STUser"];
    return provider;
}

- (ORKObjectMappingProvider *)errorMappingProvider
{
    ORKObjectMappingProvider *provider = [[ORKObjectMappingProvider new] autorelease];
    ORKObjectMapping *errorMapping = [ORKObjectMapping mappingForClass:[ORKErrorMessage class]];
    [errorMapping addAttributeMapping:[ORKObjectAttributeMapping mappingFromKeyPath:@"" toKeyPath:@"errorMessage"]];
    errorMapping.rootKeyPath = @"errors";
    provider.errorMapping = errorMapping;
    return provider;
}

- (void)testShouldHandleTheErrorCaseAppropriately
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.mappingProvider = [self errorMappingProvider];

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/errors.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];

    assertThat(responseLoader.error, isNot(nilValue()));
    assertThat([responseLoader.error localizedDescription], is(equalTo(@"error1, error2")));

    NSArray *objects = [[responseLoader.error userInfo] objectForKey:ORKObjectMapperErrorObjectsKey];
    ORKErrorMessage *error1 = [objects objectAtIndex:0];
    ORKErrorMessage *error2 = [objects lastObject];

    assertThat(error1.errorMessage, is(equalTo(@"error1")));
    assertThat(error2.errorMessage, is(equalTo(@"error2")));
}

- (void)testShouldNotCrashWhenLoadingAnErrorResponseWithAnUnmappableMIMEType
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/404" delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.loadedUnexpectedResponse, is(equalToBool(YES)));
}

#pragma mark - Complex JSON

- (void)testShouldLoadAComplexUserObjectWithTargetObject
{
    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    NSString *authString = [NSString stringWithFormat:@"TRUEREST username=%@&password=%@&apikey=123456&class=iphone", @"username", @"password"];
    [objectLoader.URLRequest addValue:authString forHTTPHeaderField:@"Authorization"];
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.targetObject = user;
    objectLoader.mappingProvider = [self providerForComplexUser];

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

- (void)testShouldLoadAComplexUserObjectWithoutTargetObject
{
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatUnsignedInteger([responseLoader.objects count], is(equalToInt(1)));
    ORKTestComplexUser *user = [responseLoader.objects lastObject];

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

- (void)testShouldLoadAComplexUserObjectUsingRegisteredKeyPath
{
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatUnsignedInteger([responseLoader.objects count], is(equalToInt(1)));
    ORKTestComplexUser *user = [responseLoader.objects lastObject];

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

#pragma mark - willSendWithObjectLoader:

- (void)testShouldInvokeWillSendWithObjectLoaderOnSend
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:user];

    // Explicitly init so we don't get a managed object loader...
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [[ORKObjectLoader alloc] initWithURL:[objectManager.baseURL URLByAppendingResourcePath:@"/200"] mappingProvider:[self providerForComplexUser]];
    objectLoader.configurationDelegate = objectManager;
    objectLoader.sourceObject = mockObject;
    objectLoader.delegate = responseLoader;
    [[mockObject expect] willSendWithObjectLoader:objectLoader];
    [objectLoader send];
    [responseLoader waitForResponse];
    [mockObject verify];
}

- (void)testShouldInvokeWillSendWithObjectLoaderOnSendAsynchronously
{
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    [objectManager setMappingProvider:[self providerForComplexUser]];
    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:user];

    // Explicitly init so we don't get a managed object loader...
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [ORKObjectLoader loaderWithURL:[objectManager.baseURL URLByAppendingResourcePath:@"/200"] mappingProvider:objectManager.mappingProvider];
    objectLoader.delegate = responseLoader;
    objectLoader.sourceObject = mockObject;
    [[mockObject expect] willSendWithObjectLoader:objectLoader];
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    [mockObject verify];
}

- (void)testShouldInvokeWillSendWithObjectLoaderOnSendSynchronously
{
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    [objectManager setMappingProvider:[self providerForComplexUser]];
    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:user];

    // Explicitly init so we don't get a managed object loader...
    ORKObjectLoader *objectLoader = [ORKObjectLoader loaderWithURL:[objectManager.baseURL URLByAppendingResourcePath:@"/200"] mappingProvider:objectManager.mappingProvider];
    objectLoader.sourceObject = mockObject;
    [[mockObject expect] willSendWithObjectLoader:objectLoader];
    [objectLoader sendSynchronously];
    [mockObject verify];
}

- (void)testShouldLoadResultsNestedAtAKeyPath
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKObjectMapping *objectMapping = [ORKObjectMapping mappingForClass:[ORKObjectLoaderTestResultModel class]];
    [objectMapping mapKeyPath:@"id" toAttribute:@"ID"];
    [objectMapping mapKeyPath:@"ends_at" toAttribute:@"endsAt"];
    [objectMapping mapKeyPath:@"photo_url" toAttribute:@"photoURL"];
    [objectManager.mappingProvider setMapping:objectMapping forKeyPath:@"results"];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/JSON/ArrayOfResults.json" delegate:loader];
    [loader waitForResponse];
    assertThat([loader objects], hasCountOf(2));
    assertThat([[[loader objects] objectAtIndex:0] ID], is(equalToInt(226)));
    assertThat([[[loader objects] objectAtIndex:0] photoURL], is(equalTo(@"1308262872.jpg")));
    assertThat([[[loader objects] objectAtIndex:1] ID], is(equalToInt(235)));
    assertThat([[[loader objects] objectAtIndex:1] photoURL], is(equalTo(@"1308634984.jpg")));
}

- (void)testShouldAllowMutationOfTheParsedDataInWillMapData
{
    ORKTestResponseLoaderWithWillMapData *loader = (ORKTestResponseLoaderWithWillMapData *)[ORKTestResponseLoaderWithWillMapData responseLoader];
    ORKObjectManager *manager = [ORKTestFactory objectManager];
    [manager loadObjectsAtResourcePath:@"/JSON/humans/1.json" delegate:loader];
    [loader waitForResponse];
    assertThat([loader.mappableData valueForKey:@"newKey"], is(equalTo(@"monkey!")));
}

- (void)testShouldAllowYouToPostAnObjectAndHandleAnEmpty204Response
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    [mapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    ORKObjectMapping *serializationMapping = [mapping inverseMapping];

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.router routeClass:[ORKTestComplexUser class] toResourcePath:@"/204"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[ORKTestComplexUser class]];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *loader = [objectManager loaderForObject:user method:ORKRequestMethodPOST];
    loader.delegate = responseLoader;
    loader.objectMapping = mapping;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
    assertThat(user.email, is(equalTo(@"blake@restkit.org")));
}

- (void)testShouldAllowYouToPOSTAnObjectAndMapBackNonNestedContent
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    [mapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    ORKObjectMapping *serializationMapping = [mapping inverseMapping];

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.router routeClass:[ORKTestComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[ORKTestComplexUser class]];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *loader = [objectManager loaderForObject:user method:ORKRequestMethodPOST];
    loader.delegate = responseLoader;
    loader.objectMapping = mapping;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
    assertThat(user.email, is(equalTo(@"changed")));
}

- (void)testShouldMapContentWithoutAMIMEType
{
    // TODO: Not sure that this is even worth it. Unable to get the Sinatra server to produce such a response
    return;
    ORKLogConfigureByName("RestKit/Network", ORKLogLevelTrace);
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    [mapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    ORKObjectMapping *serializationMapping = [mapping inverseMapping];

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [[ORKParserRegistry sharedRegistry] setParserClass:[ORKJSONParserJSONKit class] forMIMEType:@"text/html"];
    [objectManager.router routeClass:[ORKTestComplexUser class] toResourcePath:@"/noMIME"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[ORKTestComplexUser class]];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *loader = [objectManager loaderForObject:user method:ORKRequestMethodPOST];
    loader.delegate = responseLoader;
    loader.objectMapping = mapping;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
    assertThat(user.email, is(equalTo(@"changed")));
}

- (void)testShouldAllowYouToPOSTAnObjectOfOneTypeAndGetBackAnother
{
    ORKObjectMapping *sourceMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    [sourceMapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    ORKObjectMapping *serializationMapping = [sourceMapping inverseMapping];

    ORKObjectMapping *targetMapping = [ORKObjectMapping mappingForClass:[ORKObjectLoaderTestResultModel class]];
    [targetMapping mapAttributes:@"ID", nil];

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.router routeClass:[ORKTestComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[ORKTestComplexUser class]];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *loader = [objectManager loaderForObject:user method:ORKRequestMethodPOST];
    loader.delegate = responseLoader;
    loader.sourceObject = user;
    loader.targetObject = nil;
    loader.objectMapping = targetMapping;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));

    // Our original object should not have changed
    assertThat(user.email, is(equalTo(@"blake@restkit.org")));

    // And we should have a new one
    ORKObjectLoaderTestResultModel *newObject = [[responseLoader objects] lastObject];
    assertThat(newObject, is(instanceOf([ORKObjectLoaderTestResultModel class])));
    assertThat(newObject.ID, is(equalToInt(31337)));
}

- (void)testShouldAllowYouToPOSTAnObjectOfOneTypeAndGetBackAnotherViaURLConfiguration
{
    ORKObjectMapping *sourceMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    [sourceMapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    ORKObjectMapping *serializationMapping = [sourceMapping inverseMapping];

    ORKObjectMapping *targetMapping = [ORKObjectMapping mappingForClass:[ORKObjectLoaderTestResultModel class]];
    [targetMapping mapAttributes:@"ID", nil];

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.router routeClass:[ORKTestComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[ORKTestComplexUser class]];
    [objectManager.mappingProvider setObjectMapping:targetMapping forResourcePathPattern:@"/notNestedUser"];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *loader = [objectManager loaderForObject:user method:ORKRequestMethodPOST];
    loader.delegate = responseLoader;
    loader.sourceObject = user;
    loader.targetObject = nil;
    [loader send];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));

    // Our original object should not have changed
    assertThat(user.email, is(equalTo(@"blake@restkit.org")));

    // And we should have a new one
    ORKObjectLoaderTestResultModel *newObject = [[responseLoader objects] lastObject];
    assertThat(newObject, is(instanceOf([ORKObjectLoaderTestResultModel class])));
    assertThat(newObject.ID, is(equalToInt(31337)));
}

// TODO: Should live in a different file...
- (void)testShouldAllowYouToPOSTAnObjectAndMapBackNonNestedContentViapostObject
{
    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    [mapping mapAttributes:@"firstname", @"lastname", @"email", nil];
    ORKObjectMapping *serializationMapping = [mapping inverseMapping];

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.router routeClass:[ORKTestComplexUser class] toResourcePath:@"/notNestedUser"];
    [objectManager.mappingProvider setSerializationMapping:serializationMapping forClass:[ORKTestComplexUser class]];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    // NOTE: The postObject: should infer the target object from sourceObject and the mapping class
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    [objectManager postObject:user usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = responseLoader;
        loader.objectMapping = mapping;
    }];
    [responseLoader waitForResponse];
    assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
    assertThat(user.email, is(equalTo(@"changed")));
}

- (void)testShouldRespectTheRootKeyPathWhenConstructingATemporaryObjectMappingProvider
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];

    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.objectMapping = userMapping;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.targetObject = user;

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

- (void)testShouldDetermineObjectLoaderBasedOnResourcePathPatternWithExactMatch
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectMappingProvider *mappingProvider = [ORKObjectMappingProvider mappingProvider];
    [mappingProvider setObjectMapping:userMapping forResourcePathPattern:@"/JSON/ComplexNestedUser.json"];

    ORKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/JSON/ComplexNestedUser.json"];
    ORKObjectLoader *objectLoader = [ORKObjectLoader loaderWithURL:URL mappingProvider:mappingProvider];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.targetObject = user;

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];

    NSLog(@"Response: %@", responseLoader.objects);

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

- (void)testShouldDetermineObjectLoaderBasedOnResourcePathPatternWithPartialMatch
{
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectMappingProvider *mappingProvider = [ORKObjectMappingProvider mappingProvider];
    [mappingProvider setObjectMapping:userMapping forResourcePathPattern:@"/JSON/:name\\.json"];

    ORKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/JSON/ComplexNestedUser.json"];
    ORKObjectLoader *objectLoader = [ORKObjectLoader loaderWithURL:URL mappingProvider:mappingProvider];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.targetObject = user;

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];

    NSLog(@"Response: %@", responseLoader.objects);

    assertThat(user.firstname, is(equalTo(@"Diego")));
}

- (void)testShouldReturnSuccessWhenTheStatusCodeIs200AndTheResponseBodyIsEmpty
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/humans/1234"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodDELETE;
    objectLoader.objectMapping = userMapping;
    objectLoader.targetObject = user;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
}

- (void)testShouldInvokeTheDelegateWithTheTargetObjectWhenTheStatusCodeIs200AndTheResponseBodyIsEmpty
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];

    ORKTestComplexUser *user = [[ORKTestComplexUser new] autorelease];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];

    ORKObjectLoader *objectLoader = [ORKObjectLoader loaderWithURL:[objectManager.baseURL URLByAppendingResourcePath:@"/humans/1234"] mappingProvider:objectManager.mappingProvider];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodDELETE;
    objectLoader.objectMapping = userMapping;
    objectLoader.targetObject = user;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, hasItem(user));
}

- (void)testShouldConsiderTheLoadOfEmptyObjectsWithoutAnyMappableAttributesAsSuccess
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];

    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    [userMapping mapAttributes:@"firstname", nil];
    [objectManager.mappingProvider setMapping:userMapping forKeyPath:@"firstUser"];
    [objectManager.mappingProvider setMapping:userMapping forKeyPath:@"secondUser"];

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    [objectManager loadObjectsAtResourcePath:@"/users/empty" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
}

- (void)testShouldInvokeTheDelegateOnSuccessIfTheResponseIsAnEmptyArray
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    responseLoader.timeout = 20;
    [objectManager loadObjectsAtResourcePath:@"/empty/array" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, isNot(nilValue()));
    assertThatBool([responseLoader.objects isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThat(responseLoader.objects, is(empty()));
}

- (void)testShouldInvokeTheDelegateOnSuccessIfTheResponseIsAnEmptyDictionary
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    responseLoader.timeout = 20;
    [objectManager loadObjectsAtResourcePath:@"/empty/dictionary" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, isNot(nilValue()));
    assertThatBool([responseLoader.objects isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThat(responseLoader.objects, is(empty()));
}

- (void)testShouldInvokeTheDelegateOnSuccessIfTheResponseIsAnEmptyString
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    responseLoader.timeout = 20;
    [objectManager loadObjectsAtResourcePath:@"/empty/string" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThat(responseLoader.objects, isNot(nilValue()));
    assertThatBool([responseLoader.objects isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThat(responseLoader.objects, is(empty()));
}

- (void)testShouldNotBlockNetworkOperationsWhileAwaitingObjectMapping
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.requestCache.storagePolicy = ORKRequestCacheStoragePolicyDisabled;
    objectManager.client.requestQueue.concurrentRequestsLimit = 1;
    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    userMapping.rootKeyPath = @"human";
    [userMapping mapAttributes:@"name", @"id", nil];

    // Suspend the Queue to block object mapping
    dispatch_suspend(objectManager.mappingQueue);

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    [objectManager.mappingProvider setObjectMapping:userMapping forResourcePathPattern:@"/humans/1"];
    [objectManager loadObjectsAtResourcePath:@"/humans/1" delegate:nil];
    [objectManager.client get:@"/empty/string" delegate:responseLoader];
    [responseLoader waitForResponse];

    // We should get a response is network is released even though object mapping didn't finish
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
}

#pragma mark - Block Tests

- (void)testInvocationOfDidLoadObjectBlock
{
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObject = ^(id object) {
        expectedResult = object;
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(expectedResult, is(notNilValue()));
}

- (void)testInvocationOfDidLoadObjectBlockIsSingularObjectOfCorrectType
{
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObject = ^(id object) {
        expectedResult = object;
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(expectedResult, is(instanceOf([ORKTestComplexUser class])));
}

- (void)testInvocationOfDidLoadObjectsBlock
{
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObjects = ^(NSArray *objects) {
        expectedResult = objects;
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(expectedResult, is(notNilValue()));
}

- (void)testInvocationOfDidLoadObjectsBlocksIsCollectionOfObjects
{
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObjects = ^(NSArray *objects) {
        expectedResult = [objects retain];
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    NSLog(@"The expectedResult = %@", expectedResult);
    assertThat(expectedResult, is(instanceOf([NSArray class])));
    assertThat(expectedResult, hasCountOf(1));
    [expectedResult release];
}

- (void)testInvocationOfDidLoadObjectsDictionaryBlock
{
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObjectsDictionary = ^(NSDictionary *dictionary) {
        expectedResult = dictionary;
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(expectedResult, is(notNilValue()));
}

- (void)testInvocationOfDidLoadObjectsDictionaryBlocksIsDictionaryOfObjects
{
    ORKObjectManager *objectManager = [ORKObjectManager managerWithBaseURL:[ORKTestFactory baseURL]];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/JSON/ComplexNestedUser.json"];
    objectLoader.delegate = responseLoader;
    objectLoader.method = ORKRequestMethodGET;
    objectLoader.mappingProvider = [self providerForComplexUser];
    __block id expectedResult = nil;
    objectLoader.onDidLoadObjectsDictionary = ^(NSDictionary *dictionary) {
        expectedResult = dictionary;
    };

    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(expectedResult, is(instanceOf([NSDictionary class])));
    assertThat(expectedResult, hasCountOf(1));
}

// NOTE: Errors are fired in a number of contexts within the ORKObjectLoader. We have centralized the cases into a private
// method and test that one case here. There should be better coverage for this.
- (void)testInvocationOfOnDidFailWithError
{
    ORKObjectLoader *loader = [ORKObjectLoader loaderWithURL:nil mappingProvider:nil];
    NSError *expectedError = [NSError errorWithDomain:@"Testing" code:1234 userInfo:nil];
    __block NSError *blockError = nil;
    loader.onDidFailWithError = ^(NSError *error) {
        blockError = error;
    };
    [loader performSelector:@selector(informDelegateOfError:) withObject:expectedError];
    assertThat(blockError, is(equalTo(expectedError)));
}

- (void)testShouldNotAssertDuringObjectMappingOnSynchronousRequest
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];

    ORKObjectMapping *userMapping = [ORKObjectMapping mappingForClass:[ORKTestComplexUser class]];
    userMapping.rootKeyPath = @"data.STUser";
    [userMapping mapAttributes:@"firstname", nil];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/humans/1"];
    objectLoader.objectMapping = userMapping;
    [objectLoader sendSynchronously];
    ORKResponse *response = [objectLoader sendSynchronously];

    assertThatInteger(response.statusCode, is(equalToInt(200)));
}

@end
