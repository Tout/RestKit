//
//  ORKRequest.m
//  RestKit
//
//  Created by Jeremy Ellison on 7/27/09.
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

#import "ORKRequest.h"
#import "ORKResponse.h"
#import "NSDictionary+ORKRequestSerialization.h"
#import "ORKNotifications.h"
#import "Support.h"
#import "ORKURL.h"
#import "NSData+ORKAdditions.h"
#import "NSString+ORKAdditions.h"
#import "ORKLog.h"
#import "ORKRequestCache.h"
#import "GCOAuth.h"
#import "NSURL+ORKAdditions.h"
#import "ORKReachabilityObserver.h"
#import "ORKRequestQueue.h"
#import "ORKParams.h"
#import "ORKParserRegistry.h"
#import "ORKRequestSerialization.h"

NSString *ORKRequestMethodNameFromType(ORKRequestMethod method) {
    switch (method) {
        case ORKRequestMethodGET:
            return @"GET";
            break;

        case ORKRequestMethodPOST:
            return @"POST";
            break;

        case ORKRequestMethodPUT:
            return @"PUT";
            break;

        case ORKRequestMethodDELETE:
            return @"DELETE";
            break;

        case ORKRequestMethodHEAD:
            return @"HEAD";
            break;

        default:
            break;
    }

    return nil;
}

ORKRequestMethod ORKRequestMethodTypeFromName(NSString *methodName) {
    if ([methodName isEqualToString:@"GET"]) {
        return ORKRequestMethodGET;
    } else if ([methodName isEqualToString:@"POST"]) {
        return ORKRequestMethodPOST;
    } else if ([methodName isEqualToString:@"PUT"]) {
        return ORKRequestMethodPUT;
    } else if ([methodName isEqualToString:@"DELETE"]) {
        return ORKRequestMethodDELETE;
    } else if ([methodName isEqualToString:@"HEAD"]) {
        return ORKRequestMethodHEAD;
    }

    return ORKRequestMethodInvalid;
}

// Set Logging Component
#undef ORKLogComponent
#define ORKLogComponent lcl_cRestKitNetwork

@interface ORKRequest ()
@property (nonatomic, assign, readwrite, getter = isLoaded) BOOL loaded;
@property (nonatomic, assign, readwrite, getter = isLoading) BOOL loading;
@property (nonatomic, assign, readwrite, getter = isCancelled) BOOL cancelled;
@property (nonatomic, retain, readwrite) ORKResponse *response;
@end

@implementation ORKRequest
@class GCOAuth;

@synthesize URL = _URL;
@synthesize URLRequest = _URLRequest;
@synthesize delegate = _delegate;
@synthesize additionalHTTPHeaders = _additionalHTTPHeaders;
@synthesize params = _params;
@synthesize userData = _userData;
@synthesize authenticationType = _authenticationType;
@synthesize username = _username;
@synthesize password = _password;
@synthesize method = _method;
@synthesize cachePolicy = _cachePolicy;
@synthesize cache = _cache;
@synthesize cacheTimeoutInterval = _cacheTimeoutInterval;
@synthesize OAuth1ConsumerKey = _OAuth1ConsumerKey;
@synthesize OAuth1ConsumerSecret = _OAuth1ConsumerSecret;
@synthesize OAuth1AccessToken = _OAuth1AccessToken;
@synthesize OAuth1AccessTokenSecret = _OAuth1AccessTokenSecret;
@synthesize OAuth2AccessToken = _OAuth2AccessToken;
@synthesize OAuth2RefreshToken = _OAuth2RefreshToken;
@synthesize queue = _queue;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize reachabilityObserver = _reachabilityObserver;
@synthesize defaultHTTPEncoding = _defaultHTTPEncoding;
@synthesize configurationDelegate = _configurationDelegate;
@synthesize onDidLoadResponse;
@synthesize onDidFailLoadWithError;
@synthesize additionalRootCertificates = _additionalRootCertificates;
@synthesize disableCertificateValidation = _disableCertificateValidation;
@synthesize followRedirect = _followRedirect;
@synthesize runLoopMode = _runLoopMode;
@synthesize loaded = _loaded;
@synthesize loading = _loading;
@synthesize response = _response;
@synthesize cancelled = _cancelled;

