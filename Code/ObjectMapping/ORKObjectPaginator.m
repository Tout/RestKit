//
//  ORKObjectPaginator.m
//  RestKit
//
//  Created by Blake Watters on 12/29/11.
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

#import "ORKObjectPaginator.h"
#import "ORKManagedObjectLoader.h"
#import "ORKObjectMappingOperation.h"
#import "ORKSOCKit.h"
#import "ORKLog.h"

static NSUInteger ORKObjectPaginatorDefaultPerPage = 25;

// Private interface
@interface ORKObjectPaginator () <ORKObjectLoaderDelegate>
@property (nonatomic, retain) ORKObjectLoader *objectLoader;
@end

@implementation ORKObjectPaginator

@synthesize patternURL;
@synthesize currentPage;
@synthesize perPage;
@synthesize loaded;
@synthesize pageCount;
@synthesize objectCount;
@synthesize mappingProvider;
@synthesize delegate;
@synthesize objectStore;
@synthesize objectLoader;
@synthesize configurationDelegate;
@synthesize onDidLoadObjectsForPage;
@synthesize onDidFailWithError;

+ (id)paginatorWithPatternURL:(ORKURL *)aPatternURL mappingProvider:(ORKObjectMappingProvider *)aMappingProvider
{
    return [[[self alloc] initWithPatternURL:aPatternURL mappingProvider:aMappingProvider] autorelease];
}

- (id)initWithPatternURL:(ORKURL *)aPatternURL mappingProvider:(ORKObjectMappingProvider *)aMappingProvider
{
    self = [super init];
    if (self) {
        patternURL = [aPatternURL copy];
        mappingProvider = [aMappingProvider retain];
        currentPage = NSUIntegerMax;
        pageCount = NSUIntegerMax;
        objectCount = NSUIntegerMax;
        perPage = ORKObjectPaginatorDefaultPerPage;
        loaded = NO;
    }

    return self;
}

- (void)dealloc
{
    delegate = nil;
    configurationDelegate = nil;
    objectLoader.delegate = nil;
    [patternURL release];
    patternURL = nil;
    [mappingProvider release];
    mappingProvider = nil;
    [objectStore release];
    objectStore = nil;
    [objectLoader cancel];
    objectLoader.delegate = nil;
    [objectLoader release];
    objectLoader = nil;
    [onDidLoadObjectsForPage release];
    onDidLoadObjectsForPage = nil;
    [onDidFailWithError release];
    onDidFailWithError = nil;

    [super dealloc];
}

- (ORKObjectMapping *)paginationMapping
{
    return [mappingProvider paginationMapping];
}

- (ORKURL *)URL
{
    return [patternURL URLByInterpolatingResourcePathWithObject:self];
}

// Private. Public consumers can rely on isLoaded
- (BOOL)hasCurrentPage
{
    return currentPage != NSUIntegerMax;
}

- (BOOL)hasPageCount
{
    return pageCount != NSUIntegerMax;
}

- (BOOL)hasObjectCount
{
    return objectCount != NSUIntegerMax;
}

- (NSUInteger)currentPage
{
    // Referenced during initial load, so we don't rely on isLoaded.
    NSAssert([self hasCurrentPage], @"Current page has not been initialized.");
    return currentPage;
}

- (NSUInteger)pageCount
{
    NSAssert([self hasPageCount], @"Page count not available.");
    return pageCount;
}

- (BOOL)hasNextPage
{
    NSAssert(self.isLoaded, @"Cannot determine hasNextPage: paginator is not loaded.");
    NSAssert([self hasPageCount], @"Cannot determine hasNextPage: page count is not known.");

    return self.currentPage < self.pageCount;
}

- (BOOL)hasPreviousPage
{
    NSAssert(self.isLoaded, @"Cannot determine hasPreviousPage: paginator is not loaded.");
    return self.currentPage > 1;
}

#pragma mark - ORKObjectLoaderDelegate methods

- (void)objectLoader:(ORKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    self.objectLoader = nil;
    loaded = YES;
    ORKLogInfo(@"Loaded objects: %@", objects);
    [self.delegate paginator:self didLoadObjects:objects forPage:self.currentPage];

    if (self.onDidLoadObjectsForPage) {
        self.onDidLoadObjectsForPage(objects, self.currentPage);
    }

    if ([self hasPageCount] && self.currentPage == 1) {
        if ([self.delegate respondsToSelector:@selector(paginatorDidLoadFirstPage:)]) {
            [self.delegate paginatorDidLoadFirstPage:self];
        }
    }

    if ([self hasPageCount] && self.currentPage == self.pageCount) {
        if ([self.delegate respondsToSelector:@selector(paginatorDidLoadLastPage:)]) {
            [self.delegate paginatorDidLoadLastPage:self];
        }
    }
}

- (void)objectLoader:(ORKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    ORKLogError(@"Paginator error %@", error);
    [self.delegate paginator:self didFailWithError:error objectLoader:self.objectLoader];
    if (self.onDidFailWithError) {
        self.onDidFailWithError(error, self.objectLoader);
    }
    self.objectLoader = nil;
}

- (void)objectLoader:(ORKObjectLoader *)loader willMapData:(inout id *)mappableData
{
    NSError *error = nil;
    ORKObjectMappingOperation *mappingOperation = [ORKObjectMappingOperation mappingOperationFromObject:*mappableData toObject:self withMapping:[self paginationMapping]];
    BOOL success = [mappingOperation performMapping:&error];
    if (!success) {
      pageCount = currentPage = 0;
      ORKLogError(@"Paginator didn't map info to compute page count. Assuming no pages.");
    } else if (self.perPage && [self hasObjectCount]) {
      float objectCountFloat = self.objectCount;
      pageCount = ceilf(objectCountFloat / self.perPage);
      ORKLogInfo(@"Paginator objectCount: %ld pageCount: %ld", (long)self.objectCount, (long)self.pageCount);
    } else {
      NSAssert(NO, @"Paginator perPage set is 0.");
      ORKLogError(@"Paginator perPage set is 0.");
    }
}

#pragma mark - Action methods

- (void)loadNextPage
{
    [self loadPage:currentPage + 1];
}

- (void)loadPreviousPage
{
    [self loadPage:currentPage - 1];
}

- (void)loadPage:(NSUInteger)pageNumber
{
    NSAssert(self.mappingProvider, @"Cannot perform a load with a nil mappingProvider.");
    NSAssert(! objectLoader, @"Cannot perform a load while one is already in progress.");
    currentPage = pageNumber;

    if (self.objectStore) {
        self.objectLoader = [[[ORKManagedObjectLoader alloc] initWithURL:self.URL mappingProvider:self.mappingProvider objectStore:self.objectStore] autorelease];
    } else {
        self.objectLoader = [[[ORKObjectLoader alloc] initWithURL:self.URL mappingProvider:self.mappingProvider] autorelease];
    }

    if ([self.configurationDelegate respondsToSelector:@selector(configureObjectLoader:)]) {
        [self.configurationDelegate configureObjectLoader:objectLoader];
    }
    self.objectLoader.method = ORKRequestMethodGET;
    self.objectLoader.delegate = self;

    if ([self.delegate respondsToSelector:@selector(paginator:willLoadPage:objectLoader:)]) {
        [self.delegate paginator:self willLoadPage:pageNumber objectLoader:self.objectLoader];
    }

    [self.objectLoader send];
}

@end
