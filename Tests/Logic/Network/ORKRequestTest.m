//
//  ORKRequestTest.m
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
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
#import "ORKRequest.h"
#import "ORKParams.h"
#import "ORKResponse.h"
#import "ORKURL.h"
#import "ORKDirectory.h"

@interface ORKRequest (Private)
- (void)fireAsynchronousRequest;
- (void)shouldDispatchRequest;
@end

@interface ORKRequestTest : ORKTestCase {
    int _methodInvocationCounter;
}

@end

@implementation ORKRequestTest

- (void)setUp
{
    [ORKTestFactory setUp];

    // Clear the cache directory
    [ORKTestFactory clearCacheDirectory];
    _methodInvocationCounter = 0;
}

- (void)tearDown
{
    [ORKTestFactory tearDown];
}

- (int)incrementMethodInvocationCounter
{
    return _methodInvocationCounter++;
}

/**
 * This spec requires the test Sinatra server to be running
 * `ruby Tests/server.rb`
 */
- (void)testShouldSendMultiPartRequests
{
    NSString *URLString = [NSString stringWithFormat:@"http://127.0.0.1:4567/photo"];
    NSURL *URL = [NSURL URLWithString:URLString];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    ORKParams *params = [[ORKParams params] retain];
    NSString *filePath = [ORKTestFixture pathForFixture:@"blake.png"];
    [params setFile:filePath forParam:@"file"];
    [params setValue:@"this is the value" forParam:@"test"];
    request.method = ORKRequestMethodPOST;
    request.params = params;
    ORKResponse *response = [request sendSynchronously];
    assertThatInteger(response.statusCode, is(equalToInt(200)));
}

#pragma mark - Basics

- (void)testShouldSetURLRequestHTTPBody
{
    NSURL *URL = [NSURL URLWithString:[ORKTestFactory baseURLString]];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    NSString *JSON = @"whatever";
    NSData *data = [JSON dataUsingEncoding:NSASCIIStringEncoding];
    request.HTTPBody = data;
    assertThat(request.URLRequest.HTTPBody, equalTo(data));
    assertThat(request.HTTPBody, equalTo(data));
    assertThat(request.HTTPBodyString, equalTo(JSON));
}

- (void)testShouldSetURLRequestHTTPBodyByString
{
    NSURL *URL = [NSURL URLWithString:[ORKTestFactory baseURLString]];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    NSString *JSON = @"whatever";
    NSData *data = [JSON dataUsingEncoding:NSASCIIStringEncoding];
    request.HTTPBodyString = JSON;
    assertThat(request.URLRequest.HTTPBody, equalTo(data));
    assertThat(request.HTTPBody, equalTo(data));
    assertThat(request.HTTPBodyString, equalTo(JSON));
}

- (void)testShouldTimeoutAtIntervalWhenSentAsynchronously
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    id loaderMock = [OCMockObject partialMockForObject:loader];
    NSURL *URL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:@"/timeout"];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.delegate = loaderMock;
    request.timeoutInterval = 3.0;
    [[[loaderMock expect] andForwardToRealObject] request:request didFailLoadWithError:OCMOCK_ANY];
    [request sendAsynchronously];
    [loaderMock waitForResponse];
    assertThatInt((int)loader.error.code, equalToInt(ORKRequestConnectionTimeoutError));
    [request release];
}

- (void)testShouldTimeoutAtIntervalWhenSentSynchronously
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    id loaderMock = [OCMockObject partialMockForObject:loader];
    NSURL *URL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:@"/timeout"];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.delegate = loaderMock;
    request.timeoutInterval = 3.0;
    [[[loaderMock expect] andForwardToRealObject] request:request didFailLoadWithError:OCMOCK_ANY];
    [request sendSynchronously];
    assertThatInt((int)loader.error.code, equalToInt(ORKRequestConnectionTimeoutError));
    [request release];
}