#if TARGET_OS_IPHONE
@synthesize backgroundPolicy = _backgroundPolicy;
@synthesize backgroundTaskIdentifier = _backgroundTaskIdentifier;
#endif

+ (ORKRequest *)requestWithURL:(NSURL *)URL
{
    return [[[ORKRequest alloc] initWithURL:URL] autorelease];
}

- (id)initWithURL:(NSURL *)URL
{
    self = [self init];
    if (self) {
        _URL = [URL retain];
        [self reset];
        _authenticationType = ORKRequestAuthenticationTypeNone;
        _cachePolicy = ORKRequestCachePolicyDefault;
        _cacheTimeoutInterval = 0;
        _timeoutInterval = 120.0;
        _defaultHTTPEncoding = NSUTF8StringEncoding;
        _followRedirect = YES;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.runLoopMode = NSRunLoopCommonModes;
#if TARGET_OS_IPHONE
        _backgroundPolicy = ORKRequestBackgroundPolicyNone;
        _backgroundTaskIdentifier = 0;
        BOOL backgroundOK = &UIBackgroundTaskInvalid != NULL;
        if (backgroundOK) {
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
#endif
    }

    return self;
}

- (void)reset
{
    if (self.isLoading) {
        ORKLogWarning(@"Request was reset while loading: %@. Canceling.", self);
        [self cancel];
    }
    [_URLRequest release];
    _URLRequest = [[NSMutableURLRequest alloc] initWithURL:_URL];
    [_URLRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [_connection release];
    _connection = nil;
    self.loading = NO;
    self.loaded = NO;
    self.cancelled = NO;
}

- (void)cleanupBackgroundTask
{
    #if TARGET_OS_IPHONE
    BOOL backgroundOK = &UIBackgroundTaskInvalid != NULL;
    if (backgroundOK && UIBackgroundTaskInvalid == self.backgroundTaskIdentifier) {
        return;
    }

    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
            [app endBackgroundTask:_backgroundTaskIdentifier];
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
    #endif
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.delegate = nil;
    if (_onDidLoadResponse) Block_release(_onDidLoadResponse);
    if (_onDidFailLoadWithError) Block_release(_onDidFailLoadWithError);

    _delegate = nil;
    _configurationDelegate = nil;
    [_reachabilityObserver release];
    _reachabilityObserver = nil;
    [_connection cancel];
    [_connection release];
    _connection = nil;
    [_response release];
    _response = nil;
    [_userData release];
    _userData = nil;
    [_URL release];
    _URL = nil;
    [_URLRequest release];
    _URLRequest = nil;
    [_params release];
    _params = nil;
    [_additionalHTTPHeaders release];
    _additionalHTTPHeaders = nil;
    [_username release];
    _username = nil;
    [_password release];
    _password = nil;
    [_cache release];
    _cache = nil;
    [_OAuth1ConsumerKey release];
    _OAuth1ConsumerKey = nil;
    [_OAuth1ConsumerSecret release];
    _OAuth1ConsumerSecret = nil;
    [_OAuth1AccessToken release];
    _OAuth1AccessToken = nil;
    [_OAuth1AccessTokenSecret release];
    _OAuth1AccessTokenSecret = nil;
    [_OAuth2AccessToken release];
    _OAuth2AccessToken = nil;
    [_OAuth2RefreshToken release];
    _OAuth2RefreshToken = nil;
    [onDidFailLoadWithError release];
    onDidFailLoadWithError = nil;
    [onDidLoadResponse release];
    onDidLoadResponse = nil;
    [self invalidateTimeoutTimer];
    [_timeoutTimer release];
    _timeoutTimer = nil;
    [_runLoopMode release];
    _runLoopMode = nil;

    // Cleanup a background task if there is any
    [self cleanupBackgroundTask];

    [super dealloc];
}

- (BOOL)shouldSendParams
{
    return (_params && (_method != ORKRequestMethodGET && _method != ORKRequestMethodHEAD));
}

- (void)setRequestBody
{
    if ([self shouldSendParams]) {
        // Prefer the use of a stream over a raw body
        if ([_params respondsToSelector:@selector(HTTPBodyStream)]) {
            // NOTE: This causes the stream to be retained. For ORKParams, this will
            // cause a leak unless the stream is released. See [ORKParams close]
            [_URLRequest setHTTPBodyStream:[_params HTTPBodyStream]];
        } else {
            [_URLRequest setHTTPBody:[_params HTTPBody]];
        }
    }
}

- (NSData *)HTTPBody
{
    return self.URLRequest.HTTPBody;
}

- (void)setHTTPBody:(NSData *)HTTPBody
{
    [self.URLRequest setHTTPBody:HTTPBody];
}

- (NSString *)HTTPBodyString
{
    return [[[NSString alloc] initWithData:self.URLRequest.HTTPBody encoding:NSASCIIStringEncoding] autorelease];
}

- (void)setHTTPBodyString:(NSString *)HTTPBodyString
{
    [self.URLRequest setHTTPBody:[HTTPBodyString dataUsingEncoding:NSASCIIStringEncoding]];
}

- (void)addHeadersToRequest
{
    NSString *header = nil;
    for (header in _additionalHTTPHeaders) {
        [_URLRequest setValue:[_additionalHTTPHeaders valueForKey:header] forHTTPHeaderField:header];
    }

    if ([self shouldSendParams]) {
        // Temporarily support older ORKRequestSerializable implementations
        if ([_params respondsToSelector:@selector(HTTPHeaderValueForContentType)]) {
            [_URLRequest setValue:[_params HTTPHeaderValueForContentType] forHTTPHeaderField:@"Content-Type"];
        } else if ([_params respondsToSelector:@selector(ContentTypeHTTPHeader)]) {
            [_URLRequest setValue:[_params performSelector:@selector(ContentTypeHTTPHeader)] forHTTPHeaderField:@"Content-Type"];
        }
        if ([_params respondsToSelector:@selector(HTTPHeaderValueForContentLength)]) {
            [_URLRequest setValue:[NSString stringWithFormat:@"%d", [_params HTTPHeaderValueForContentLength]] forHTTPHeaderField:@"Content-Length"];
        }
    } else {
        [_URLRequest setValue:@"0" forHTTPHeaderField:@"Content-Length"];
    }

    // Add authentication headers so we don't have to deal with an extra cycle for each message requiring basic auth.
    if (self.authenticationType == ORKRequestAuthenticationTypeHTTPBasic && _username && _password) {
        CFHTTPMessageRef dummyRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)[self HTTPMethod], (CFURLRef)[self URL], kCFHTTPVersion1_1);
        if (dummyRequest) {
          CFHTTPMessageAddAuthentication(dummyRequest, nil, (CFStringRef)_username, (CFStringRef)_password, kCFHTTPAuthenticationSchemeBasic, FALSE);
          CFStringRef authorizationString = CFHTTPMessageCopyHeaderFieldValue(dummyRequest, CFSTR("Authorization"));
          if (authorizationString) {
            [_URLRequest setValue:(NSString *)authorizationString forHTTPHeaderField:@"Authorization"];
            CFRelease(authorizationString);
          }
          CFRelease(dummyRequest);
        }
    }

    // Add OAuth headers if necessary
    // OAuth 1
    if (self.authenticationType == ORKRequestAuthenticationTypeOAuth1) {
        NSURLRequest *echo = nil;

        // use the suitable parameters dict
        NSDictionary *parameters = nil;
        if ([self.params isKindOfClass:[ORKParams class]])
            parameters = [(ORKParams *)self.params dictionaryOfPlainTextParams];
        else
            parameters = [_URL queryParameters];
        
        NSString *methodString = ORKRequestMethodNameFromType(self.method);        
        echo = [GCOAuth URLRequestForPath:[_URL path] 
                               HTTPMethod:methodString 
                               parameters:(self.method == ORKRequestMethodGET) ? [_URL queryParameters] : parameters 
                                   scheme:[_URL scheme] 
                                     host:[_URL host] 
                              consumerKey:self.OAuth1ConsumerKey 
                           consumerSecret:self.OAuth1ConsumerSecret 
                              accessToken:self.OAuth1AccessToken 
                              tokenSecret:self.OAuth1AccessTokenSecret];
        [_URLRequest setValue:[echo valueForHTTPHeaderField:@"Authorization"] forHTTPHeaderField:@"Authorization"];
        [_URLRequest setValue:[echo valueForHTTPHeaderField:@"Accept-Encoding"] forHTTPHeaderField:@"Accept-Encoding"];
        [_URLRequest setValue:[echo valueForHTTPHeaderField:@"User-Agent"] forHTTPHeaderField:@"User-Agent"];
    }

    // OAuth 2 valid request
    if (self.authenticationType == ORKRequestAuthenticationTypeOAuth2) {
        NSString *authorizationString = [NSString stringWithFormat:@"OAuth2 %@", self.OAuth2AccessToken];
        [_URLRequest setValue:authorizationString forHTTPHeaderField:@"Authorization"];
    }

    if (self.cachePolicy & ORKRequestCachePolicyEtag) {
        NSString *etag = [self.cache etagForRequest:self];
        if (etag) {
            ORKLogTrace(@"Setting If-None-Match header to '%@'", etag);
            [_URLRequest setValue:etag forHTTPHeaderField:@"If-None-Match"];
        }
    }
}

