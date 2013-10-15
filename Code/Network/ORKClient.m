//
//  ORKClient.m
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
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

#import "ORKClient.h"
#import "ORKURL.h"
#import "ORKNotifications.h"
#import "ORKAlert.h"
#import "ORKLog.h"
#import "ORKPathMatcher.h"
#import "NSString+ORKAdditions.h"
#import "ORKDirectory.h"

// Set Logging Component
#undef ORKLogComponent
#define ORKLogComponent lcl_cRestKitNetwork

///////////////////////////////////////////////////////////////////////////////////////////////////
// Global

static ORKClient *sharedClient = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////
// URL Conveniences functions

NSURL *ORKMakeURL(NSString *resourcePath) {
    return [[ORKClient sharedClient].baseURL URLByAppendingResourcePath:resourcePath];
}

NSString *ORKMakeURLPath(NSString *resourcePath) {
    return [[[ORKClient sharedClient].baseURL URLByAppendingResourcePath:resourcePath] absoluteString];
}

NSString *ORKMakePathWithObjectAddingEscapes(NSString *pattern, id object, BOOL addEscapes) {
    NSCAssert(pattern != NULL, @"Pattern string must not be empty in order to create a path from an interpolated object.");
    NSCAssert(object != NULL, @"Object provided is invalid; cannot create a path from a NULL object");
    ORKPathMatcher *matcher = [ORKPathMatcher matcherWithPattern:pattern];
    NSString *interpolatedPath = [matcher pathFromObject:object addingEscapes:addEscapes];
    return interpolatedPath;
}

NSString *ORKMakePathWithObject(NSString *pattern, id object) {
    return ORKMakePathWithObjectAddingEscapes(pattern, object, YES);
}

NSString *ORKPathAppendQueryParams(NSString *resourcePath, NSDictionary *queryParams) {
    return [resourcePath stringByAppendingQueryParameters:queryParams];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface ORKClient ()
@property (nonatomic, retain, readwrite) NSMutableDictionary *HTTPHeaders;
@property (nonatomic, retain, readwrite) NSSet *additionalRootCertificates;
@end

@implementation ORKClient

@synthesize baseURL = _baseURL;
@synthesize authenticationType = _authenticationType;
@synthesize username = _username;
@synthesize password = _password;
@synthesize OAuth1ConsumerKey = _OAuth1ConsumerKey;
@synthesize OAuth1ConsumerSecret = _OAuth1ConsumerSecret;
@synthesize OAuth1AccessToken = _OAuth1AccessToken;
@synthesize OAuth1AccessTokenSecret = _OAuth1AccessTokenSecret;
@synthesize OAuth2AccessToken = _OAuth2AccessToken;
@synthesize OAuth2RefreshToken = _OAuth2RefreshToken;
@synthesize HTTPHeaders = _HTTPHeaders;
@synthesize additionalRootCertificates = _additionalRootCertificates;
@synthesize disableCertificateValidation = _disableCertificateValidation;
@synthesize reachabilityObserver = _reachabilityObserver;
@synthesize serviceUnavailableAlertTitle = _serviceUnavailableAlertTitle;
@synthesize serviceUnavailableAlertMessage = _serviceUnavailableAlertMessage;
@synthesize serviceUnavailableAlertEnabled = _serviceUnavailableAlertEnabled;
@synthesize requestCache = _requestCache;
@synthesize cachePolicy = _cachePolicy;
@synthesize requestQueue = _requestQueue;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize defaultHTTPEncoding = _defaultHTTPEncoding;
@synthesize cacheTimeoutInterval = _cacheTimeoutInterval;
@synthesize runLoopMode = _runLoopMode;

+ (ORKClient *)sharedClient
{
    return sharedClient;
}

+ (void)setSharedClient:(ORKClient *)client
{
    [sharedClient release];
    sharedClient = [client retain];
}

+ (ORKClient *)clientWithBaseURLString:(NSString *)baseURLString
{
    return [self clientWithBaseURL:[ORKURL URLWithString:baseURLString]];
}

+ (ORKClient *)clientWithBaseURL:(NSURL *)baseURL
{
    ORKClient *client = [[[self alloc] initWithBaseURL:baseURL] autorelease];
    return client;
}

+ (ORKClient *)clientWithBaseURL:(NSString *)baseURL username:(NSString *)username password:(NSString *)password
{
    ORKClient *client = [ORKClient clientWithBaseURLString:baseURL];
    client.authenticationType = ORKRequestAuthenticationTypeHTTPBasic;
    client.username = username;
    client.password = password;
    return client;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.HTTPHeaders = [NSMutableDictionary dictionary];
        self.additionalRootCertificates = [NSMutableSet set];
        self.defaultHTTPEncoding = NSUTF8StringEncoding;
        self.cacheTimeoutInterval = 0;
        self.runLoopMode = NSRunLoopCommonModes;
        self.requestQueue = [ORKRequestQueue requestQueue];
        self.serviceUnavailableAlertEnabled = NO;
        self.serviceUnavailableAlertTitle = NSLocalizedString(@"Service Unavailable", nil);
        self.serviceUnavailableAlertMessage = NSLocalizedString(@"The remote resource is unavailable. Please try again later.", nil);
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(serviceDidBecomeUnavailableNotification:)
                                                     name:ORKServiceDidBecomeUnavailableNotification
                                                   object:nil];

        // Configure observers
        [self addObserver:self forKeyPath:@"reachabilityObserver" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:@"baseURL" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"requestQueue" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:nil];
    }

    return self;
}