- (void)testShouldCreateOneTimeoutTimerWhenSentAsynchronously
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:[ORKTestFactory baseURL]];
    request.delegate = loader;
    id requestMock = [OCMockObject partialMockForObject:request];
    [[[requestMock expect] andCall:@selector(incrementMethodInvocationCounter) onObject:self] createTimeoutTimer];
    [requestMock sendAsynchronously];
    [loader waitForResponse];
    assertThatInt(_methodInvocationCounter, equalToInt(1));
    [request release];
}

- (void)testThatSendingDataInvalidatesTimeoutTimer
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    loader.timeout = 3.0;
    NSURL *URL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:@"/timeout"];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.method = ORKRequestMethodPOST;
    request.delegate = loader;
    request.params = [NSDictionary dictionaryWithObject:@"test" forKey:@"test"];
request.timeoutInterval = 1.0;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
    [request release];
}

- (void)testThatRunLoopModePropertyRespected
{
    NSString * const dummyRunLoopMode = @"dummyRunLoopMode";
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:[ORKTestFactory baseURL]];
    request.delegate = loader;
    request.runLoopMode = dummyRunLoopMode;
    [request sendAsynchronously];
    while ([[NSRunLoop currentRunLoop] runMode:dummyRunLoopMode beforeDate:[[NSRunLoop currentRunLoop] limitDateForMode:dummyRunLoopMode]])
        ;
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
    [request release];
}

#pragma mark - Background Policies

#if TARGET_OS_IPHONE

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsORKRequestBackgroundPolicyNone
{
    NSURL *URL = [ORKTestFactory baseURL];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = ORKRequestBackgroundPolicyNone;
    id requestMock = [OCMockObject partialMockForObject:request];
    [[requestMock expect] fireAsynchronousRequest]; // Not sure what else to test on this case
    [request sendAsynchronously];
    [requestMock verify];
}

- (UIApplication *)sharedApplicationMock
{
    id mockApplication = [OCMockObject mockForClass:[UIApplication class]];
    return mockApplication;
}

- (void)stubSharedApplicationWhileExecutingBlock:(void (^)(void))block
{
    [self swizzleMethod:@selector(sharedApplication)
                inClass:[UIApplication class]
             withMethod:@selector(sharedApplicationMock)
              fromClass:[self class]
           executeBlock:block];
}

- (void)testShouldObserveForAppBackgroundTransitionsAndCancelTheRequestWhenBackgroundPolicyIsORKRequestBackgroundPolicyCancel
{
    [self stubSharedApplicationWhileExecutingBlock:^{
        NSURL *URL = [ORKTestFactory baseURL];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.backgroundPolicy = ORKRequestBackgroundPolicyCancel;
        id requestMock = [OCMockObject partialMockForObject:request];
        [[requestMock expect] cancel];
        [requestMock sendAsynchronously];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        [requestMock verify];
    }];
}

- (void)testShouldInformTheDelegateOfCancelWhenTheRequestWhenBackgroundPolicyIsORKRequestBackgroundPolicyCancel
{
    [ORKTestFactory client];
    [self stubSharedApplicationWhileExecutingBlock:^{
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        NSURL *URL = [ORKTestFactory baseURL];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.backgroundPolicy = ORKRequestBackgroundPolicyCancel;
        request.delegate = loader;
        [request sendAsynchronously];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        assertThatBool(loader.wasCancelled, is(equalToBool(YES)));
        [request release];
    }];
}

- (void)testShouldDeallocTheRequestWhenBackgroundPolicyIsORKRequestBackgroundPolicyCancel
{
    [ORKTestFactory client];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    NSURL *URL = [ORKTestFactory baseURL];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = ORKRequestBackgroundPolicyCancel;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatInteger([request retainCount], is(equalToInteger(1)));
    [request release];
}