// Setup the NSURLRequest. The request must be prepared right before dispatching
- (BOOL)prepareURLRequest
{
    [_URLRequest setHTTPMethod:[self HTTPMethod]];

    if ([self.delegate respondsToSelector:@selector(requestWillPrepareForSend:)]) {
        [self.delegate requestWillPrepareForSend:self];
    }

    [self setRequestBody];
    [self addHeadersToRequest];

    NSString *body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
    ORKLogTrace(@"Prepared %@ URLRequest '%@'. HTTP Headers: %@. HTTP Body: %@.", [self HTTPMethod], _URLRequest, [_URLRequest allHTTPHeaderFields], body);
    [body release];

    return YES;
}

- (void)cancelAndInformDelegate:(BOOL)informDelegate
{
    self.cancelled = YES;
    [_connection cancel];
    [_connection release];
    _connection = nil;
    [self invalidateTimeoutTimer];
    self.loading = NO;

    if (informDelegate && [_delegate respondsToSelector:@selector(requestDidCancelLoad:)]) {
        [_delegate requestDidCancelLoad:self];
    }
}

- (NSString *)HTTPMethod
{
    return ORKRequestMethodNameFromType(self.method);
}

// NOTE: We could factor the knowledge about the queue out of ORKRequest entirely, but it will break behavior.
- (void)send
{
    NSAssert(NO == self.isLoading || NO == self.isLoaded, @"Cannot send a request that is loading or loaded without resetting it first.");
    if (self.queue) {
        [self.queue addRequest:self];
    } else {
        [self sendAsynchronously];
    }
}

