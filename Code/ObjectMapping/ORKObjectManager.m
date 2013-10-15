//
//  ORKObjectManager.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
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

#import "ORKObjectManager.h"
#import "ORKObjectSerializer.h"
#import "ORKManagedObjectStore.h"
#import "ORKManagedObjectLoader.h"
#import "Support.h"

NSString * const ORKObjectManagerDidBecomeOfflineNotification = @"ORKDidEnterOfflineModeNotification";
NSString * const ORKObjectManagerDidBecomeOnlineNotification = @"ORKDidEnterOnlineModeNotification";

//////////////////////////////////
// Shared Instances

static ORKObjectManager  *sharedManager = nil;
static dispatch_queue_t defaultMappingQueue = nil;

///////////////////////////////////

@interface ORKObjectManager ()
@property (nonatomic, assign, readwrite) ORKObjectManagerNetworkStatus networkStatus;
@end

@implementation ORKObjectManager

@synthesize client = _client;
@synthesize objectStore = _objectStore;
@synthesize router = _router;
@synthesize mappingProvider = _mappingProvider;
@synthesize serializationMIMEType = _serializationMIMEType;
@synthesize networkStatus = _networkStatus;
@synthesize mappingQueue = _mappingQueue;

+ (dispatch_queue_t)defaultMappingQueue
{
    if (! defaultMappingQueue) {
        defaultMappingQueue = dispatch_queue_create("org.restkit.ObjectMapping", DISPATCH_QUEUE_SERIAL);
    }

    return defaultMappingQueue;
}

+ (void)setDefaultMappingQueue:(dispatch_queue_t)newDefaultMappingQueue
{
    if (defaultMappingQueue) {
        dispatch_release(defaultMappingQueue);
        defaultMappingQueue = nil;
    }

    if (newDefaultMappingQueue) {
        dispatch_retain(newDefaultMappingQueue);
        defaultMappingQueue = newDefaultMappingQueue;
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        _mappingProvider = [ORKObjectMappingProvider new];
        _router = [ORKObjectRouter new];
        _networkStatus = ORKObjectManagerNetworkStatusUnknown;

        self.serializationMIMEType = ORKMIMETypeFormURLEncoded;
        self.mappingQueue = [ORKObjectManager defaultMappingQueue];

        [self addObserver:self
               forKeyPath:@"client.reachabilityObserver"
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                  context:nil];

        // Set shared manager if nil
        if (nil == sharedManager) {
            [ORKObjectManager setSharedManager:self];
        }
    }

    return self;
}

- (id)initWithBaseURL:(ORKURL *)baseURL
{
    self = [self init];
    if (self) {
        self.client = [ORKClient clientWithBaseURL:baseURL];
        self.acceptMIMEType = ORKMIMETypeJSON;
    }

    return self;
}

+ (ORKObjectManager *)sharedManager
{
    return sharedManager;
}

+ (void)setSharedManager:(ORKObjectManager *)manager
{
    [manager retain];
    [sharedManager release];
    sharedManager = manager;
}

+ (ORKObjectManager *)managerWithBaseURLString:(NSString *)baseURLString
{
    return [self managerWithBaseURL:[ORKURL URLWithString:baseURLString]];
}

+ (ORKObjectManager *)managerWithBaseURL:(NSURL *)baseURL
{
    ORKObjectManager *manager = [[[self alloc] initWithBaseURL:baseURL] autorelease];
    return manager;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"client.reachabilityObserver"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_router release];
    _router = nil;
    self.client = nil;
    [_objectStore release];
    _objectStore = nil;
    [_serializationMIMEType release];
    _serializationMIMEType = nil;
    [_mappingProvider release];
    _mappingProvider = nil;

    [super dealloc];
}

- (BOOL)isOnline
{
    return (_networkStatus == ORKObjectManagerNetworkStatusOnline);
}

- (BOOL)isOffline
{
    return (_networkStatus == ORKObjectManagerNetworkStatusOffline);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"client.reachabilityObserver"]) {
        [self reachabilityObserverDidChange:change];
    }
}

- (void)reachabilityObserverDidChange:(NSDictionary *)change
{
    ORKReachabilityObserver *oldReachabilityObserver = [change objectForKey:NSKeyValueChangeOldKey];
    ORKReachabilityObserver *newReachabilityObserver = [change objectForKey:NSKeyValueChangeNewKey];

    if (! [oldReachabilityObserver isEqual:[NSNull null]]) {
        ORKLogDebug(@"Reachability observer changed for ORKClient %@ of ORKObjectManager %@, stopping observing reachability changes", self.client, self);
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ORKReachabilityDidChangeNotification object:oldReachabilityObserver];
    }

    if (! [newReachabilityObserver isEqual:[NSNull null]]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:ORKReachabilityDidChangeNotification
                                                   object:newReachabilityObserver];

        ORKLogDebug(@"Reachability observer changed for client %@ of object manager %@, starting observing reachability changes", self.client, self);
    }

    // Initialize current Network Status
    if ([self.client.reachabilityObserver isReachabilityDetermined]) {
        BOOL isNetworkReachable = [self.client.reachabilityObserver isNetworkReachable];
        self.networkStatus = isNetworkReachable ? ORKObjectManagerNetworkStatusOnline : ORKObjectManagerNetworkStatusOffline;
    } else {
        self.networkStatus = ORKObjectManagerNetworkStatusUnknown;
    }
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    BOOL isHostReachable = [self.client.reachabilityObserver isNetworkReachable];

    _networkStatus = isHostReachable ? ORKObjectManagerNetworkStatusOnline : ORKObjectManagerNetworkStatusOffline;

    if (isHostReachable) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOnlineNotification object:self];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOfflineNotification object:self];
    }
}