- (id)initWithBaseURL:(NSURL *)baseURL
{
    self = [self init];
    if (self) {
        self.cachePolicy = ORKRequestCachePolicyDefault;
        self.baseURL = [ORKURL URLWithBaseURL:baseURL];

        if (sharedClient == nil) {
            [ORKClient setSharedClient:self];

            // Initialize Logging as soon as a client is created
            ORKLogInitialize();
        }
    }

    return self;
}

- (id)initWithBaseURLString:(NSString *)baseURLString
{
    return [self initWithBaseURL:[ORKURL URLWithString:baseURLString]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Allow KVO to fire
    self.reachabilityObserver = nil;
    self.baseURL = nil;
    self.requestQueue = nil;

    [self removeObserver:self forKeyPath:@"reachabilityObserver"];
    [self removeObserver:self forKeyPath:@"baseURL"];
    [self removeObserver:self forKeyPath:@"requestQueue"];

    self.username = nil;
    self.password = nil;
    self.serviceUnavailableAlertTitle = nil;
    self.serviceUnavailableAlertMessage = nil;
    self.requestCache = nil;
    self.runLoopMode = nil;
    [_HTTPHeaders release];
    [_additionalRootCertificates release];

    if (sharedClient == self) sharedClient = nil;

    [super dealloc];
}

- (NSString *)cachePath
{
    NSString *cacheDirForClient = [NSString stringWithFormat:@"ORKClientRequestCache-%@", [self.baseURL host]];
    NSString *cachePath = [[ORKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    return cachePath;
}

- (BOOL)isNetworkReachable
{
    BOOL isNetworkReachable = YES;
    if (self.reachabilityObserver) {
        isNetworkReachable = [self.reachabilityObserver isNetworkReachable];
    }

    return isNetworkReachable;
}

- (void)configureRequest:(ORKRequest *)request
{
    request.additionalHTTPHeaders = _HTTPHeaders;
    request.authenticationType = self.authenticationType;
    request.username = self.username;
    request.password = self.password;
    request.cachePolicy = self.cachePolicy;
    request.cache = self.requestCache;
    request.queue = self.requestQueue;
    request.reachabilityObserver = self.reachabilityObserver;
    request.defaultHTTPEncoding = self.defaultHTTPEncoding;

    request.additionalRootCertificates = self.additionalRootCertificates;
    request.disableCertificateValidation = self.disableCertificateValidation;
    request.runLoopMode = self.runLoopMode;

    // If a timeoutInterval was set on the client, we'll pass it on to the request.
    // Otherwise, we'll let the request default to its own timeout interval.
    if (self.timeoutInterval) {
        request.timeoutInterval = self.timeoutInterval;
    }

    if (self.cacheTimeoutInterval) {
        request.cacheTimeoutInterval = self.cacheTimeoutInterval;
    }

    // OAuth 1 Parameters
    request.OAuth1AccessToken = self.OAuth1AccessToken;
    request.OAuth1AccessTokenSecret = self.OAuth1AccessTokenSecret;
    request.OAuth1ConsumerKey = self.OAuth1ConsumerKey;
    request.OAuth1ConsumerSecret = self.OAuth1ConsumerSecret;

    // OAuth2 Parameters
    request.OAuth2AccessToken = self.OAuth2AccessToken;
    request.OAuth2RefreshToken = self.OAuth2RefreshToken;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)header
{
    [_HTTPHeaders setValue:value forKey:header];
}

- (void)addRootCertificate:(SecCertificateRef)cert
{
    [_additionalRootCertificates addObject:(id)cert];
}

- (void)reachabilityObserverDidChange:(NSDictionary *)change
{
    ORKReachabilityObserver *oldReachabilityObserver = [change objectForKey:NSKeyValueChangeOldKey];
    ORKReachabilityObserver *newReachabilityObserver = [change objectForKey:NSKeyValueChangeNewKey];

    if (! [oldReachabilityObserver isEqual:[NSNull null]]) {
        ORKLogDebug(@"Reachability observer changed for ORKClient %@, disposing of previous instance: %@", self, oldReachabilityObserver);
        // Cleanup if changed immediately after client init
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ORKReachabilityWasDeterminedNotification object:oldReachabilityObserver];
    }

    if (! [newReachabilityObserver isEqual:[NSNull null]]) {
        // Suspend the queue until reachability to our new hostname is established
        if (! [newReachabilityObserver isReachabilityDetermined]) {
            self.requestQueue.suspended = YES;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reachabilityWasDetermined:)
                                                         name:ORKReachabilityWasDeterminedNotification
                                                       object:newReachabilityObserver];

            ORKLogDebug(@"Reachability observer changed for client %@, suspending queue %@ until reachability to host '%@' can be determined",
                       self, self.requestQueue, newReachabilityObserver.host);

            // Maintain a flag for Reachability determination status. This ensures that we can do the right thing in the
            // event that the requestQueue is changed while we are in an inderminate suspension state
            _awaitingReachabilityDetermination = YES;
        } else {
            self.requestQueue.suspended = NO;
            ORKLogDebug(@"Reachability observer changed for client %@, unsuspending queue %@ as new observer already has determined reachability to %@",
                       self, self.requestQueue, newReachabilityObserver.host);
            _awaitingReachabilityDetermination = NO;
        }
    }
}

