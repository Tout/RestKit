//
//  ORKClientTest.m
//  RestKit
//
//  Created by Blake Watters on 1/31/11.
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

#import <SenTestingKit/SenTestingKit.h>
#import "ORKTestEnvironment.h"
#import "ORKURL.h"

@interface ORKClientTest : ORKTestCase
@end


@implementation ORKClientTest

- (void)setUp
{
    [ORKTestFactory setUp];
}

- (void)tearDown
{
    [ORKTestFactory tearDown];
}

- (void)testShouldDetectNetworkStatusWithAHostname
{
    ORKClient *client = [[ORKClient alloc] initWithBaseURLString:@"http://restkit.org"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
    ORKReachabilityNetworkStatus status = [client.reachabilityObserver networkStatus];
    assertThatInt(status, is(equalToInt(ORKReachabilityReachableViaWiFi)));
    [client release];
}

- (void)testShouldDetectNetworkStatusWithAnIPAddressBaseName
{
    ORKClient *client = [[ORKClient alloc] initWithBaseURLString:@"http://173.45.234.197"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
    ORKReachabilityNetworkStatus status = [client.reachabilityObserver networkStatus];
    assertThatInt(status, isNot(equalToInt(ORKReachabilityIndeterminate)));
    [client release];
}

- (void)testShouldSetTheCachePolicyOfTheRequest
{
    ORKClient *client = [ORKClient clientWithBaseURLString:@"http://restkit.org"];
    client.cachePolicy = ORKRequestCachePolicyLoadIfOffline;
    ORKRequest *request = [client requestWithResourcePath:@""];
    assertThatInt(request.cachePolicy, is(equalToInt(ORKRequestCachePolicyLoadIfOffline)));
}

- (void)testShouldInitializeTheCacheOfTheRequest
{
    ORKClient *client = [ORKClient clientWithBaseURLString:@"http://restkit.org"];
    client.requestCache = [[[ORKRequestCache alloc] init] autorelease];
    ORKRequest *request = [client requestWithResourcePath:@""];
    assertThat(request.cache, is(equalTo(client.requestCache)));
}

- (void)testShouldLoadPageWithNoContentTypeInformation
{
    ORKClient *client = [ORKClient clientWithBaseURLString:@"http://www.semiose.fr"];
    client.defaultHTTPEncoding = NSISOLatin1StringEncoding;
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    ORKRequest *request = [client requestWithResourcePath:@"/"];
    request.delegate = loader;
    [request send];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(YES)));
    assertThat([loader.response bodyEncodingName], is(nilValue()));
    assertThatInteger([loader.response bodyEncoding], is(equalToInteger(NSISOLatin1StringEncoding)));
}

- (void)testShouldAllowYouToChangeTheBaseURL
{
    ORKClient *client = [ORKClient clientWithBaseURLString:@"http://www.google.com"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
    assertThatBool([client isNetworkReachable], is(equalToBool(YES)));
    client.baseURL = [ORKURL URLWithString:@"http://www.restkit.org"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]]; // Let the runloop cycle
    assertThatBool([client isNetworkReachable], is(equalToBool(YES)));
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    ORKRequest *request = [client requestWithResourcePath:@"/"];
    request.delegate = loader;
    [request send];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(YES)));
}

- (void)testShouldLetYouChangeTheHTTPAuthCredentials
{
    ORKClient *client = [ORKTestFactory client];
    client.authenticationType = ORKRequestAuthenticationTypeHTTP;
    client.username = @"invalid";
    client.password = @"password";
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    [client get:@"/authentication/basic" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(NO)));
    assertThat(responseLoader.error, is(notNilValue()));
    client.username = @"restkit";
    client.password = @"authentication";
    [client get:@"/authentication/basic" delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
}

- (void)testShouldSuspendTheQueueOnBaseURLChangeWhenReachabilityHasNotBeenEstablished
{
    ORKClient *client = [ORKClient clientWithBaseURLString:@"http://www.google.com"];
    client.baseURL = [ORKURL URLWithString:@"http://restkit.org"];
    assertThatBool(client.requestQueue.suspended, is(equalToBool(YES)));
}

- (void)testShouldNotSuspendTheMainQueueOnBaseURLChangeWhenReachabilityHasBeenEstablished
{
    ORKReachabilityObserver *observer = [ORKReachabilityObserver reachabilityObserverForInternet];
    [observer getFlags];
    assertThatBool([observer isReachabilityDetermined], is(equalToBool(YES)));
    ORKClient *client = [ORKClient clientWithBaseURLString:@"http://www.google.com"];
    assertThatBool(client.requestQueue.suspended, is(equalToBool(YES)));
    client.reachabilityObserver = observer;
    assertThatBool(client.requestQueue.suspended, is(equalToBool(NO)));
}

- (void)testShouldAllowYouToChangeTheTimeoutInterval
{
    ORKClient *client = [ORKClient clientWithBaseURLString:@"http://restkit.org"];
    client.timeoutInterval = 20.0;
    ORKRequest *request = [client requestWithResourcePath:@""];
    assertThatFloat(request.timeoutInterval, is(equalToFloat(20.0)));
}

- (void)testShouldPerformAPUTWithParams
{
    NSLog(@"PENDING ---> FIX ME!!!");
    return;
    ORKClient *client = [ORKClient clientWithBaseURLString:@"http://ohblockhero.appspot.com/api/v1"];
    client.cachePolicy = ORKRequestCachePolicyNone;
    ORKParams *params = [ORKParams params];
    [params setValue:@"username" forParam:@"username"];
    [params setValue:@"Dear Daniel" forParam:@"fullName"];
    [params setValue:@"aa@aa.com" forParam:@"email"];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [client put:@"/userprofile" params:params delegate:loader];
    STAssertNoThrow([loader waitForResponse], @"");
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(NO)));
}

- (void)testShouldAllowYouToChangeTheCacheTimeoutInterval
{
    ORKClient *client = [ORKClient clientWithBaseURLString:@"http://restkit.org"];
    client.cacheTimeoutInterval = 20.0;
    ORKRequest *request = [client requestWithResourcePath:@""];
    assertThatFloat(request.cacheTimeoutInterval, is(equalToFloat(20.0)));
}

- (void)testThatRunLoopModePropertyRespected
{
    NSString * const dummyRunLoopMode = @"dummyRunLoopMode";
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    ORKClient *client = [ORKTestFactory client];
    client.runLoopMode = dummyRunLoopMode;
    [client get:[[ORKTestFactory baseURL] absoluteString] delegate:loader];
    while ([[NSRunLoop currentRunLoop] runMode:dummyRunLoopMode beforeDate:[[NSRunLoop currentRunLoop] limitDateForMode:dummyRunLoopMode]])
        ;
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

@end