- (void)fireAsynchronousRequest
{
    ORKLogDebug(@"Sending asynchronous %@ request to URL %@.", [self HTTPMethod], [[self URL] absoluteString]);
    if (![self prepareURLRequest]) {
        ORKLogWarning(@"Failed to send request asynchronously: prepareURLRequest returned NO.");
        return;
    }

    self.loading = YES;

    if ([self.delegate respondsToSelector:@selector(requestDidStartLoad:)]) {
        [self.delegate requestDidStartLoad:self];
    }

    ORKResponse *response = [[[ORKResponse alloc] initWithRequest:self] autorelease];

    _connection = [[[[NSURLConnection alloc] initWithRequest:_URLRequest delegate:response startImmediately:NO] autorelease] retain];
    [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:self.runLoopMode];
    [_connection start];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKRequestSentNotification object:self userInfo:nil];
}

- (BOOL)shouldLoadFromCache
{
    // if ORKRequestCachePolicyEnabled or if ORKRequestCachePolicyTimeout and we are in the timeout
    if ([self.cache hasResponseForRequest:self]) {
        if (self.cachePolicy & ORKRequestCachePolicyEnabled) {
            return YES;
        } else if (self.cachePolicy & ORKRequestCachePolicyTimeout) {
            NSDate *date = [self.cache cacheDateForRequest:self];
            NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:date];
            return interval <= self.cacheTimeoutInterval;
        }
    }
    return NO;
}

- (ORKResponse *)loadResponseFromCache
{
    ORKLogDebug(@"Found cached content, loading...");
    return [self.cache responseForRequest:self];
}

- (BOOL)shouldDispatchRequest
{
    if (nil == self.reachabilityObserver || NO == [self.reachabilityObserver isReachabilityDetermined]) {
        return YES;
    }

    return [self.reachabilityObserver isNetworkReachable];
}