- (void)baseURLDidChange:(NSDictionary *)change
{
    ORKURL *newBaseURL = [change objectForKey:NSKeyValueChangeNewKey];

    // Don't crash if baseURL is nil'd out (i.e. dealloc)
    if (! [newBaseURL isEqual:[NSNull null]]) {
        // Configure a cache for the new base URL
        [_requestCache release];
        _requestCache = [[ORKRequestCache alloc] initWithPath:[self cachePath]
                                                    storagePolicy:ORKRequestCacheStoragePolicyPermanently];

        // Determine reachability strategy (if user has not already done so)
        if (self.reachabilityObserver == nil) {
            NSString *hostName = [newBaseURL host];
            if ([hostName isEqualToString:@"localhost"] || [hostName isIPAddress]) {
                self.reachabilityObserver = [ORKReachabilityObserver reachabilityObserverForHost:hostName];
            } else {
                self.reachabilityObserver = [ORKReachabilityObserver reachabilityObserverForInternet];
            }
        }
    }
}

- (void)requestQueueDidChange:(NSDictionary *)change
{
    if (! _awaitingReachabilityDetermination) {
        return;
    }

    // If we are awaiting reachability determination, suspend the new queue
    ORKRequestQueue *newQueue = [change objectForKey:NSKeyValueChangeNewKey];

    if (! [newQueue isEqual:[NSNull null]]) {
        // The request queue has changed while we were awaiting reachability.
        // Suspend the queue until reachability is determined
        newQueue.suspended = !self.reachabilityObserver.reachabilityDetermined;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"baseURL"]) {
        [self baseURLDidChange:change];
    } else if ([keyPath isEqualToString:@"requestQueue"]) {
        [self requestQueueDidChange:change];
    } else if ([keyPath isEqualToString:@"reachabilityObserver"]) {
        [self reachabilityObserverDidChange:change];
    }
}

- (ORKRequest *)requestWithResourcePath:(NSString *)resourcePath
{
    ORKRequest *request = [[ORKRequest alloc] initWithURL:[self.baseURL URLByAppendingResourcePath:resourcePath]];
    [self configureRequest:request];
    [request autorelease];

    return request;
}