- (void)testShouldPutTheRequestBackOntoTheQueueWhenBackgroundPolicyIsORKRequestBackgroundPolicyRequeue
{
    [self stubSharedApplicationWhileExecutingBlock:^{
        ORKRequestQueue *queue = [ORKRequestQueue new];
        queue.suspended = YES;
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        NSURL *URL = [ORKTestFactory baseURL];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.backgroundPolicy = ORKRequestBackgroundPolicyRequeue;
        request.delegate = loader;
        request.queue = queue;
        [request sendAsynchronously];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        assertThatBool([request isLoading], is(equalToBool(NO)));
        assertThatBool([queue containsRequest:request], is(equalToBool(YES)));
        [queue release];
    }];
}

- (void)testShouldCreateABackgroundTaskWhenBackgroundPolicyIsORKRequestBackgroundPolicyContinue
{
    NSURL *URL = [ORKTestFactory baseURL];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = ORKRequestBackgroundPolicyContinue;
    [request sendAsynchronously];
    assertThatInt(request.backgroundTaskIdentifier, equalToInt(UIBackgroundTaskInvalid));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsNone
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    NSURL *URL = [ORKTestFactory baseURL];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = ORKRequestBackgroundPolicyNone;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsContinue
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    NSURL *URL = [ORKTestFactory baseURL];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = ORKRequestBackgroundPolicyContinue;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsCancel
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    NSURL *URL = [ORKTestFactory baseURL];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = ORKRequestBackgroundPolicyCancel;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsRequeue
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    NSURL *URL = [ORKTestFactory baseURL];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = ORKRequestBackgroundPolicyRequeue;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

#endif

#pragma mark ORKRequestCachePolicy Tests

- (void)testShouldSendTheRequestWhenTheCachePolicyIsNone
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    NSString *url = [NSString stringWithFormat:@"%@/etags", [ORKTestFactory baseURLString]];
    NSURL *URL = [NSURL URLWithString:url];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.cachePolicy = ORKRequestCachePolicyNone;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

- (void)testShouldCacheTheRequestHeadersAndBodyIncludingOurOwnCustomTimestampHeader
{
    NSString *baseURL = [ORKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    ORKRequestCache *cache = [[ORKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:ORKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:ORKRequestCacheStoragePolicyPermanently];

    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
    NSURL *URL = [NSURL URLWithString:url];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.cachePolicy = ORKRequestCachePolicyEtag;
    request.cache = cache;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
    NSDictionary *headers = [cache headersForRequest:request];
    assertThat([headers valueForKey:@"X-RESTKIT-CACHEDATE"], isNot(nilValue()));
    assertThat([headers valueForKey:@"Etag"], is(equalTo(@"686897696a7c876b7e")));
    assertThat([[cache responseForRequest:request] bodyAsString], is(equalTo(@"This Should Get Cached")));
}

- (void)testShouldGenerateAUniqueCacheKeyBasedOnTheUrlTheMethodAndTheHTTPBody
{
    NSString *baseURL = [ORKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    ORKRequestCache *cache = [[ORKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:ORKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:ORKRequestCacheStoragePolicyPermanently];

    NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
    NSURL *URL = [NSURL URLWithString:url];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.cachePolicy = ORKRequestCachePolicyEtag;
    request.method = ORKRequestMethodDELETE;
    // Don't cache delete. cache key should be nil.
    assertThat([request cacheKey], is(nilValue()));

    request.method = ORKRequestMethodPOST;
    assertThat([request cacheKey], is(nilValue()));

    request.method = ORKRequestMethodPUT;
    assertThat([request cacheKey], is(nilValue()));
}

- (void)testShouldLoadFromCacheWhenWeRecieveA304
{
    NSString *baseURL = [ORKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    ORKRequestCache *cache = [[ORKRequestCache alloc] initWithPath:cachePath
                                storagePolicy:ORKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:ORKRequestCacheStoragePolicyPermanently];
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThat([cache etagForRequest:request], is(equalTo(@"686897696a7c876b7e")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
}

- (void)testShouldUpdateTheInternalCacheDateWhenWeRecieveA304
{
    NSString *baseURL = [ORKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    ORKRequestCache *cache = [[ORKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:ORKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:ORKRequestCacheStoragePolicyPermanently];

    NSDate *internalCacheDate1;
    NSDate *internalCacheDate2;
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThat([cache etagForRequest:request], is(equalTo(@"686897696a7c876b7e")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
        internalCacheDate1 = [cache cacheDateForRequest:request];
    }
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.5]];
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
        internalCacheDate2 = [cache cacheDateForRequest:request];
    }
    assertThat(internalCacheDate1, isNot(internalCacheDate2));
}

- (void)testShouldLoadFromTheCacheIfThereIsAnError
{
    NSString *baseURL = [ORKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    ORKRequestCache *cache = [[ORKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:ORKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:ORKRequestCacheStoragePolicyPermanently];

    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyLoadOnError;
        request.cache = cache;
        request.delegate = loader;
        [request didFailLoadWithError:[NSError errorWithDomain:@"Fake" code:0 userInfo:nil]];
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
}

- (void)testShouldLoadFromTheCacheIfWeAreWithinTheTimeout
{
    NSString *baseURL = [ORKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    ORKRequestCache *cache = [[ORKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:ORKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:ORKRequestCacheStoragePolicyPermanently];

    NSString *url = [NSString stringWithFormat:@"%@/disk/cached", [ORKTestFactory baseURLString]];
    NSURL *URL = [NSURL URLWithString:url];
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 5;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 5;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 5;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 0;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
}

- (void)testShouldLoadFromTheCacheIfWeAreOffline
{
    NSString *baseURL = [ORKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    ORKRequestCache *cache = [[ORKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:ORKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:ORKRequestCacheStoragePolicyPermanently];

    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        loader.timeout = 60;
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        loader.timeout = 60;
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyLoadIfOffline;
        request.cache = cache;
        request.delegate = loader;
        id mock = [OCMockObject partialMockForObject:request];
        BOOL returnValue = NO;
        [[[mock expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldDispatchRequest];
        [mock sendAsynchronously];
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
}

- (void)testShouldCacheTheStatusCodeMIMETypeAndURL
{
    NSString *baseURL = [ORKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];

    ORKRequestCache *cache = [[ORKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:ORKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:ORKRequestCacheStoragePolicyPermanently];
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        NSLog(@"Headers: %@", [cache headersForRequest:request]);
        assertThat([cache etagForRequest:request], is(equalTo(@"686897696a7c876b7e")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [ORKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
        request.cachePolicy = ORKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
        assertThatInteger(loader.response.statusCode, is(equalToInt(200)));
        assertThat(loader.response.MIMEType, is(equalTo(@"text/html")));
        assertThat([loader.response.URL absoluteString], is(equalTo(@"http://127.0.0.1:4567/etags/cached")));
    }
}

- (void)testShouldPostSimpleKeyValuesViaORKParams
{
    ORKParams *params = [ORKParams params];

    [params setValue:@"hello" forParam:@"username"];
    [params setValue:@"password" forParam:@"password"];

    ORKClient *client = [ORKTestFactory client];
    client.cachePolicy = ORKRequestCachePolicyNone;
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    loader.timeout = 20;
    [client post:@"/echo_params" params:params delegate:loader];
    [loader waitForResponse];
    assertThat([loader.response bodyAsString], is(equalTo(@"{\"username\":\"hello\",\"password\":\"password\"}")));
}

- (void)testShouldSetAnEmptyContentBodyWhenParamsIsNil
{
    ORKClient *client = [ORKTestFactory client];
    client.cachePolicy = ORKRequestCachePolicyNone;
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    loader.timeout = 20;
    ORKRequest *request = [client get:@"/echo_params" delegate:loader];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldSetAnEmptyContentBodyWhenQueryParamsIsAnEmptyDictionary
{
    ORKClient *client = [ORKTestFactory client];
    client.cachePolicy = ORKRequestCachePolicyNone;
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    loader.timeout = 20;
    ORKRequest *request = [client get:@"/echo_params" queryParameters:[NSDictionary dictionary] delegate:loader];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldPUTWithParams
{
    ORKClient *client = [ORKTestFactory client];
    ORKParams *params = [ORKParams params];
    [params setValue:@"ddss" forParam:@"username"];
    [params setValue:@"aaaa@aa.com" forParam:@"email"];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    [client put:@"/ping" params:params delegate:loader];
    [loader waitForResponse];
    assertThat([loader.response bodyAsString], is(equalTo(@"{\"username\":\"ddss\",\"email\":\"aaaa@aa.com\"}")));
}

- (void)testShouldAllowYouToChangeTheURL
{
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkey"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    request.URL = [NSURL URLWithString:@"http://restkit.org/gorilla"];
    assertThat([request.URL absoluteString], is(equalTo(@"http://restkit.org/gorilla")));
}

- (void)testShouldAllowYouToChangeTheResourcePath
{
    ORKURL *URL = [[ORKURL URLWithString:@"http://restkit.org"] URLByAppendingResourcePath:@"/monkey"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    request.resourcePath = @"/gorilla";
    assertThat(request.resourcePath, is(equalTo(@"/gorilla")));
}

- (void)testShouldNotRaiseAnExceptionWhenAttemptingToMutateResourcePathOnAnNSURL
{
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkey"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    NSException *exception = nil;
    @try {
        request.resourcePath = @"/gorilla";
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(nilValue()));
    }
}

- (void)testShouldOptionallySkipSSLValidation
{
    NSURL *URL = [NSURL URLWithString:@"https://blakewatters.com/"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    request.disableCertificateValidation = YES;
    ORKResponse *response = [request sendSynchronously];
    assertThatBool([response isOK], is(equalToBool(YES)));
}

- (void)testShouldNotAddANonZeroContentLengthHeaderIfParamsIsSetAndThisIsAGETRequest
{
    ORKClient *client = [ORKTestFactory client];
    client.disableCertificateValidation = YES;
    NSURL *URL = [NSURL URLWithString:@"https://blakewatters.com/"];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    request.delegate = loader;
    request.params = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
    [request send];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldNotAddANonZeroContentLengthHeaderIfParamsIsSetAndThisIsAHEADRequest
{
    ORKClient *client = [ORKTestFactory client];
    client.disableCertificateValidation = YES;
    NSURL *URL = [NSURL URLWithString:@"https://blakewatters.com/"];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    request.delegate = loader;
    request.method = ORKRequestMethodHEAD;
    request.params = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
    [request send];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldLetYouHandleResponsesWithABlock
{
    ORKURL *URL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:@"/ping"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    request.delegate = responseLoader;
    __block BOOL blockInvoked = NO;
    request.onDidLoadResponse = ^ (ORKResponse *response) {
        blockInvoked = YES;
    };
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatBool(blockInvoked, is(equalToBool(YES)));
}

- (void)testShouldLetYouHandleErrorsWithABlock
{
    ORKURL *URL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:@"/fail"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    request.delegate = responseLoader;
    __block BOOL blockInvoked = NO;
    request.onDidLoadResponse = ^ (ORKResponse *response) {
        blockInvoked = YES;
    };
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatBool(blockInvoked, is(equalToBool(YES)));
}

// TODO: Move to ORKRequestCacheTest
- (void)testShouldReturnACachePathWhenTheRequestIsUsingORKParams
{
    ORKParams *params = [ORKParams params];
    [params setValue:@"foo" forParam:@"bar"];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    request.params = params;
    NSString *baseURL = [ORKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    ORKRequestCache *requestCache = [[ORKRequestCache alloc] initWithPath:cachePath storagePolicy:ORKRequestCacheStoragePolicyForDurationOfSession];
    NSString *requestCachePath = [requestCache pathForRequest:request];
    NSArray *pathComponents = [requestCachePath pathComponents];
    NSString *cacheFile = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange([pathComponents count] - 2, 2)]];
    assertThat(cacheFile, is(equalTo(@"SessionStore/4ba47367884760141da2e38fda525a1f")));
}

- (void)testShouldReturnNilForCachePathWhenTheRequestIsADELETE
{
    ORKParams *params = [ORKParams params];
    [params setValue:@"foo" forParam:@"bar"];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    request.method = ORKRequestMethodDELETE;
    NSString *baseURL = [ORKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    ORKRequestCache *requestCache = [[ORKRequestCache alloc] initWithPath:cachePath storagePolicy:ORKRequestCacheStoragePolicyForDurationOfSession];
    NSString *requestCachePath = [requestCache pathForRequest:request];
    assertThat(requestCachePath, is(nilValue()));
}

- (void)testShouldBuildAProperAuthorizationHeaderForOAuth1
{
    ORKRequest *request = [ORKRequest requestWithURL:[ORKURL URLWithString:@"http://restkit.org/this?that=foo&bar=word"]];
    request.authenticationType = ORKRequestAuthenticationTypeOAuth1;
    request.OAuth1AccessToken = @"12345";
    request.OAuth1AccessTokenSecret = @"monkey";
    request.OAuth1ConsumerKey = @"another key";
    request.OAuth1ConsumerSecret = @"more data";
    [request prepareURLRequest];
    NSString *authorization = [request.URLRequest valueForHTTPHeaderField:@"Authorization"];
    assertThat(authorization, isNot(nilValue()));
}

- (void)testShouldBuildAProperAuthorizationHeaderForOAuth1ThatIsAcceptedByServer
{
    ORKRequest *request = [ORKRequest requestWithURL:[ORKURL URLWithString:[NSString stringWithFormat:@"%@/oauth1/me", [ORKTestFactory baseURLString]]]];
    request.authenticationType = ORKRequestAuthenticationTypeOAuth1;
    request.OAuth1AccessToken = @"12345";
    request.OAuth1AccessTokenSecret = @"monkey";
    request.OAuth1ConsumerKey = @"restkit_key";
    request.OAuth1ConsumerSecret = @"restkit_secret";
    [request prepareURLRequest];
    NSString *authorization = [request.URLRequest valueForHTTPHeaderField:@"Authorization"];
    assertThat(authorization, isNot(nilValue()));

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    request.delegate = responseLoader;
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.successful, is(equalToBool(YES)));
}

- (void)testImproperOAuth1CredentialsShouldFall
{
    ORKRequest *request = [ORKRequest requestWithURL:[ORKURL URLWithString:[NSString stringWithFormat:@"%@/oauth1/me", [ORKTestFactory baseURLString]]]];
    request.authenticationType = ORKRequestAuthenticationTypeOAuth1;
    request.OAuth1AccessToken = @"12345";
    request.OAuth1AccessTokenSecret = @"monkey";
    request.OAuth1ConsumerKey = @"restkit_key";
    request.OAuth1ConsumerSecret = @"restkit_incorrect_secret";
    [request prepareURLRequest];
    NSString *authorization = [request.URLRequest valueForHTTPHeaderField:@"Authorization"];
    assertThat(authorization, isNot(nilValue()));

    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    request.delegate = responseLoader;
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.successful, is(equalToBool(YES)));
}

- (void)testOnDidLoadResponseBlockInvocation
{
    ORKURL *URL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:@"/200"];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    __block ORKResponse *blockResponse = nil;
    request.onDidLoadResponse = ^ (ORKResponse *response) {
        blockResponse = response;
    };
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThat(blockResponse, is(notNilValue()));
}

- (void)testOnDidFailLoadWithErrorBlockInvocation
{
    ORKURL *URL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:@"/503"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    __block NSError *blockError = nil;
    request.onDidFailLoadWithError = ^ (NSError *error) {
        blockError = error;
    };
    NSError *expectedError = [NSError errorWithDomain:@"Test" code:1234 userInfo:nil];
    [request didFailLoadWithError:expectedError];
    assertThat(blockError, is(notNilValue()));
}

- (void)testShouldBuildAProperRequestWhenSettingBodyByMIMEType
{
    ORKClient *client = [ORKTestFactory client];
    NSDictionary *bodyParams = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:10], @"number",
                                @"JSON String", @"string",
                                nil];
    ORKRequest *request = [client requestWithResourcePath:@"/upload"];
    [request setMethod:ORKRequestMethodPOST];
    [request setBody:bodyParams forMIMEType:ORKMIMETypeJSON];
    [request prepareURLRequest];
    assertThat(request.HTTPBodyString, is(equalTo(@"{\"number\":10,\"string\":\"JSON String\"}")));
}

- (void)testThatGETRequestsAreConsideredCacheable
{
    ORKRequest *request = [ORKRequest new];
    request.method = ORKRequestMethodGET;
    assertThatBool([request isCacheable], is(equalToBool(YES)));
}

- (void)testThatPOSTRequestsAreNotConsideredCacheable
{
    ORKRequest *request = [ORKRequest new];
    request.method = ORKRequestMethodPOST;
    assertThatBool([request isCacheable], is(equalToBool(NO)));
}

- (void)testThatPUTRequestsAreNotConsideredCacheable
{
    ORKRequest *request = [ORKRequest new];
    request.method = ORKRequestMethodPUT;
    assertThatBool([request isCacheable], is(equalToBool(NO)));
}

- (void)testThatDELETERequestsAreNotConsideredCacheable
{
    ORKRequest *request = [ORKRequest new];
    request.method = ORKRequestMethodDELETE;
    assertThatBool([request isCacheable], is(equalToBool(NO)));
}

- (void)testInvocationOfDidReceiveResponse
{
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];
    id loaderMock = [OCMockObject partialMockForObject:loader];
    NSURL *URL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:@"/200"];
    ORKRequest *request = [[ORKRequest alloc] initWithURL:URL];
    request.delegate = loaderMock;
    [[loaderMock expect] request:request didReceiveResponse:OCMOCK_ANY];
    [request sendAsynchronously];
    [loaderMock waitForResponse];
    [request release];
    [loaderMock verify];
}

- (void)testThatIsLoadingIsNoDuringDidFailWithErrorCallback
{
    NSURL *URL = [[NSURL alloc] initWithString:@"http://localhost:8765"];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];

    ORKClient *client = [ORKClient clientWithBaseURL:URL];
    ORKRequest *request = [client requestWithResourcePath:@"/invalid"];
    request.method = ORKRequestMethodGET;
    request.delegate = loader;
    request.onDidFailLoadWithError = ^(NSError *error) {
        assertThatBool([request isLoading], is(equalToBool(NO)));
    };
    [request sendAsynchronously];
    [loader waitForResponse];
}

- (void)testThatIsLoadedIsYesDuringDidFailWithErrorCallback
{
    NSURL *URL = [[NSURL alloc] initWithString:@"http://localhost:8765"];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];

    ORKClient *client = [ORKClient clientWithBaseURL:URL];
    ORKRequest *request = [client requestWithResourcePath:@"/invalid"];
    request.method = ORKRequestMethodGET;
    request.delegate = loader;
    request.onDidFailLoadWithError = ^(NSError *error) {
        assertThatBool([request isLoaded], is(equalToBool(YES)));
    };
    [request sendAsynchronously];
    [loader waitForResponse];
}

- (void)testUnavailabilityOfResponseInDidFailWithErrorCallback
{
    NSURL *URL = [[NSURL alloc] initWithString:@"http://localhost:8765"];
    ORKTestResponseLoader *loader = [ORKTestResponseLoader responseLoader];

    ORKClient *client = [ORKClient clientWithBaseURL:URL];
    ORKRequest *request = [client requestWithResourcePath:@"/invalid"];
    request.method = ORKRequestMethodGET;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThat(request.response, is(nilValue()));
}

- (void)testAvailabilityOfResponseWhenFailedDueTo500Response
{
    ORKURL *URL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:@"/fail"];
    ORKRequest *request = [ORKRequest requestWithURL:URL];
    ORKTestResponseLoader *responseLoader = [ORKTestResponseLoader responseLoader];
    request.delegate = responseLoader;
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(request.response, is(notNilValue()));
    assertThatInteger(request.response.statusCode, is(equalToInteger(500)));
}

@end