- (void)setAcceptMIMEType:(NSString *)MIMEType
{
    [_client setValue:MIMEType forHTTPHeaderField:@"Accept"];
}

- (NSString *)acceptMIMEType
{
    return [self.client.HTTPHeaders valueForKey:@"Accept"];
}

/////////////////////////////////////////////////////////////
#pragma mark - Object Collection Loaders

- (Class)objectLoaderClass
{
    Class managedObjectLoaderClass = NSClassFromString(@"ORKManagedObjectLoader");
    if (self.objectStore && managedObjectLoaderClass) {
        return managedObjectLoaderClass;
    }

    return [ORKObjectLoader class];
}

- (id)loaderWithResourcePath:(NSString *)resourcePath
{
    ORKURL *URL = [self.baseURL URLByAppendingResourcePath:resourcePath];
    return [self loaderWithURL:URL];
}

- (id)loaderWithURL:(ORKURL *)URL
{
    ORKObjectLoader *loader = [[self objectLoaderClass] loaderWithURL:URL mappingProvider:self.mappingProvider];
    loader.configurationDelegate = self;
    if ([loader isKindOfClass:[ORKManagedObjectLoader class]]) {
        [(ORKManagedObjectLoader *)loader setObjectStore:self.objectStore];
    }
    [self configureObjectLoader:loader];

    return loader;
}

- (NSURL *)baseURL
{
    return self.client.baseURL;
}

- (ORKObjectPaginator *)paginatorWithResourcePathPattern:(NSString *)resourcePathPattern
{
    ORKURL *patternURL = [[self baseURL] URLByAppendingResourcePath:resourcePathPattern];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL
                                                              mappingProvider:self.mappingProvider];
    paginator.configurationDelegate = self;
    return paginator;
}

- (id)loaderForObject:(id<NSObject>)object method:(ORKRequestMethod)method
{
    NSString *resourcePath = (method == ORKRequestMethodInvalid) ? nil : [self.router resourcePathForObject:object method:method];
    ORKObjectLoader *loader = [self loaderWithResourcePath:resourcePath];
    loader.method = method;
    loader.sourceObject = object;
    loader.serializationMIMEType = self.serializationMIMEType;
    loader.serializationMapping = [self.mappingProvider serializationMappingForClass:[object class]];

    ORKObjectMappingDefinition *objectMapping = resourcePath ? [self.mappingProvider objectMappingForResourcePath:resourcePath] : nil;
    if (objectMapping == nil || ([objectMapping isKindOfClass:[ORKObjectMapping class]] && [object isMemberOfClass:[(ORKObjectMapping *)objectMapping objectClass]])) {
        loader.targetObject = object;
    } else {
        loader.targetObject = nil;
    }

    return loader;
}

- (void)loadObjectsAtResourcePath:(NSString *)resourcePath delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    ORKObjectLoader *loader = [self loaderWithResourcePath:resourcePath];
    loader.delegate = delegate;
    loader.method = ORKRequestMethodGET;

    [loader send];
}

/////////////////////////////////////////////////////////////
#pragma mark - Object Instance Loaders

- (void)getObject:(id<NSObject>)object delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    ORKObjectLoader *loader = [self loaderForObject:object method:ORKRequestMethodGET];
    loader.delegate = delegate;
    [loader send];
}

- (void)postObject:(id<NSObject>)object delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    ORKObjectLoader *loader = [self loaderForObject:object method:ORKRequestMethodPOST];
    loader.delegate = delegate;
    [loader send];
}

- (void)putObject:(id<NSObject>)object delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    ORKObjectLoader *loader = [self loaderForObject:object method:ORKRequestMethodPUT];
    loader.delegate = delegate;
    [loader send];
}

- (void)deleteObject:(id<NSObject>)object delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    ORKObjectLoader *loader = [self loaderForObject:object method:ORKRequestMethodDELETE];
    loader.delegate = delegate;
    [loader send];
}

#if NS_BLOCKS_AVAILABLE

#pragma mark - Block Configured Object Loaders

- (void)loadObjectsAtResourcePath:(NSString *)resourcePath usingBlock:(void(^)(ORKObjectLoader *))block
{
    ORKObjectLoader *loader = [self loaderWithResourcePath:resourcePath];
    loader.method = ORKRequestMethodGET;

    // Yield to the block for setup
    block(loader);

    [loader send];
}

