//
//  ORKRequestQueue.m
//  RestKit
//
//  Created by Blake Watters on 12/1/10.
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

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "ORKClient.h"
#import "ORKRequestQueue.h"
#import "ORKResponse.h"
#import "ORKNotifications.h"
#import "ORKLog.h"
#import "ORKFixCategoryBug.h"

ORK_FIX_CATEGORY_BUG(UIApplication_ORKNetworkActivity)

// Constants
static NSMutableArray *ORKRequestQueueInstances = nil;

static const NSTimeInterval kFlushDelay = 0.3;

// Set Logging Component
#undef ORKLogComponent
#define ORKLogComponent lcl_cRestKitNetworkQueue

@interface ORKRequestQueue ()
@property (nonatomic, retain, readwrite) NSString *name;
@end

@implementation ORKRequestQueue

@synthesize name = _name;
@synthesize delegate = _delegate;
@synthesize concurrentRequestsLimit = _concurrentRequestsLimit;
@synthesize requestTimeout = _requestTimeout;
@synthesize suspended = _suspended;

#if TARGET_OS_IPHONE
@synthesize showsNetworkActivityIndicatorWhenBusy = _showsNetworkActivityIndicatorWhenBusy;
#endif

+ (ORKRequestQueue *)sharedQueue
{
    ORKLogWarning(@"Deprecated invocation of [ORKRequestQueue sharedQueue]. Returning [ORKClient sharedClient].requestQueue. Update your code to reference the queue you want explicitly.");
    return [ORKClient sharedClient].requestQueue;
}

+ (void)setSharedQueue:(ORKRequestQueue *)requestQueue
{
    ORKLogWarning(@"Deprecated access to [ORKRequestQueue setSharedQueue:]. Invoking [[ORKClient sharedClient] setRequestQueue:]. Update your code to reference the specific queue instance you want.");
    [ORKClient sharedClient].requestQueue = requestQueue;
}

+ (id)requestQueue
{
    return [[self new] autorelease];
}

+ (id)newRequestQueueWithName:(NSString *)name
{
    if (ORKRequestQueueInstances == nil) {
        ORKRequestQueueInstances = [NSMutableArray new];
    }

    if ([self requestQueueExistsWithName:name]) {
        return nil;
    }

    ORKRequestQueue *queue = [self new];
    queue.name = name;
    [ORKRequestQueueInstances addObject:[NSValue valueWithNonretainedObject:queue]];

    return queue;
}

+ (id)requestQueueWithName:(NSString *)name
{
    if (ORKRequestQueueInstances == nil) {
        ORKRequestQueueInstances = [NSMutableArray new];
    }

    // Find existing reference
    NSArray *requestQueueInstances = [ORKRequestQueueInstances copy];
    ORKRequestQueue *namedQueue = nil;
    for (NSValue *value in requestQueueInstances) {
        ORKRequestQueue *queue = (ORKRequestQueue *)[value nonretainedObjectValue];
        if ([queue.name isEqualToString:name]) {
            namedQueue = queue;
            break;
        }
    }
    [requestQueueInstances release];

    if (namedQueue == nil) {
        namedQueue = [self requestQueue];
        namedQueue.name = name;
        [ORKRequestQueueInstances addObject:[NSValue valueWithNonretainedObject:namedQueue]];
    }

    return namedQueue;
}

+ (BOOL)requestQueueExistsWithName:(NSString *)name
{
    BOOL queueExists = NO;
    if (ORKRequestQueueInstances) {
        NSArray *requestQueueInstances = [ORKRequestQueueInstances copy];
        for (NSValue *value in requestQueueInstances) {
            ORKRequestQueue *queue = (ORKRequestQueue *)[value nonretainedObjectValue];
            if ([queue.name isEqualToString:name]) {
                queueExists = YES;
                break;
            }
        }
        [requestQueueInstances release];
    }

    return queueExists;
}

- (id)init
{
    if ((self = [super init])) {
        _requests = [[NSMutableArray alloc] init];
        _loadingRequests = [[NSMutableSet alloc] init];
        _suspended = YES;
        _concurrentRequestsLimit = 5;
        _requestTimeout = 300;
        _showsNetworkActivityIndicatorWhenBusy = NO;

#if TARGET_OS_IPHONE
        BOOL backgroundOK = &UIApplicationDidEnterBackgroundNotification != NULL;
        if (backgroundOK) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(willTransitionToBackground)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(willTransitionToForeground)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:nil];
        }
#endif
    }
    return self;
}

- (void)removeFromNamedQueues
{
    if (self.name) {
        for (NSValue *value in ORKRequestQueueInstances) {
            ORKRequestQueue *queue = (ORKRequestQueue *)[value nonretainedObjectValue];
            if ([queue.name isEqualToString:self.name]) {
                [ORKRequestQueueInstances removeObject:value];
                return;
            }
        }
    }
}

