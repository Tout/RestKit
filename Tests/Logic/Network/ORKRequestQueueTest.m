//
//  ORKRequestQueueTest.m
//  RestKit
//
//  Created by Blake Watters on 3/28/11.
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

// Expose the request queue's [add|remove]LoadingRequest methods testing purposes...
@interface ORKRequestQueue ()
- (void)addLoadingRequest:(ORKRequest *)request;
- (void)removeLoadingRequest:(ORKRequest *)request;
@end

@interface ORKRequestQueueTest : ORKTestCase {
    NSAutoreleasePool *_autoreleasePool;
}

@end


@implementation ORKRequestQueueTest

- (void)setUp
{
    _autoreleasePool = [NSAutoreleasePool new];
}

- (void)tearDown
{
    [_autoreleasePool drain];
}

- (void)testShouldBeSuspendedWhenInitialized
{
    ORKRequestQueue *queue = [ORKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    [queue release];
}

#if TARGET_OS_IPHONE

// TODO: Crashing...
- (void)testShouldSuspendTheQueueOnTransitionToTheBackground
{
    return;
    ORKRequestQueue *queue = [ORKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    queue.suspended = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    [queue release];
}

- (void)testShouldUnsuspendTheQueueOnTransitionToTheForeground
{
    // TODO: Crashing...
    return;
    ORKRequestQueue *queue = [ORKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    assertThatBool(queue.suspended, is(equalToBool(NO)));
    [queue release];
}

#endif

- (void)testShouldInformTheDelegateWhenSuspended
{
    ORKRequestQueue *queue = [ORKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    queue.suspended = NO;
    OCMockObject *delegateMock = [OCMockObject niceMockForProtocol:@protocol(ORKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueWasSuspended:queue];
    queue.delegate = (NSObject<ORKRequestQueueDelegate> *)delegateMock;
    queue.suspended = YES;
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateWhenUnsuspended
{
    ORKRequestQueue *queue = [ORKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    OCMockObject *delegateMock = [OCMockObject niceMockForProtocol:@protocol(ORKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueWasUnsuspended:queue];
    queue.delegate = (NSObject<ORKRequestQueueDelegate> *)delegateMock;
    queue.suspended = NO;
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateOnTransitionFromEmptyToProcessing
{
    ORKRequestQueue *queue = [ORKRequestQueue new];
    OCMockObject *delegateMock = [OCMockObject niceMockForProtocol:@protocol(ORKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueDidBeginLoading:queue];
    queue.delegate = (NSObject<ORKRequestQueueDelegate> *)delegateMock;
    NSURL *URL = [ORKTestFactory baseURL];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    [queue addLoadingRequest:request];
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateOnTransitionFromProcessingToEmpty
{
    ORKRequestQueue *queue = [ORKRequestQueue new];
    OCMockObject *delegateMock = [OCMockObject niceMockForProtocol:@protocol(ORKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueDidFinishLoading:queue];
    queue.delegate = (NSObject<ORKRequestQueueDelegate> *)delegateMock;
    NSURL *URL = [ORKTestFactory baseURL];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    [queue addLoadingRequest:request];
    [queue removeLoadingRequest:request];
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateOnTransitionFromProcessingToEmptyForQueuesWithASingleRequest
{
    OCMockObject *delegateMock = [OCMockObject niceMockForProtocol:@protocol(ORKRequestQueueDelegate)];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];

    NSString *url = [NSString stringWithFormat:@"%@/ok-with-delay/0.3", [ORKTestFactory baseURLString]];
    NSURL *URL = [NSURL URLWithString:url];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.delegate = loader;

    ORKRequestQueue *queue = [ORKRequestQueue new];
    queue.delegate = (NSObject<ORKRequestQueueDelegate> *)delegateMock;
    [[delegateMock expect] requestQueueDidFinishLoading:queue];
    [queue addRequest:request];
    [queue start];
    [loader waitForResponse];
    [delegateMock verify];
    [queue release];
}

// TODO: These tests cannot pass in the unit testing environment... Need to migrate to an integration
// testing area
//- (void)testShouldBeginSpinningTheNetworkActivityIfAsked {
//    [[UIApplication sharedApplication] rk_resetNetworkActivity];
//    ORKRequestQueue *queue = [ORKRequestQueue new];
//    queue.showsNetworkActivityIndicatorWhenBusy = YES;
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(NO)));
//    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [queue release];
//}
//
//- (void)testShouldStopSpinningTheNetworkActivityIfAsked {
//    [[UIApplication sharedApplication] rk_resetNetworkActivity];
//    ORKRequestQueue *queue = [ORKRequestQueue new];
//    queue.showsNetworkActivityIndicatorWhenBusy = YES;
//    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [queue setValue:[NSNumber numberWithInt:0] forKey:@"loadingCount"];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(NO)));
//    [queue release];
//}
//
//- (void)testShouldJointlyManageTheNetworkActivityIndicator {
//    [[UIApplication sharedApplication] rk_resetNetworkActivity];
//    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
//    loader.timeout = 10;
//
//    ORKRequestQueue *queue1 = [ORKRequestQueue new];
//    queue1.showsNetworkActivityIndicatorWhenBusy = YES;
//    NSString *url1 = [NSString stringWithFormat:@"%@/ok-with-delay/2.0", [ORKTestFactory baseURL]];
//    NSURL *URL1 = [NSURL URLWithString:url1];
//    ORKRequest *request1 = [[ORKRequest alloc] initWithURL:URL1];
//    request1.delegate = loader;
//
//    ORKRequestQueue *queue2 = [ORKRequestQueue new];
//    queue2.showsNetworkActivityIndicatorWhenBusy = YES;
//    NSString *url2 = [NSString stringWithFormat:@"%@/ok-with-delay/2.0", [ORKTestFactory baseURL]];
//    NSURL *URL2 = [NSURL URLWithString:url2];
//    ORKRequest *request2 = [[ORKRequest alloc] initWithURL:URL2];
//    request2.delegate = loader;
//
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(NO)));
//    [queue1 addRequest:request1];
//    [queue1 start];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [queue2 addRequest:request2];
//    [queue2 start];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [loader waitForResponse];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [loader waitForResponse];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(NO)));
//}

- (void)testShouldLetYouReturnAQueueByName
{
    ORKRequestQueue *queue = [ORKRequestQueue requestQueueWithName:@"Images"];
    assertThat(queue, isNot(nilValue()));
    assertThat(queue.name, is(equalTo(@"Images")));
}

- (void)testShouldReturnAnExistingQueueByName
{
    ORKRequestQueue *queue = [ORKRequestQueue requestQueueWithName:@"Images2"];
    assertThat(queue, isNot(nilValue()));
    ORKRequestQueue *secondQueue = [ORKRequestQueue requestQueueWithName:@"Images2"];
    assertThat(queue, is(equalTo(secondQueue)));
}

- (void)testShouldReturnTheQueueWithoutAModifiedRetainCount
{
    ORKRequestQueue *queue = [ORKRequestQueue requestQueueWithName:@"Images3"];
    assertThat(queue, isNot(nilValue()));
    assertThatUnsignedInteger([queue retainCount], is(equalToInt(1)));
}

- (void)testShouldReturnYESWhenAQueueExistsWithAGivenName
{
    assertThatBool([ORKRequestQueue requestQueueExistsWithName:@"Images4"], is(equalToBool(NO)));
    [ORKRequestQueue requestQueueWithName:@"Images4"];
    assertThatBool([ORKRequestQueue requestQueueExistsWithName:@"Images4"], is(equalToBool(YES)));
}

- (void)testShouldRemoveTheQueueFromTheNamedInstancesOnDealloc
{
    // TODO: Crashing...
    return;
    ORKRequestQueue *queue = [ORKRequestQueue requestQueueWithName:@"Images5"];
    assertThat(queue, isNot(nilValue()));
    assertThatBool([ORKRequestQueue requestQueueExistsWithName:@"Images5"], is(equalToBool(YES)));
    [queue release];
    assertThatBool([ORKRequestQueue requestQueueExistsWithName:@"Images5"], is(equalToBool(NO)));
}

- (void)testShouldReturnANewOwningReferenceViaNewRequestWithName
{
    ORKRequestQueue *requestQueue = [ORKRequestQueue newRequestQueueWithName:@"Images6"];
    assertThat(requestQueue, isNot(nilValue()));
    assertThatUnsignedInteger([requestQueue retainCount], is(equalToInt(1)));
}

- (void)testShouldReturnNilIfNewRequestQueueWithNameIsCalledForAnExistingName
{
    ORKRequestQueue *queue = [ORKRequestQueue newRequestQueueWithName:@"Images7"];
    assertThat(queue, isNot(nilValue()));
    ORKRequestQueue *queue2 = [ORKRequestQueue newRequestQueueWithName:@"Images7"];
    assertThat(queue2, is(nilValue()));
}

- (void)testShouldRemoveItemsFromTheQueueWithAnUnmappableResponse
{
    ORKRequestQueue *queue = [ORKRequestQueue requestQueue];
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    ORKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/403"];
    objectLoader.delegate = loader;
    [queue addRequest:(ORKRequest *)objectLoader];
    [queue start];
    [loader waitForResponse];
    assertThatUnsignedInteger(queue.loadingCount, is(equalToInt(0)));
}

- (void)testThatSendingRequestToInvalidURLDoesNotGetSentTwice
{
    ORKRequestQueue *queue = [ORKRequestQueue requestQueue];
    NSURL *URL = [NSURL URLWithString:@"http://localhost:7662/ORKRequestQueueExample"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    id mockResponseLoader = [OCMockObject partialMockForObject:responseLoader];
    [[[mockResponseLoader expect] andForwardToRealObject] request:request didFailLoadWithError:OCMOCK_ANY];
    request.delegate = responseLoader;
    id mockQueueDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKRequestQueueDelegate)];
    __block NSUInteger invocationCount = 0;
    [[mockQueueDelegate stub] requestQueue:queue willSendRequest:[OCMArg checkWithBlock:^BOOL(id request) {
        invocationCount++;
        return YES;
    }]];
    [queue addRequest:request];
    queue.delegate = mockQueueDelegate;
    [queue start];
    [mockResponseLoader waitForResponse];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    [mockResponseLoader verify];
    assertThatInteger(invocationCount, is(equalToInteger(1)));
}

@end