- (void)sendObject:(id<NSObject>)object toResourcePath:(NSString *)resourcePath usingBlock:(void(^)(ORKObjectLoader *))block
{
    ORKObjectLoader *loader = [self loaderForObject:object method:ORKRequestMethodInvalid];
    loader.URL = [self.baseURL URLByAppendingResourcePath:resourcePath];
    // Yield to the block for setup
    block(loader);

    [loader send];
}

- (void)sendObject:(id<NSObject>)object method:(ORKRequestMethod)method usingBlock:(void(^)(ORKObjectLoader *))block
{
    NSString *resourcePath = [self.router resourcePathForObject:object method:method];
    [self sendObject:object toResourcePath:resourcePath usingBlock:^(ORKObjectLoader *loader) {
        loader.method = method;
        block(loader);
    }];
}

- (void)getObject:(id<NSObject>)object usingBlock:(void(^)(ORKObjectLoader *))block
{
    [self sendObject:object method:ORKRequestMethodGET usingBlock:block];
}

- (void)postObject:(id<NSObject>)object usingBlock:(void(^)(ORKObjectLoader *))block
{
    [self sendObject:object method:ORKRequestMethodPOST usingBlock:block];
}

- (void)putObject:(id<NSObject>)object usingBlock:(void(^)(ORKObjectLoader *))block
{
    [self sendObject:object method:ORKRequestMethodPUT usingBlock:block];
}

- (void)deleteObject:(id<NSObject>)object usingBlock:(void(^)(ORKObjectLoader *))block
{
    [self sendObject:object method:ORKRequestMethodDELETE usingBlock:block];
}

#endif // NS_BLOCKS_AVAILABLE

#pragma mark - Object Instance Loaders for Non-nested JSON

- (void)getObject:(id<NSObject>)object mapResponseWith:(ORKObjectMapping *)objectMapping delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    [self sendObject:object method:ORKRequestMethodGET usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = delegate;
        loader.objectMapping = objectMapping;
    }];
}

- (void)postObject:(id<NSObject>)object mapResponseWith:(ORKObjectMapping *)objectMapping delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    [self sendObject:object method:ORKRequestMethodPOST usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = delegate;
        loader.objectMapping = objectMapping;
    }];
}

- (void)putObject:(id<NSObject>)object mapResponseWith:(ORKObjectMapping *)objectMapping delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    [self sendObject:object method:ORKRequestMethodPUT usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = delegate;
        loader.objectMapping = objectMapping;
    }];
}

- (void)deleteObject:(id<NSObject>)object mapResponseWith:(ORKObjectMapping *)objectMapping delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    [self sendObject:object method:ORKRequestMethodDELETE usingBlock:^(ORKObjectLoader *loader) {
        loader.delegate = delegate;
        loader.objectMapping = objectMapping;
    }];
}

- (ORKRequestCache *)requestCache
{
    return self.client.requestCache;
}

- (ORKRequestQueue *)requestQueue
{
    return self.client.requestQueue;
}

- (void)setMappingQueue:(dispatch_queue_t)newMappingQueue
{
    if (_mappingQueue) {
        dispatch_release(_mappingQueue);
        _mappingQueue = nil;
    }

    if (newMappingQueue) {
        dispatch_retain(newMappingQueue);
        _mappingQueue = newMappingQueue;
    }
}

#pragma mark - ORKConfigrationDelegate

- (void)configureRequest:(ORKRequest *)request
{
    [self.client configureRequest:request];
}

- (void)configureObjectLoader:(ORKObjectLoader *)objectLoader
{
    objectLoader.serializationMIMEType = self.serializationMIMEType;
    [self configureRequest:objectLoader];
}

#pragma mark - Deprecations

+ (ORKObjectManager *)objectManagerWithBaseURLString:(NSString *)baseURLString
{
    return [self managerWithBaseURLString:baseURLString];
}

+ (ORKObjectManager *)objectManagerWithBaseURL:(NSURL *)baseURL
{
    return [self managerWithBaseURL:baseURL];
}

- (ORKObjectLoader *)objectLoaderWithResourcePath:(NSString *)resourcePath delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    ORKObjectLoader *loader = [self loaderWithResourcePath:resourcePath];
    loader.delegate = delegate;

    return loader;
}

- (ORKObjectLoader *)objectLoaderForObject:(id<NSObject>)object method:(ORKRequestMethod)method delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    ORKObjectLoader *loader = [self loaderForObject:object method:method];
    loader.delegate = delegate;
    return loader;
}

- (void)loadObjectsAtResourcePath:(NSString *)resourcePath objectMapping:(ORKObjectMapping *)objectMapping delegate:(id<ORKObjectLoaderDelegate>)delegate
{
    ORKObjectLoader *loader = [self loaderWithResourcePath:resourcePath];
    loader.delegate = delegate;
    loader.method = ORKRequestMethodGET;
    loader.objectMapping = objectMapping;

    [loader send];
}

@end