- (void)sendAsynchronously
{
    NSAssert(NO == self.loading || NO == self.loaded, @"Cannot send a request that is loading or loaded without resetting it first.");
    _sentSynchronously = NO;
    if ([self shouldLoadFromCache]) {
        ORKResponse *response = [self loadResponseFromCache];
        self.loading = YES;
        [self performSelector:@selector(didFinishLoad:) withObject:response afterDelay:0];
    } else if ([self shouldDispatchRequest]) {
        [self createTimeoutTimer];
#if TARGET_OS_IPHONE
        // Background Request Policy support
        UIApplication *app = [UIApplication sharedApplication];
        if (self.backgroundPolicy == ORKRequestBackgroundPolicyNone ||
            NO == [app respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
            // No support for background (iOS 3.x) or the policy is none -- just fire the request
            [self fireAsynchronousRequest];
        } else if (self.backgroundPolicy == ORKRequestBackgroundPolicyCancel || self.backgroundPolicy == ORKRequestBackgroundPolicyRequeue) {
            // For cancel or requeue behaviors, we watch for background transition notifications
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(appDidEnterBackgroundNotification:)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
            [self fireAsynchronousRequest];
        } else if (self.backgroundPolicy == ORKRequestBackgroundPolicyContinue) {
            ORKLogInfo(@"Beginning background task to perform processing...");

            // Fork a background task for continueing a long-running request
            __block ORKRequest *weakSelf = self;
            __block id<ORKRequestDelegate> weakDelegate = _delegate;
            _backgroundTaskIdentifier = [app beginBackgroundTaskWithExpirationHandler:^{
                ORKLogInfo(@"Background request time expired, canceling request.");

                [weakSelf cancelAndInformDelegate:NO];
                [weakSelf cleanupBackgroundTask];

                if ([weakDelegate respondsToSelector:@selector(requestDidTimeout:)]) {
                    [weakDelegate requestDidTimeout:weakSelf];
                }
            }];

            // Start the potentially long-running request
            [self fireAsynchronousRequest];
        }
#else
        [self fireAsynchronousRequest];
#endif
    } else {
        ORKLogTrace(@"Declined to dispatch request %@: reachability observer reported the network is not available.", self);

        if (_cachePolicy & ORKRequestCachePolicyLoadIfOffline &&
            [self.cache hasResponseForRequest:self]) {
            self.loading = YES;
            [self didFinishLoad:[self loadResponseFromCache]];
        } else {
            self.loading = YES;

            ORKLogError(@"Failed to send request to %@ due to unreachable network. Reachability observer = %@", [[self URL] absoluteString], self.reachabilityObserver);
            NSString *errorMessage = [NSString stringWithFormat:@"The client is unable to contact the resource at %@", [[self URL] absoluteString]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      errorMessage, NSLocalizedDescriptionKey,
                                      nil];
            NSError *error = [NSError errorWithDomain:ORKErrorDomain code:ORKRequestBaseURLOfflineError userInfo:userInfo];
            [self performSelector:@selector(didFailLoadWithError:) withObject:error afterDelay:0];
        }
    }
}

- (ORKResponse *)sendSynchronously
{
    NSAssert(NO == self.loading || NO == self.loaded, @"Cannot send a request that is loading or loaded without resetting it first.");
    NSHTTPURLResponse *URLResponse = nil;
    NSError *error;
    NSData *payload = nil;
    ORKResponse *response = nil;
    _sentSynchronously = YES;

    if ([self shouldLoadFromCache]) {
        response = [self loadResponseFromCache];
        self.loading = YES;
        [self didFinishLoad:response];
    } else if ([self shouldDispatchRequest]) {
        ORKLogDebug(@"Sending synchronous %@ request to URL %@.", [self HTTPMethod], [[self URL] absoluteString]);

        if (![self prepareURLRequest]) {
            ORKLogWarning(@"Failed to send request synchronously: prepareURLRequest returned NO.");
            return nil;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:ORKRequestSentNotification object:self userInfo:nil];

        self.loading = YES;
        if ([self.delegate respondsToSelector:@selector(requestDidStartLoad:)]) {
            [self.delegate requestDidStartLoad:self];
        }

        _URLRequest.timeoutInterval = _timeoutInterval;
        payload = [NSURLConnection sendSynchronousRequest:_URLRequest returningResponse:&URLResponse error:&error];

        if (payload != nil) error = nil;

        response = [[[ORKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];

        if (error.code == NSURLErrorTimedOut) {
            [self timeout];
        } else if (payload == nil) {
            [self didFailLoadWithError:error];
        } else {
            [self didFinishLoad:response];
        }

    } else {
        if (_cachePolicy & ORKRequestCachePolicyLoadIfOffline &&
            [self.cache hasResponseForRequest:self]) {

            response = [self loadResponseFromCache];

        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"The client is unable to contact the resource at %@", [[self URL] absoluteString]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      errorMessage, NSLocalizedDescriptionKey,
                                      nil];
            error = [NSError errorWithDomain:ORKErrorDomain code:ORKRequestBaseURLOfflineError userInfo:userInfo];
            [self didFailLoadWithError:error];
            response = [[[ORKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];
        }
    }

    return response;
}

- (void)cancel
{
    [self cancelAndInformDelegate:YES];
}

- (void)createTimeoutTimer
{
    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeoutInterval target:self selector:@selector(timeout) userInfo:nil repeats:NO];
}

- (void)timeout
{
    [self cancelAndInformDelegate:NO];
    ORKLogError(@"Failed to send request to %@ due to connection timeout. Timeout interval = %f", [[self URL] absoluteString], self.timeoutInterval);
    NSString *errorMessage = [NSString stringWithFormat:@"The client timed out connecting to the resource at %@", [[self URL] absoluteString]];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              errorMessage, NSLocalizedDescriptionKey,
                              nil];
    NSError *error = [NSError errorWithDomain:ORKErrorDomain code:ORKRequestConnectionTimeoutError userInfo:userInfo];
    [self didFailLoadWithError:error];
}

- (void)invalidateTimeoutTimer
{
    [_timeoutTimer invalidate];
    _timeoutTimer = nil;
}

- (void)didFailLoadWithError:(NSError *)error
{
    if (_cachePolicy & ORKRequestCachePolicyLoadOnError &&
        [self.cache hasResponseForRequest:self]) {

        [self didFinishLoad:[self loadResponseFromCache]];
    } else {
        self.loaded = YES;
        self.loading = NO;

        if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
            [_delegate request:self didFailLoadWithError:error];
        }

        if (self.onDidFailLoadWithError) {
            self.onDidFailLoadWithError(error);
        }


        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:ORKRequestDidFailWithErrorNotificationUserInfoErrorKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKRequestDidFailWithErrorNotification
                                                            object:self
                                                          userInfo:userInfo];
    }

    // NOTE: This notification must be posted last as the request queue releases the request when it
    // receives the notification
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKRequestDidFinishLoadingNotification object:self];
}

