//
//  ORKRequestCache.h
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

#import "ORKRequest.h"
#import "ORKResponse.h"
#import "ORKCache.h"

/**
 Cache storage policy used to determines how long we keep a specific cache for.
 */
typedef enum {
    /**
     The cache is disabled. Attempts to store data will silently fail.
     */
    ORKRequestCacheStoragePolicyDisabled,
    /**
     Cache data for the length of the session and clear when the app exits.
     */
    ORKRequestCacheStoragePolicyForDurationOfSession,
    /**
     Cache data permanently until explicitly expired or flushed.
     */
    ORKRequestCacheStoragePolicyPermanently
} ORKRequestCacheStoragePolicy;

/**
 Location of session specific cache files within the Caches path.
 */
extern NSString * const ORKRequestCacheSessionCacheDirectory;

/**
 Location of permanent cache files within the Caches path.
 */
extern NSString * const ORKRequestCachePermanentCacheDirectory;

/**
 @constant ORKRequestCache Header Keys

 Constants for accessing cache specific X-RESTKIT
 headers used to store cache metadata within the cache entry.
*/
/** The key for accessing the date the entry was cached. **/
extern NSString * const ORKRequestCacheDateHeaderKey;

/** The key for accessing the status code of the cached request. **/
extern NSString * const ORKRequestCacheStatusCodeHeadersKey;

/** The key for accessing the MIME Type of the cached request. **/
extern NSString * const ORKRequestCacheMIMETypeHeadersKey;

/** The key for accessing the URL of the cached request. **/
extern NSString * const ORKRequestCacheURLHeadersKey;

/**
 Stores and retrieves cache entries for RestKit request objects.
 */
@interface ORKRequestCache : NSObject {
    ORKRequestCacheStoragePolicy _storagePolicy;
    ORKCache *_cache;
}

///-----------------------------------------------------------------------------
/// @name Initializating the Cache
///-----------------------------------------------------------------------------

/**
 Initializes the receiver with a cache at a given path and storage policy.

 @param cachePath The path to store cached data in.
 @param storagePolicy The storage policy to use for cached data.
 @return An initialized request cache object.
 */
- (id)initWithPath:(NSString *)cachePath storagePolicy:(ORKRequestCacheStoragePolicy)storagePolicy;

///-----------------------------------------------------------------------------
/// @name Locating the Cache
///-----------------------------------------------------------------------------

/**
 Returns the full pathname to the cache.
 */
@property (nonatomic, readonly) NSString *path;

/**
 Returns the cache path for the specified request.

 @param request An ORKRequest object to determine the cache path.
 @return A string of the cache path for the specified request.
 */
- (NSString *)pathForRequest:(ORKRequest *)request;

/**
 Determine if a response exists for a request.

 @param request An ORKRequest object that is looking for cached content.
 @return A boolean value for if a response exists in the cache.
 */
- (BOOL)hasResponseForRequest:(ORKRequest *)request;


///-----------------------------------------------------------------------------
/// @name Populating the Cache
///-----------------------------------------------------------------------------

/**
 Store a request's response in the cache.

 @param response The response to be stored in the cache.
 @param request The request that retrieved the response.
 */
- (void)storeResponse:(ORKResponse *)response forRequest:(ORKRequest *)request;

/**
 Set the cache date for a request.

 @param date The date the response for a request was cached.
 @param request The request to store the cache date for.
 */
- (void)setCacheDate:(NSDate *)date forRequest:(ORKRequest *)request;

///-----------------------------------------------------------------------------
/// @name Preparing Requests and Responses
///-----------------------------------------------------------------------------

/**
 Returns a dictionary of cached headers for a cached request.

 @param request The request to retrieve cached headers for.
 @return An NSDictionary of the cached headers that were stored for the
 specified request.
 */
- (NSDictionary *)headersForRequest:(ORKRequest *)request;

/**
 Returns an ETag for a request if it is stored in the cached headers.

 @param request The request that an ETag is to be determined for.
 @return A string of the ETag value stored for the specified request.
 */
- (NSString *)etagForRequest:(ORKRequest *)request;

/**
 Returns the date of the cached request.

 @param request The request that needs a cache date returned.
 @return A date object for the cached request.
 */
- (NSDate *)cacheDateForRequest:(ORKRequest *)request;

/**
 Returns the cached response for a given request.

 @param request The request used to find the cached response.
 @return An ORKResponse object that was cached for a given request.
 */
- (ORKResponse *)responseForRequest:(ORKRequest *)request;

///-----------------------------------------------------------------------------
/// @name Invalidating the Cache
///-----------------------------------------------------------------------------

/**
 The storage policy for the cache.
 */
@property (nonatomic, assign) ORKRequestCacheStoragePolicy storagePolicy;

/**
 Invalidate the cache for a given request.

 @param request The request that needs its cache invalidated.
 */
- (void)invalidateRequest:(ORKRequest *)request;

/**
 Invalidate any caches that fall under the given storage policy.

 @param storagePolicy The ORKRequestCacheStorePolicy used to determine which
 caches need to be invalidated.
 */
- (void)invalidateWithStoragePolicy:(ORKRequestCacheStoragePolicy)storagePolicy;

/**
 Invalidate all caches on disk.
 */
- (void)invalidateAll;


///-----------------------------------------------------------------------------
/// @name Helpers
///-----------------------------------------------------------------------------

/**
 The date formatter used to generate the cache date for the HTTP header.
 */
+ (NSDateFormatter *)rfc1123DateFormatter;

@end