- (ORKRequest *)requestWithResourcePath:(NSString *)resourcePath delegate:(NSObject<ORKRequestDelegate> *)delegate
{
    ORKRequest *request = [self requestWithResourcePath:resourcePath];
    request.delegate = delegate;

    return request;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Asynchronous Requests
///////////////////////////////////////////////////////////////////////////////////////////////////////////

- (ORKRequest *)load:(NSString *)resourcePath method:(ORKRequestMethod)method params:(NSObject<ORKRequestSerializable> *)params delegate:(id)delegate
{
    ORKURL *resourcePathURL = nil;
    if (method == ORKRequestMethodGET) {
        resourcePathURL = [self.baseURL URLByAppendingResourcePath:resourcePath queryParameters:(NSDictionary *)params];
    } else {
        resourcePathURL = [self.baseURL URLByAppendingResourcePath:resourcePath];
    }
    ORKRequest *request = [ORKRequest requestWithURL:resourcePathURL];
    request.delegate = delegate;
    [self configureRequest:request];
    request.method = method;
    if (method != ORKRequestMethodGET) {
        request.params = params;
    }

    [request send];

    return request;
}

- (ORKRequest *)get:(NSString *)resourcePath delegate:(id)delegate
{
    return [self load:resourcePath method:ORKRequestMethodGET params:nil delegate:delegate];
}

- (ORKRequest *)get:(NSString *)resourcePath queryParameters:(NSDictionary *)queryParameters delegate:(id)delegate
{
    return [self load:resourcePath method:ORKRequestMethodGET params:queryParameters delegate:delegate];
}

- (ORKRequest *)post:(NSString *)resourcePath params:(NSObject<ORKRequestSerializable> *)params delegate:(id)delegate
{
    return [self load:resourcePath method:ORKRequestMethodPOST params:params delegate:delegate];
}

- (ORKRequest *)put:(NSString *)resourcePath params:(NSObject<ORKRequestSerializable> *)params delegate:(id)delegate
{
    return [self load:resourcePath method:ORKRequestMethodPUT params:params delegate:delegate];
}

- (ORKRequest *)delete:(NSString *)resourcePath delegate:(id)delegate
{
    return [self load:resourcePath method:ORKRequestMethodDELETE params:nil delegate:delegate];
}

- (void)serviceDidBecomeUnavailableNotification:(NSNotification *)notification
{
    if (self.serviceUnavailableAlertEnabled) {
        ORKAlertWithTitle(self.serviceUnavailableAlertMessage, self.serviceUnavailableAlertTitle);
    }
}

- (void)reachabilityWasDetermined:(NSNotification *)notification
{
    ORKReachabilityObserver *observer = (ORKReachabilityObserver *)[notification object];
    NSAssert(observer == self.reachabilityObserver, @"Received unexpected reachability notification from inappropriate reachability observer");

    ORKLogDebug(@"Reachability to host '%@' determined for client %@, unsuspending queue %@", observer.host, self, self.requestQueue);
    _awaitingReachabilityDetermination = NO;
    self.requestQueue.suspended = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ORKReachabilityWasDeterminedNotification object:observer];
}

#pragma mark - Deprecations

// deprecated
- (ORKRequestCache *)cache
{
    return _requestCache;
}

// deprecated
- (void)setCache:(ORKRequestCache *)requestCache
{
    self.requestCache = requestCache;
}

#pragma mark - Block Request Dispatching

- (ORKRequest *)sendRequestToResourcePath:(NSString *)resourcePath usingBlock:(void (^)(ORKRequest *request))block
{
    ORKRequest *request = [self requestWithResourcePath:resourcePath];
    if (block) block(request);
    [request send];
    return request;
}

- (void)get:(NSString *)resourcePath usingBlock:(void (^)(ORKRequest *request))block
{
    [self sendRequestToResourcePath:resourcePath usingBlock:^(ORKRequest *request) {
        request.method = ORKRequestMethodGET;
        block(request);
    }];
}

- (void)post:(NSString *)resourcePath usingBlock:(void (^)(ORKRequest *request))block
{
    [self sendRequestToResourcePath:resourcePath usingBlock:^(ORKRequest *request) {
        request.method = ORKRequestMethodPOST;
        block(request);
    }];
}

- (void)put:(NSString *)resourcePath usingBlock:(void (^)(ORKRequest *request))block
{
    [self sendRequestToResourcePath:resourcePath usingBlock:^(ORKRequest *request) {
        request.method = ORKRequestMethodPUT;
        block(request);
    }];
}

- (void)delete:(NSString *)resourcePath usingBlock:(void (^)(ORKRequest *request))block
{
    [self sendRequestToResourcePath:resourcePath usingBlock:^(ORKRequest *request) {
        request.method = ORKRequestMethodDELETE;
        block(request);
    }];
}

// deprecated
- (BOOL)isNetworkAvailable
{
    return [self isNetworkReachable];
}

- (NSString *)resourcePath:(NSString *)resourcePath withQueryParams:(NSDictionary *)queryParams
{
    return ORKPathAppendQueryParams(resourcePath, queryParams);
}

- (NSURL *)URLForResourcePath:(NSString *)resourcePath
{
    return [self.baseURL URLByAppendingResourcePath:resourcePath];
}

- (NSString *)URLPathForResourcePath:(NSString *)resourcePath
{
    return [[self URLForResourcePath:resourcePath] absoluteString];
}

- (NSURL *)URLForResourcePath:(NSString *)resourcePath queryParams:(NSDictionary *)queryParams
{
    return [self.baseURL URLByAppendingResourcePath:resourcePath queryParameters:queryParams];
}

@end