- (void)updateInternalCacheDate
{
    NSDate *date = [NSDate date];
    ORKLogInfo(@"Updating cache date for request %@ to %@", self, date);
    [self.cache setCacheDate:date forRequest:self];
}

- (void)didFinishLoad:(ORKResponse *)response
{
    self.loading = NO;
    self.loaded = YES;

    ORKLogInfo(@"Status Code: %ld", (long)[response statusCode]);
    ORKLogDebug(@"Body: %@", [response bodyAsString]);

    self.response = response;

    if ((_cachePolicy & ORKRequestCachePolicyEtag) && [response isNotModified]) {
        self.response = [self loadResponseFromCache];
        [self updateInternalCacheDate];
    }

    if (![response wasLoadedFromCache] && [response isSuccessful] && (_cachePolicy != ORKRequestCachePolicyNone)) {
        [self.cache storeResponse:response forRequest:self];
    }

    if ([_delegate respondsToSelector:@selector(request:didLoadResponse:)]) {
        [_delegate request:self didLoadResponse:self.response];
    }

    if (self.onDidLoadResponse) {
        self.onDidLoadResponse(self.response);
    }

    if ([response isServiceUnavailable]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKServiceDidBecomeUnavailableNotification object:self];
    }

    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.response
                                                         forKey:ORKRequestDidLoadResponseNotificationUserInfoResponseKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKRequestDidLoadResponseNotification
                                                        object:self
                                                      userInfo:userInfo];

    // NOTE: This notification must be posted last as the request queue releases the request when it
    // receives the notification
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKRequestDidFinishLoadingNotification object:self];
}

