//
//  ORKTestFactory.m
//  ORKGithub
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestFactory.h"

@interface ORKTestFactory ()

@property (nonatomic, strong) ORKURL *baseURL;
@property (nonatomic, strong) NSString *managedObjectStoreFilename;
@property (nonatomic, strong) NSMutableDictionary *factoryBlocks;

+ (ORKTestFactory *)sharedFactory;
- (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block;
- (id)objectFromFactory:(NSString *)factoryName;
- (void)defineDefaultFactories;

@end

static ORKTestFactory *sharedFactory = nil;

@implementation ORKTestFactory

@synthesize baseURL = _baseURL;
@synthesize managedObjectStoreFilename = _managedObjectStoreFilename;
@synthesize factoryBlocks = _factoryBlocks;

+ (void)initialize
{
    // Ensure the shared factory is initialized
    [self sharedFactory];

    if ([ORKTestFactory respondsToSelector:@selector(didInitialize)]) {
        [ORKTestFactory didInitialize];
    }
}

+ (ORKTestFactory *)sharedFactory
{
    if (! sharedFactory) {
        sharedFactory = [ORKTestFactory new];
    }

    return sharedFactory;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.baseURL = [ORKURL URLWithString:@"http://127.0.0.1:4567"];
        self.managedObjectStoreFilename = ORKTestFactoryDefaultStoreFilename;
        self.factoryBlocks = [NSMutableDictionary new];
        [self defineDefaultFactories];
    }

    return self;
}

- (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block
{
    [self.factoryBlocks setObject:[block copy] forKey:factoryName];
}

- (id)objectFromFactory:(NSString *)factoryName
{
    id (^block)() = [self.factoryBlocks objectForKey:factoryName];
    NSAssert(block, @"No factory is defined with the name '%@'", factoryName);

    return block();
}

- (void)defineDefaultFactories
{
    [self defineFactory:ORKTestFactoryDefaultNamesClient withBlock:^id {
        __block ORKClient *client;

        ORKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitNetworkReachability, ^{
            ORKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitSupport, ^{
                client = [ORKClient clientWithBaseURL:self.baseURL];
                client.requestQueue.suspended = NO;
                [client.reachabilityObserver getFlags];
            });
        });

        return client;
    }];

    [self defineFactory:ORKTestFactoryDefaultNamesObjectManager withBlock:^id {
        __block ORKObjectManager *objectManager;

        ORKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitNetworkReachability, ^{
            ORKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitSupport, ^{
                objectManager = [ORKObjectManager managerWithBaseURL:self.baseURL];
                ORKObjectMappingProvider *mappingProvider = [self objectFromFactory:ORKTestFactoryDefaultNamesMappingProvider];
                objectManager.mappingProvider = mappingProvider;

                // Force reachability determination
                [objectManager.client.reachabilityObserver getFlags];
            });
        });

        return objectManager;
    }];

    [self defineFactory:ORKTestFactoryDefaultNamesMappingProvider withBlock:^id {
        ORKObjectMappingProvider *mappingProvider = [ORKObjectMappingProvider mappingProvider];
        return mappingProvider;
    }];

    [self defineFactory:ORKTestFactoryDefaultNamesManagedObjectStore withBlock:^id {
        NSString *storePath = [[ORKDirectory applicationDataDirectory] stringByAppendingPathComponent:ORKTestFactoryDefaultStoreFilename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
            [ORKManagedObjectStore deleteStoreInApplicationDataDirectoryWithFilename:ORKTestFactoryDefaultStoreFilename];
        }
        ORKManagedObjectStore *store = [ORKManagedObjectStore objectStoreWithStoreFilename:ORKTestFactoryDefaultStoreFilename];

        return store;
    }];
}

#pragma mark - Public Static Interface

+ (ORKURL *)baseURL
{
    return [ORKTestFactory sharedFactory].baseURL;
}

+ (void)setBaseURL:(ORKURL *)URL
{
    [ORKTestFactory sharedFactory].baseURL = URL;
}

+ (NSString *)baseURLString
{
    return [[[ORKTestFactory sharedFactory] baseURL] absoluteString];
}

+ (void)setBaseURLString:(NSString *)baseURLString
{
    [[ORKTestFactory sharedFactory] setBaseURL:[ORKURL URLWithString:baseURLString]];
}

+ (NSString *)managedObjectStoreFilename
{
   return [ORKTestFactory sharedFactory].managedObjectStoreFilename;
}

+ (void)setManagedObjectStoreFilename:(NSString *)managedObjectStoreFilename
{
    [ORKTestFactory sharedFactory].managedObjectStoreFilename = managedObjectStoreFilename;
}

+ (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block
{
    [[ORKTestFactory sharedFactory] defineFactory:factoryName withBlock:block];
}

+ (id)objectFromFactory:(NSString *)factoryName
{
    return [[ORKTestFactory sharedFactory] objectFromFactory:factoryName];
}

+ (NSSet *)factoryNames
{
    return [NSSet setWithArray:[[ORKTestFactory sharedFactory].factoryBlocks allKeys]];
}

+ (id)client
{
    ORKClient *client = [self objectFromFactory:ORKTestFactoryDefaultNamesClient];
    [ORKClient setSharedClient:client];

    return client;
}

+ (id)objectManager
{
    ORKObjectManager *objectManager = [self objectFromFactory:ORKTestFactoryDefaultNamesObjectManager];
    [ORKObjectManager setSharedManager:objectManager];
    [ORKClient setSharedClient:objectManager.client];

    return objectManager;
}

+ (id)mappingProvider
{
    ORKObjectMappingProvider *mappingProvider = [self objectFromFactory:ORKTestFactoryDefaultNamesMappingProvider];

    return mappingProvider;
}

+ (id)managedObjectStore
{
    ORKManagedObjectStore *objectStore = [self objectFromFactory:ORKTestFactoryDefaultNamesManagedObjectStore];
    [ORKManagedObjectStore setDefaultObjectStore:objectStore];

    return objectStore;
}

+ (void)setUp
{
    [ORKObjectManager setDefaultMappingQueue:dispatch_queue_create("org.restkit.ObjectMapping", DISPATCH_QUEUE_SERIAL)];
    [ORKObjectMapping setDefaultDateFormatters:nil];

    // Delete the store if it exists
    NSString *path = [[ORKDirectory applicationDataDirectory] stringByAppendingPathComponent:ORKTestFactoryDefaultStoreFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [ORKManagedObjectStore deleteStoreInApplicationDataDirectoryWithFilename:ORKTestFactoryDefaultStoreFilename];
    }

    if ([self respondsToSelector:@selector(didSetUp)]) {
        [self didSetUp];
    }
}

+ (void)tearDown
{
    [ORKObjectManager setSharedManager:nil];
    [ORKClient setSharedClient:nil];
    [ORKManagedObjectStore setDefaultObjectStore:nil];

    if ([self respondsToSelector:@selector(didTearDown)]) {
        [self didTearDown];
    }
}

+ (void)clearCacheDirectory
{
    NSError *error = nil;
    NSString *cachePath = [ORKDirectory cachesDirectory];
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:cachePath error:&error];
    if (success) {
        ORKLogDebug(@"Cleared cache directory...");
        success = [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            ORKLogError(@"Failed creation of cache path '%@': %@", cachePath, [error localizedDescription]);
        }
    } else {
        ORKLogError(@"Failed to clear cache path '%@': %@", cachePath, [error localizedDescription]);
    }
}

@end
