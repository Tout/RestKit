//
//  ORKRequestCache.m
//  RestKit
//
//  Created by Jeff Arena on 4/4/11.
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

#import "ORKRequestCache.h"
#import "ORKLog.h"

// Set Logging Component
#undef ORKLogComponent
#define ORKLogComponent lcl_cRestKitNetworkCache

NSString * const ORKRequestCacheSessionCacheDirectory = @"SessionStore";
NSString * const ORKRequestCachePermanentCacheDirectory = @"PermanentStore";
NSString * const ORKRequestCacheHeadersExtension = @"headers";
NSString * const ORKRequestCacheDateHeaderKey = @"X-RESTKIT-CACHEDATE";
NSString * const ORKRequestCacheStatusCodeHeadersKey = @"X-RESTKIT-CACHED-RESPONSE-CODE";
NSString * const ORKRequestCacheMIMETypeHeadersKey = @"X-RESTKIT-CACHED-MIME-TYPE";
NSString * const ORKRequestCacheURLHeadersKey = @"X-RESTKIT-CACHED-URL";

static NSDateFormatter *__rfc1123DateFormatter;

@implementation ORKRequestCache

@synthesize storagePolicy = _storagePolicy;

+ (NSDateFormatter *)rfc1123DateFormatter
{
    if (__rfc1123DateFormatter == nil) {
        __rfc1123DateFormatter = [[NSDateFormatter alloc] init];
        [__rfc1123DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [__rfc1123DateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss 'GMT'"];
    }
    return __rfc1123DateFormatter;
}

- (id)initWithPath:(NSString *)cachePath storagePolicy:(ORKRequestCacheStoragePolicy)storagePolicy
{
    self = [super init];
    if (self) {
        _cache = [[ORKCache alloc] initWithPath:cachePath
                                     subDirectories:
                  [NSArray arrayWithObjects:ORKRequestCacheSessionCacheDirectory,
                   ORKRequestCachePermanentCacheDirectory, nil]];
        self.storagePolicy = storagePolicy;
    }

    return self;
}

- (void)dealloc
{
    [_cache release];
    _cache = nil;
    [super dealloc];
}

- (NSString *)path
{
    return _cache.cachePath;
}

- (NSString *)pathForRequest:(ORKRequest *)request
{
    NSString *pathForRequest = nil;
    NSString *requestCacheKey = [request cacheKey];
    if (requestCacheKey) {
        if (_storagePolicy == ORKRequestCacheStoragePolicyForDurationOfSession) {
            pathForRequest = [ORKRequestCacheSessionCacheDirectory stringByAppendingPathComponent:requestCacheKey];

        } else if (_storagePolicy == ORKRequestCacheStoragePolicyPermanently) {
            pathForRequest = [ORKRequestCachePermanentCacheDirectory stringByAppendingPathComponent:requestCacheKey];
        }
        ORKLogTrace(@"Found cacheKey '%@' for %@", pathForRequest, request);
    } else {
        ORKLogTrace(@"Failed to find cacheKey for %@ due to nil cacheKey", request);
    }
    return pathForRequest;
}

- (BOOL)hasResponseForRequest:(ORKRequest *)request
{
    BOOL hasEntryForRequest = NO;
    NSString *cacheKey = [self pathForRequest:request];
    if (cacheKey) {
        hasEntryForRequest = ([_cache hasEntry:cacheKey] &&
                              [_cache hasEntry:[cacheKey stringByAppendingPathExtension:ORKRequestCacheHeadersExtension]]);
    }
    ORKLogTrace(@"Determined hasResponseForRequest: %@ => %@", request, hasEntryForRequest ? @"YES" : @"NO");
    return hasEntryForRequest;
}

- (void)storeResponse:(ORKResponse *)response forRequest:(ORKRequest *)request
{
    if ([self hasResponseForRequest:request]) {
        [self invalidateRequest:request];
    }

    if (_storagePolicy != ORKRequestCacheStoragePolicyDisabled) {
        NSString *cacheKey = [self pathForRequest:request];
        if (cacheKey) {
            [_cache writeData:response.body withCacheKey:cacheKey];

            NSMutableDictionary *headers = [response.allHeaderFields mutableCopy];
            if (headers) {
                // TODO: expose this?
                NSHTTPURLResponse *urlResponse = [response valueForKey:@"_httpURLResponse"];
                // Cache Loaded Time
                [headers setObject:[[ORKRequestCache rfc1123DateFormatter] stringFromDate:[NSDate date]]
                            forKey:ORKRequestCacheDateHeaderKey];
                // Cache status code
                [headers setObject:[NSNumber numberWithInteger:urlResponse.statusCode]
                            forKey:ORKRequestCacheStatusCodeHeadersKey];
                // Cache MIME Type
                [headers setObject:urlResponse.MIMEType
                            forKey:ORKRequestCacheMIMETypeHeadersKey];
                // Cache URL
                [headers setObject:[urlResponse.URL absoluteString]
                            forKey:ORKRequestCacheURLHeadersKey];
                // Save
                [_cache writeDictionary:headers withCacheKey:[cacheKey stringByAppendingPathExtension:ORKRequestCacheHeadersExtension]];
            }
            [headers release];
        }
    }
}

- (ORKResponse *)responseForRequest:(ORKRequest *)request
{
    ORKResponse *response = nil;
    NSString *cacheKey = [self pathForRequest:request];
    if (cacheKey) {
        NSData *responseData = [_cache dataForCacheKey:cacheKey];
        NSDictionary *responseHeaders = [_cache dictionaryForCacheKey:[cacheKey stringByAppendingPathExtension:ORKRequestCacheHeadersExtension]];
        response = [[[ORKResponse alloc] initWithRequest:request body:responseData headers:responseHeaders] autorelease];
    }
    ORKLogDebug(@"Found cached ORKResponse '%@' for '%@'", response, request);
    return response;
}

- (NSDictionary *)headersForRequest:(ORKRequest *)request
{
    NSDictionary *headers = nil;
    NSString *cacheKey = [self pathForRequest:request];
    if (cacheKey) {
        NSString *headersCacheKey = [cacheKey stringByAppendingPathExtension:ORKRequestCacheHeadersExtension];
        headers = [_cache dictionaryForCacheKey:headersCacheKey];
        if (headers) {
            ORKLogDebug(@"Read cached headers '%@' from headersCacheKey '%@' for '%@'", headers, headersCacheKey, request);
        } else {
            ORKLogDebug(@"Read nil cached headers from headersCacheKey '%@' for '%@'", headersCacheKey, request);
        }
    } else {
        ORKLogDebug(@"Unable to read cached headers for '%@': cacheKey not found", request);
    }
    return headers;
}

- (NSString *)etagForRequest:(ORKRequest *)request
{
    NSString *etag = nil;

    NSDictionary *responseHeaders = [self headersForRequest:request];
    if (responseHeaders) {
        for (NSString *responseHeader in responseHeaders) {
            if ([[responseHeader uppercaseString] isEqualToString:[@"ETag" uppercaseString]]) {
                etag = [responseHeaders objectForKey:responseHeader];
            }
        }
    }
    ORKLogDebug(@"Found cached ETag '%@' for '%@'", etag, request);
    return etag;
}

- (void)setCacheDate:(NSDate *)date forRequest:(ORKRequest *)request
{
    NSString *cacheKey = [self pathForRequest:request];
    if (cacheKey) {
        NSMutableDictionary *responseHeaders = [[self headersForRequest:request] mutableCopy];

        [responseHeaders setObject:[[ORKRequestCache rfc1123DateFormatter] stringFromDate:date]
                                     forKey:ORKRequestCacheDateHeaderKey];
        [_cache writeDictionary:responseHeaders
                   withCacheKey:[cacheKey stringByAppendingPathExtension:ORKRequestCacheHeadersExtension]];
        [responseHeaders release];
    }
}

- (NSDate *)cacheDateForRequest:(ORKRequest *)request
{
    NSDate *date = nil;
    NSString *dateString = nil;

    NSDictionary *responseHeaders = [self headersForRequest:request];
    if (responseHeaders) {
        for (NSString *responseHeader in responseHeaders) {
            if ([[responseHeader uppercaseString] isEqualToString:[ORKRequestCacheDateHeaderKey uppercaseString]]) {
                dateString = [responseHeaders objectForKey:responseHeader];
            }
        }
    }
    date = [[ORKRequestCache rfc1123DateFormatter] dateFromString:dateString];
    ORKLogDebug(@"Found cached date '%@' for '%@'", date, request);
    return date;
}

- (void)invalidateRequest:(ORKRequest *)request
{
    ORKLogDebug(@"Invalidating cache entry for '%@'", request);
    NSString *cacheKey = [self pathForRequest:request];
    if (cacheKey) {
        [_cache invalidateEntry:cacheKey];
        [_cache invalidateEntry:[cacheKey stringByAppendingPathExtension:ORKRequestCacheHeadersExtension]];
        ORKLogTrace(@"Removed cache entry at path '%@' for '%@'", cacheKey, request);
    }
}

- (void)invalidateWithStoragePolicy:(ORKRequestCacheStoragePolicy)storagePolicy
{
    if (storagePolicy != ORKRequestCacheStoragePolicyDisabled) {
        if (storagePolicy == ORKRequestCacheStoragePolicyForDurationOfSession) {
            [_cache invalidateSubDirectory:ORKRequestCacheSessionCacheDirectory];
        } else {
            [_cache invalidateSubDirectory:ORKRequestCachePermanentCacheDirectory];
        }
    }
}

- (void)invalidateAll
{
    ORKLogInfo(@"Invalidating all cache entries...");
    [_cache invalidateSubDirectory:ORKRequestCacheSessionCacheDirectory];
    [_cache invalidateSubDirectory:ORKRequestCachePermanentCacheDirectory];
}

- (void)setStoragePolicy:(ORKRequestCacheStoragePolicy)storagePolicy
{
    [self invalidateWithStoragePolicy:ORKRequestCacheStoragePolicyForDurationOfSession];
    if (storagePolicy == ORKRequestCacheStoragePolicyDisabled) {
        [self invalidateWithStoragePolicy:ORKRequestCacheStoragePolicyPermanently];
    }
    _storagePolicy = storagePolicy;
}

@end