- (void)dealloc
{
    ORKLogDebug(@"Queue instance is being deallocated: %@", self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self removeFromNamedQueues];

    [_queueTimer invalidate];
    [_loadingRequests release];
    _loadingRequests = nil;
    [_requests release];
    _requests = nil;

    [super dealloc];
}

- (NSUInteger)count
{
    return [_requests count];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p name=%@ suspended=%@ requestCount=%d loadingCount=%d/%d>",
            NSStringFromClass([self class]), self, self.name, self.suspended ? @"YES" : @"NO",
            self.count, self.loadingCount, self.concurrentRequestsLimit];
}

- (NSUInteger)loadingCount
{
    return [_loadingRequests count];
}

- (void)addLoadingRequest:(ORKRequest *)request
{
    if (self.loadingCount == 0) {
        ORKLogTrace(@"Loading count increasing from 0 to 1. Firing requestQueueDidBeginLoading");

        // Transitioning from empty to processing
        if ([_delegate respondsToSelector:@selector(requestQueueDidBeginLoading:)]) {
            [_delegate requestQueueDidBeginLoading:self];
        }

#if TARGET_OS_IPHONE
        if (self.showsNetworkActivityIndicatorWhenBusy) {
            [[UIApplication sharedApplication] pushNetworkActivity];
        }
#endif
    }
    @synchronized(self) {
        [_loadingRequests addObject:request];
    }
    ORKLogTrace(@"Loading count now %ld for queue %@", (long)self.loadingCount, self);
}

- (void)removeLoadingRequest:(ORKRequest *)request
{
    if (self.loadingCount == 1 && [_loadingRequests containsObject:request]) {
        ORKLogTrace(@"Loading count decreasing from 1 to 0. Firing requestQueueDidFinishLoading");

        // Transition from processing to empty
        if ([_delegate respondsToSelector:@selector(requestQueueDidFinishLoading:)]) {
            [_delegate requestQueueDidFinishLoading:self];
        }

#if TARGET_OS_IPHONE
        if (self.showsNetworkActivityIndicatorWhenBusy) {
            [[UIApplication sharedApplication] popNetworkActivity];
        }
#endif
    }
    @synchronized(self) {
        [_loadingRequests removeObject:request];
    }
    ORKLogTrace(@"Loading count now %ld for queue %@", (long)self.loadingCount, self);
}

- (void)loadNextInQueueDelayed
{
    if (!_queueTimer) {
        _queueTimer = [NSTimer scheduledTimerWithTimeInterval:kFlushDelay
                                                       target:self
                                                     selector:@selector(loadNextInQueue)
                                                     userInfo:nil
                                                      repeats:NO];
        ORKLogTrace(@"Timer initialized with delay %f for queue %@", kFlushDelay, self);
    }
}

- (ORKRequest *)nextRequest
{
    for (NSUInteger i = 0; i < [_requests count]; i++) {
        ORKRequest *request = [_requests objectAtIndex:i];
        if ([request isUnsent]) {
            return request;
        }
    }

    return nil;
}

- (void)loadNextInQueue
{
    // We always want to dispatch requests from the main thread so the current thread does not terminate
    // and cause us to lose the delegate callbacks
    if (! [NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(loadNextInQueue) withObject:nil waitUntilDone:NO];
        return;
    }

    // Make sure that the Request Queue does not fire off any requests until the Reachability state has been determined.
    if (self.suspended) {
        _queueTimer = nil;
        [self loadNextInQueueDelayed];

        ORKLogTrace(@"Deferring request loading for queue %@ due to suspension", self);
        return;
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    _queueTimer = nil;

    @synchronized(self) {
        ORKRequest *request = [self nextRequest];
        while (request && self.loadingCount < _concurrentRequestsLimit) {
            ORKLogTrace(@"Processing request %@ in queue %@", request, self);
            if ([_delegate respondsToSelector:@selector(requestQueue:willSendRequest:)]) {
                [_delegate requestQueue:self willSendRequest:request];
            }

            [self addLoadingRequest:request];
            ORKLogDebug(@"Sent request %@ from queue %@. Loading count = %ld of %ld", request, self, (long)self.loadingCount, (long)_concurrentRequestsLimit);
            [request sendAsynchronously];

            if ([_delegate respondsToSelector:@selector(requestQueue:didSendRequest:)]) {
                [_delegate requestQueue:self didSendRequest:request];
            }

            request = [self nextRequest];
        }
    }

    if (_requests.count && !_suspended) {
        [self loadNextInQueueDelayed];
    }

    [pool drain];
}

- (void)setSuspended:(BOOL)isSuspended
{
    if (_suspended != isSuspended) {
        if (isSuspended) {
            ORKLogDebug(@"Queue %@ has been suspended", self);

            // Becoming suspended
            if ([_delegate respondsToSelector:@selector(requestQueueWasSuspended:)]) {
                [_delegate requestQueueWasSuspended:self];
            }
        } else {
            ORKLogDebug(@"Queue %@ has been unsuspended", self);

            // Becoming unsupended
            if ([_delegate respondsToSelector:@selector(requestQueueWasUnsuspended:)]) {
                [_delegate requestQueueWasUnsuspended:self];
            }
        }
    }

    _suspended = isSuspended;

    if (!_suspended) {
        [self loadNextInQueue];
    } else if (_queueTimer) {
        [_queueTimer invalidate];
        _queueTimer = nil;
    }
}

- (void)addRequest:(ORKRequest *)request
{
    ORKLogTrace(@"Request %@ added to queue %@", request, self);
    NSAssert(![self containsRequest:request], @"Attempting to add the same request multiple times");

    @synchronized(self) {
        [_requests addObject:request];
        request.queue = self;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processRequestDidFinishLoadingNotification:)
                                                 name:ORKRequestDidFinishLoadingNotification
                                               object:request];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processRequestDidLoadResponseNotification:)
                                                 name:ORKRequestDidLoadResponseNotification
                                               object:request];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processRequestDidFailWithErrorNotification:)
                                                 name:ORKRequestDidFailWithErrorNotification
                                               object:request];

    [self loadNextInQueue];
}