- (BOOL)isGET
{
    return _method == ORKRequestMethodGET;
}

- (BOOL)isPOST
{
    return _method == ORKRequestMethodPOST;
}

- (BOOL)isPUT
{
    return _method == ORKRequestMethodPUT;
}

- (BOOL)isDELETE
{
    return _method == ORKRequestMethodDELETE;
}

- (BOOL)isHEAD
{
    return _method == ORKRequestMethodHEAD;
}

- (BOOL)isUnsent
{
    return self.loading == NO && self.loaded == NO;
}

- (NSString *)resourcePath
{
    NSString *resourcePath = nil;
    if ([self.URL isKindOfClass:[ORKURL class]]) {
        ORKURL *url = (ORKURL *)self.URL;
        resourcePath = url.resourcePath;
    }
    return resourcePath;
}

- (void)setURL:(NSURL *)URL
{
    [URL retain];
    [_URL release];
    _URL = URL;
    _URLRequest.URL = URL;
}

- (void)setResourcePath:(NSString *)resourcePath
{
    if ([self.URL isKindOfClass:[ORKURL class]]) {
        self.URL = [(ORKURL *)self.URL URLByReplacingResourcePath:resourcePath];
    } else {
        self.URL = [ORKURL URLWithBaseURL:self.URL resourcePath:resourcePath];
    }
}

- (BOOL)wasSentToResourcePath:(NSString *)resourcePath
{
    return [[self resourcePath] isEqualToString:resourcePath];
}

- (BOOL)wasSentToResourcePath:(NSString *)resourcePath method:(ORKRequestMethod)method
{
    return (self.method == method && [self wasSentToResourcePath:resourcePath]);
}

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification
{
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    if (self.backgroundPolicy == ORKRequestBackgroundPolicyCancel) {
        [self cancel];
    } else if (self.backgroundPolicy == ORKRequestBackgroundPolicyRequeue) {
        // Cancel the existing request
        [self cancelAndInformDelegate:NO];
        [self send];
    }
#endif
}

- (BOOL)isCacheable
{
    return _method == ORKRequestMethodGET;
}

- (NSString *)cacheKey
{
    if (! [self isCacheable]) {
        return nil;
    }

    // Use [_params HTTPBody] because the URLRequest body may not have been set up yet.
    NSString *compositeCacheKey = nil;
    if (_params) {
        if ([_params respondsToSelector:@selector(HTTPBody)]) {
            compositeCacheKey = [NSString stringWithFormat:@"%@-%d-%@", self.URL, _method, [_params HTTPBody]];
        } else if ([_params isKindOfClass:[ORKParams class]]) {
            compositeCacheKey = [NSString stringWithFormat:@"%@-%d-%@", self.URL, _method, [(ORKParams *)_params MD5]];
        }
    } else {
        compositeCacheKey = [NSString stringWithFormat:@"%@-%d", self.URL, _method];
    }
    NSAssert(compositeCacheKey, @"Expected a cacheKey to be generated for request %@, but got nil", compositeCacheKey);
    return [compositeCacheKey MD5];
}

- (void)setBody:(NSDictionary *)body forMIMEType:(NSString *)MIMEType
{
    id<ORKParser> parser = [[ORKParserRegistry sharedRegistry] parserForMIMEType:MIMEType];

    NSError *error = nil;
    NSString *parsedValue = [parser stringFromObject:body error:&error];

    ORKLogTrace(@"parser=%@, error=%@, parsedValue=%@", parser, error, parsedValue);

    if (error == nil && parsedValue) {
        self.params = [ORKRequestSerialization serializationWithData:[parsedValue dataUsingEncoding:NSUTF8StringEncoding]
                                                           MIMEType:MIMEType];
    }
}

// Deprecations
+ (ORKRequest *)requestWithURL:(NSURL *)URL delegate:(id)delegate
{
    return [[[ORKRequest alloc] initWithURL:URL delegate:delegate] autorelease];
}

- (id)initWithURL:(NSURL *)URL delegate:(id)delegate
{
    self = [self initWithURL:URL];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

@end
