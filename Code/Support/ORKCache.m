//
//  ORKCache.h
//  RestKit
//
//  Created by Jeff Arena on 8/26/11.
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

#import "ORKCache.h"
#import "ORKLog.h"

// Set Logging Component
#undef ORKLogComponent
#define ORKLogComponent lcl_cRestKitSupport

@implementation ORKCache

- (id)initWithPath:(NSString *)cachePath subDirectories:(NSArray *)subDirectories
{
    self = [super init];
    if (self) {
        _cachePath = [cachePath copy];
        _cacheLock = [[NSRecursiveLock alloc] init];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableArray *pathArray = [NSMutableArray arrayWithObject:_cachePath];
        for (NSString *subDirectory in subDirectories) {
            [pathArray addObject:[_cachePath stringByAppendingPathComponent:subDirectory]];
        }

        for (NSString *path in pathArray) {
            BOOL isDirectory = NO;
            BOOL fileExists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
            if (!fileExists) {
                NSError *error = nil;
                BOOL created = [fileManager createDirectoryAtPath:path
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
                if (!created || error != nil) {
                    ORKLogError(@"Failed to create cache directory at %@: error %@", path, [error localizedDescription]);
                } else {
                    ORKLogDebug(@"Created cache storage at path '%@'", path);
                }
            } else {
                if (!isDirectory) {
                    ORKLogWarning(@"Skipped creation of cache directory as non-directory file exists at path: %@", path);
                }
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [_cachePath release];
    _cachePath = nil;
    [_cacheLock release];
    _cacheLock = nil;
    [super dealloc];
}

- (NSString *)cachePath
{
    return _cachePath;
}

- (NSString *)pathForCacheKey:(NSString *)cacheKey
{
    [_cacheLock lock];
    NSString *pathForCacheKey = [_cachePath stringByAppendingPathComponent:cacheKey];
    [_cacheLock unlock];
    ORKLogTrace(@"Found cachePath '%@' for %@", pathForCacheKey, cacheKey);
    return pathForCacheKey;
}

- (BOOL)hasEntry:(NSString *)cacheKey
{
    [_cacheLock lock];
    BOOL hasEntry = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [self pathForCacheKey:cacheKey];
    hasEntry = [fileManager fileExistsAtPath:cachePath];
    [_cacheLock unlock];
    ORKLogTrace(@"Determined hasEntry: %@ => %@", cacheKey, hasEntry ? @"YES" : @"NO");
    return hasEntry;
}

- (void)writeDictionary:(NSDictionary *)dictionary withCacheKey:(NSString *)cacheKey
{
    if (dictionary) {
        [_cacheLock lock];
        ORKLogTrace(@"Writing dictionary to cache key: '%@'", cacheKey);
        BOOL success = [dictionary writeToFile:[self pathForCacheKey:cacheKey] atomically:YES];
        if (success) {
            ORKLogTrace(@"Wrote cached dictionary to cacheKey '%@'", cacheKey);
        } else {
            ORKLogError(@"Failed to write cached dictionary to cacheKey '%@'", cacheKey);
        }
        [_cacheLock unlock];
    }
}

- (void)writeData:(NSData *)data withCacheKey:(NSString *)cacheKey
{
    if (data) {
        [_cacheLock lock];
        NSString *cachePath = [self pathForCacheKey:cacheKey];
        if (cachePath) {
            NSError *error = nil;
            BOOL success = [data writeToFile:cachePath options:NSDataWritingAtomic error:&error];
            if (success) {
                ORKLogTrace(@"Wrote cached data to path '%@'", cachePath);
            } else {
                ORKLogError(@"Failed to write cached data to path '%@': %@", cachePath, [error localizedDescription]);
            }
        }
        [_cacheLock unlock];
    }
}

- (NSDictionary *)dictionaryForCacheKey:(NSString *)cacheKey
{
    [_cacheLock lock];
    NSDictionary *dictionary = nil;
    NSString *cachePath = [self pathForCacheKey:cacheKey];
    if (cachePath) {
        dictionary = [NSDictionary dictionaryWithContentsOfFile:cachePath];
        if (dictionary) {
            ORKLogDebug(@"Read cached dictionary '%@' from cachePath '%@' for '%@'", dictionary, cachePath, cacheKey);
        } else {
            ORKLogDebug(@"Read nil cached dictionary from cachePath '%@' for '%@'", cachePath, cacheKey);
        }
    } else {
        ORKLogDebug(@"Unable to read cached dictionary for '%@': cachePath not found", cacheKey);
    }
    [_cacheLock unlock];
    return dictionary;
}

- (NSData *)dataForCacheKey:(NSString *)cacheKey
{
    [_cacheLock lock];
    NSData *data = nil;
    NSString *cachePath = [self pathForCacheKey:cacheKey];
    if (cachePath) {
        data = [NSData dataWithContentsOfFile:cachePath];
        if (data) {
            ORKLogDebug(@"Read cached data '%@' from cachePath '%@' for '%@'", data, cachePath, cacheKey);
        } else {
            ORKLogDebug(@"Read nil cached data from cachePath '%@' for '%@'", cachePath, cacheKey);
        }
    }
    [_cacheLock unlock];
    return data;
}

- (void)invalidateEntry:(NSString *)cacheKey
{
    [_cacheLock lock];
    ORKLogDebug(@"Invalidating cache entry for '%@'", cacheKey);
    NSString *cachePath = [self pathForCacheKey:cacheKey];
    if (cachePath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:cachePath error:NULL];
        ORKLogTrace(@"Removed cache entry at path '%@' for '%@'", cachePath, cacheKey);
    }
    [_cacheLock unlock];
}

- (void)invalidateSubDirectory:(NSString *)subDirectory
{
    [_cacheLock lock];
    if (_cachePath && subDirectory) {
        NSString *subDirectoryPath = [_cachePath stringByAppendingPathComponent:subDirectory];
        ORKLogInfo(@"Invalidating cache at path: %@", subDirectoryPath);
        NSFileManager *fileManager = [NSFileManager defaultManager];

        BOOL isDirectory = NO;
        BOOL fileExists = [fileManager fileExistsAtPath:subDirectoryPath isDirectory:&isDirectory];

        if (fileExists && isDirectory) {
            NSError *error = nil;
            NSArray *cacheEntries = [fileManager contentsOfDirectoryAtPath:subDirectoryPath error:&error];

            if (nil == error) {
                for (NSString *cacheEntry in cacheEntries) {
                    NSString *cacheEntryPath = [subDirectoryPath stringByAppendingPathComponent:cacheEntry];
                    [fileManager removeItemAtPath:cacheEntryPath error:&error];
                    if (nil != error) {
                        ORKLogError(@"Failed to delete cache entry for file: %@", cacheEntryPath);
                    }
                }
            } else {
                ORKLogWarning(@"Failed to fetch list of cache entries for cache path: %@", subDirectoryPath);
            }
        }
    }
    [_cacheLock unlock];
}

- (void)invalidateAll
{
    [_cacheLock lock];
    if (_cachePath) {
        ORKLogInfo(@"Invalidating cache at path: %@", _cachePath);
        NSFileManager *fileManager = [NSFileManager defaultManager];

        BOOL isDirectory = NO;
        BOOL fileExists = [fileManager fileExistsAtPath:_cachePath isDirectory:&isDirectory];

        if (fileExists && isDirectory) {
            NSError *error = nil;
            NSArray *cacheEntries = [fileManager contentsOfDirectoryAtPath:_cachePath error:&error];

            if (nil == error) {
                for (NSString *cacheEntry in cacheEntries) {
                    NSString *cacheEntryPath = [_cachePath stringByAppendingPathComponent:cacheEntry];
                    [fileManager removeItemAtPath:cacheEntryPath error:&error];
                    if (nil != error) {
                        ORKLogError(@"Failed to delete cache entry for file: %@", cacheEntryPath);
                    }
                }
            } else {
                ORKLogWarning(@"Failed to fetch list of cache entries for cache path: %@", _cachePath);
            }
        }
    }
    [_cacheLock unlock];
}

@end