- (BOOL)removeRequest:(ORKRequest *)request
{
    if ([self containsRequest:request]) {
        ORKLogTrace(@"Removing request %@ from queue %@", request, self);
        @synchronized(self) {
            [self removeLoadingRequest:request];
            [_requests removeObject:request];
            request.queue = nil;
        }

        [[NSNotificationCenter defaultCenter] removeObserver:self name:ORKRequestDidLoadResponseNotification object:request];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ORKRequestDidFailWithErrorNotification object:request];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ORKRequestDidFinishLoadingNotification object:request];

        return YES;
    }

    ORKLogWarning(@"Failed to remove request %@ from queue %@: it is not in the queue.", request, self);
    return NO;
}

- (BOOL)containsRequest:(ORKRequest *)request
{
    @synchronized(self) {
        return [_requests containsObject:request];
    }
}

- (void)cancelRequest:(ORKRequest *)request loadNext:(BOOL)loadNext
{
    if ([request isUnsent]) {
        ORKLogDebug(@"Cancelled undispatched request %@ and removed from queue %@", request, self);

        [self removeRequest:request];
        request.delegate = nil;

        if ([_delegate respondsToSelector:@selector(requestQueue:didCancelRequest:)]) {
            [_delegate requestQueue:self didCancelRequest:request];
        }
    } else if ([self containsRequest:request] && [request isLoading]) {
        ORKLogDebug(@"Cancelled loading request %@ and removed from queue %@", request, self);

        [request cancel];
        request.delegate = nil;

        if ([_delegate respondsToSelector:@selector(requestQueue:didCancelRequest:)]) {
            [_delegate requestQueue:self didCancelRequest:request];
        }

        [self removeRequest:request];

        if (loadNext) {
            [self loadNextInQueue];
        }
    }
}

- (void)cancelRequest:(ORKRequest *)request
{
    [self cancelRequest:request loadNext:YES];
}

- (void)cancelRequestsWithDelegate:(NSObject<ORKRequestDelegate> *)delegate
{
    ORKLogDebug(@"Cancelling all request in queue %@ with delegate %p", self, delegate);

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *requestsCopy = [NSArray arrayWithArray:_requests];
    for (ORKRequest *request in requestsCopy) {
        if (request.delegate && request.delegate == delegate) {
            [self cancelRequest:request];
        }
    }
    [pool drain];
}

- (void)abortRequestsWithDelegate:(NSObject<ORKRequestDelegate> *)delegate
{
    ORKLogDebug(@"Aborting all request in queue %@ with delegate %p", self, delegate);

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *requestsCopy = [NSArray arrayWithArray:_requests];
    for (ORKRequest *request in requestsCopy) {
        if (request.delegate && request.delegate == delegate) {
            request.delegate = nil;
            [self cancelRequest:request];
        }
    }
    [pool drain];
}

- (void)cancelAllRequests
{
    ORKLogDebug(@"Cancelling all request in queue %@", self);

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *requestsCopy = [NSArray arrayWithArray:_requests];
    for (ORKRequest *request in requestsCopy) {
        [self cancelRequest:request loadNext:NO];
    }
    [pool drain];
}

- (void)start
{
    ORKLogDebug(@"Started queue %@", self);
    [self setSuspended:NO];
}

- (void)processRequestDidLoadResponseNotification:(NSNotification *)notification
{
    NSAssert([notification.object isKindOfClass:[ORKRequest class]], @"Notification expected to contain an ORKRequest, got a %@", NSStringFromClass([notification.object class]));
    ORKLogTrace(@"Received notification: %@", notification);

    ORKRequest *request = (ORKRequest *)notification.object;
    NSDictionary *userInfo = [notification userInfo];

    // We successfully loaded a response
    ORKLogDebug(@"Received response for request %@, removing from queue. (Now loading %ld of %ld)", request, (long)self.loadingCount, (long)_concurrentRequestsLimit);

    ORKResponse *response = [userInfo objectForKey:ORKRequestDidLoadResponseNotificationUserInfoResponseKey];
    if ([_delegate respondsToSelector:@selector(requestQueue:didLoadResponse:)]) {
        [_delegate requestQueue:self didLoadResponse:response];
    }

    [self removeLoadingRequest:request];
    [self loadNextInQueue];
}

- (void)processRequestDidFailWithErrorNotification:(NSNotification *)notification
{
    NSAssert([notification.object isKindOfClass:[ORKRequest class]], @"Notification expected to contain an ORKRequest, got a %@", NSStringFromClass([notification.object class]));
    ORKLogTrace(@"Received notification: %@", notification);

    ORKRequest *request = (ORKRequest *)notification.object;
    NSDictionary *userInfo = [notification userInfo];

    // We failed with an error
    NSError *error = nil;
    if (userInfo) {
        error = [userInfo objectForKey:ORKRequestDidFailWithErrorNotificationUserInfoErrorKey];
        ORKLogDebug(@"Request %@ failed loading in queue %@ with error: %@.(Now loading %ld of %ld)", request, self,
                   [error localizedDescription], (long)self.loadingCount, (long)_concurrentRequestsLimit);
    } else {
        ORKLogWarning(@"Received ORKRequestDidFailWithErrorNotification without a userInfo, something is amiss...");
    }

    if ([_delegate respondsToSelector:@selector(requestQueue:didFailRequest:withError:)]) {
        [_delegate requestQueue:self didFailRequest:request withError:error];
    }

    [self removeLoadingRequest:request];
    [self loadNextInQueue];
}

/*
 Invoked via observation when a request has loaded a response or failed with an
 error. Remove the completed request from the queue and continue processing
 */
- (void)processRequestDidFinishLoadingNotification:(NSNotification *)notification
{
    NSAssert([notification.object isKindOfClass:[ORKRequest class]], @"Notification expected to contain an ORKRequest, got a %@", NSStringFromClass([notification.object class]));
    ORKLogTrace(@"Received notification: %@", notification);

    ORKRequest *request = (ORKRequest *)notification.object;
    if ([self containsRequest:request]) {
        [self removeRequest:request];

        // Load the next request
        [self loadNextInQueue];
    } else {
        ORKLogWarning(@"Request queue %@ received unexpected lifecycle notification %@ for request %@: Request not found in queue.", [notification name], self, request);
    }
}

#pragma mark - Background Request Support

- (void)willTransitionToBackground
{
    ORKLogDebug(@"App is transitioning into background, suspending queue");

    // Suspend the queue so background requests do not trigger additional requests on state changes
    self.suspended = YES;
}

- (void)willTransitionToForeground
{
    ORKLogDebug(@"App returned from background, unsuspending queue");

    self.suspended = NO;
}

@end

#if TARGET_OS_IPHONE

@implementation UIApplication (ORKNetworkActivity)

static NSInteger networkActivityCount;

- (NSInteger)networkActivityCount
{
    @synchronized(self) {
        return networkActivityCount;
    }
}

- (void)refreshActivityIndicator
{
    if (![NSThread isMainThread]) {
        SEL sel_refresh = @selector(refreshActivityIndicator);
        [self performSelectorOnMainThread:sel_refresh withObject:nil waitUntilDone:NO];
        return;
    }
    BOOL active = (self.networkActivityCount > 0);
    self.networkActivityIndicatorVisible = active;
}

- (void)pushNetworkActivity
{
    @synchronized(self) {
        networkActivityCount++;
    }
    [self refreshActivityIndicator];
}

- (void)popNetworkActivity
{
    @synchronized(self) {
        if (networkActivityCount > 0) {
            networkActivityCount--;
        } else {
            networkActivityCount = 0;
            ORKLogError(@"Unbalanced network activity: count already 0.");
        }
    }
    [self refreshActivityIndicator];
}

- (void)resetNetworkActivity
{
    @synchronized(self) {
        networkActivityCount = 0;
    }
    [self refreshActivityIndicator];
}

@end

#endif
