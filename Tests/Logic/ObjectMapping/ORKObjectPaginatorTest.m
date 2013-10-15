//
//  ORKObjectPaginatorTest.m
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

#import "ORKTestEnvironment.h"
#import "ORKObjectPaginator.h"
#import "ORKObjectMapperTestModel.h"
#import "NSURL+ORKAdditions.h"

NSString * const ORKTestPaginatorDelegateTimeoutException = @"ORKTestPaginatorDelegateTimeoutException";

@interface ORKTestPaginatorDelegate : NSObject <ORKObjectPaginatorDelegate>

@property (nonatomic, readonly, retain) NSArray *paginatedObjects;
@property (nonatomic, readonly, retain) NSError *paginationError;
@property (nonatomic, readonly) NSUInteger currentPage;
@property (nonatomic, readonly, getter = isLoading) BOOL loading;
@property (nonatomic, assign) NSTimeInterval timeout;

+ (ORKTestPaginatorDelegate *)paginatorDelegate;

- (BOOL)isLoaded;
- (BOOL)isError;
- (void)waitForLoad;

@end

@interface ORKTestPaginatorDelegate ()
@property (nonatomic, readwrite, retain) NSArray *paginatedObjects;
@property (nonatomic, readwrite, retain) NSError *paginationError;
@end

@implementation ORKTestPaginatorDelegate

@synthesize paginatedObjects;
@synthesize currentPage;
@synthesize paginationError;
@synthesize loading;
@synthesize timeout;

+ (ORKTestPaginatorDelegate *)paginatorDelegate
{
    return [[self new] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        currentPage = NSIntegerMax;
        timeout = 5;
    }

    return self;
}

- (void)dealloc
{
    [paginatedObjects release];
    [paginationError release];

    [super dealloc];
}

- (BOOL)isLoaded
{
    return currentPage != NSIntegerMax;
}

- (BOOL)isError
{
    return paginationError == nil;
}

- (void)waitForLoad
{
    loading = YES;
    self.paginatedObjects = nil;
    self.paginationError = nil;

    NSDate *startDate = [NSDate date];

    while (loading) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        if ([[NSDate date] timeIntervalSinceDate:startDate] > self.timeout) {
            [NSException raise:@"ORKTestPaginatorDelegateTimeoutException" format:@"*** Operation timed out after %f seconds...", self.timeout];
            loading = NO;
        }
    }
}

#pragma mark - ORKObjectPaginatorDelegate

- (void)paginator:(ORKObjectPaginator *)paginator didLoadObjects:(NSArray *)objects forPage:(NSUInteger)page
{
    loading = NO;
    self.paginatedObjects = objects;
    currentPage = page;
}

- (void)paginator:(ORKObjectPaginator *)paginator didFailWithError:(NSError *)error objectLoader:(ORKObjectLoader *)loader
{
    loading = NO;
    self.paginationError = error;
}

- (void)paginator:(ORKObjectPaginator *)paginator willLoadPage:(NSUInteger)page objectLoader:(ORKObjectLoader *)loader
{
    // Necessary for OCMock expectations
}

- (void)paginatorDidLoadFirstPage:(ORKObjectPaginator *)paginator
{
    // Necessary for OCMock expectations
}

- (void)paginatorDidLoadLastPage:(ORKObjectPaginator *)paginator
{
    // Necessary for OCMock expectations
}

@end

@interface ORKObjectPaginatorTest : ORKTestCase {
}

@end

@implementation ORKObjectPaginatorTest

static NSString * const ORKObjectPaginatorTestResourcePathPattern = @"/paginate?per_page=:perPage&page=:currentPage";

- (void)setUp
{
    [ORKTestFactory setUp];
}

- (void)tearDown
{
    [ORKTestFactory tearDown];
}

- (ORKObjectMappingProvider *)paginationMappingProvider
{
    ORKObjectMapping *paginationMapping = [ORKObjectMapping mappingForClass:[ORKObjectPaginator class]];
    [paginationMapping mapKeyPath:@"current_page" toAttribute:@"currentPage"];
    [paginationMapping mapKeyPath:@"per_page" toAttribute:@"perPage"];
    [paginationMapping mapKeyPath:@"total_entries" toAttribute:@"objectCount"];

    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[ORKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    ORKObjectMappingProvider *mappingProvider = [ORKObjectMappingProvider mappingProvider];
    mappingProvider.paginationMapping = paginationMapping;
    [mappingProvider setObjectMapping:mapping forKeyPath:@"entries"];

    return mappingProvider;
}

- (void)testInitCopiesPatternURL
{
    ORKURL *patternURL = [ORKURL URLWithBaseURLString:@"http://restkit.org"];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:nil];
    assertThat([paginator.patternURL absoluteString], is(equalTo(@"http://restkit.org")));
}

- (void)testInitRetainsMappingProvider
{
    ORKURL *patternURL = [ORKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    assertThat(paginator.mappingProvider, is(equalTo(mappingProvider)));
}

- (void)testInitDoesNotHavePageCount
{
    ORKURL *patternURL = [ORKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:nil];
    assertThatBool([paginator hasPageCount], is(equalToBool(NO)));
}

- (void)testInitDoesNotHaveObjectCount
{
    ORKURL *patternURL = [ORKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:nil];
    assertThatBool([paginator hasObjectCount], is(equalToBool(NO)));
}

- (void)testThatLoadWithNilMappingProviderRaisesException
{
    ORKURL *patternURL = [ORKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:nil];
    NSException *exception = nil;
    @try {
        [paginator loadPage:1];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

- (void)testThatResourcePathPatternEvaluatesAgainstPaginator
{
    ORKURL *patternURL = [ORKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:nil];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    NSUInteger currentPage = 1;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThat([[paginator URL] resourcePath], is(equalTo(@"/paginate?per_page=25&page=1")));
}

- (void)testThatURLReturnsReflectsStateOfPaginator
{
    ORKURL *patternURL = [ORKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:nil];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    NSUInteger currentPage = 1;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"1", @"page",
                                 @"25", @"per_page", nil];
    assertThat([[mockPaginator URL] queryParameters], is(equalTo(queryParams)));
}

- (void)testLoadingAPageOfObjects
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatBool([testDelegate isLoaded], is(equalToBool(YES)));
}

- (void)testLoadingPageOfObjectMapsPerPage
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.perPage, is(equalToInteger(3)));
}

- (void)testLoadingPageOfObjectMapsTotalEntries
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.objectCount, is(equalToInteger(6)));
}

- (void)testLoadingPageOfObjectMapsCurrentPage
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.currentPage, is(equalToInteger(1)));
}

- (void)testLoadingPageOfObjectMapsEntriesToObjects
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatInteger([[testDelegate paginatedObjects] count], is(equalToInteger(3)));
    assertThat([[testDelegate paginatedObjects] valueForKey:@"name"], is(equalTo([NSArray arrayWithObjects:@"Blake", @"Sarah", @"Colin", nil])));
}

- (void)testLoadingPageOfObjectHasPageCount
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatBool([paginator hasPageCount], is(equalToBool(YES)));
}

- (void)testLoadingPageOfObjectHasObjectCount
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatBool([paginator hasObjectCount], is(equalToBool(YES)));
}

- (void)testOnDidLoadObjectsForPageBlockIsInvokedOnLoad
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    __block NSArray *blockObjects = nil;
    paginator.onDidLoadObjectsForPage = ^(NSArray *objects, NSUInteger page) {
        blockObjects = objects;
    };
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThat(blockObjects, is(notNilValue()));
}

- (void)testDelegateIsInformedOfWillLoadPage
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    id mockDelegate = [OCMockObject partialMockForObject:testDelegate];
    [[mockDelegate expect] paginator:paginator willLoadPage:1 objectLoader:OCMOCK_ANY];
    paginator.delegate = mockDelegate;
    [paginator loadPage:1];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testDelegateIsInformedOnError
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    id mockDelegate = [OCMockObject partialMockForObject:testDelegate];
    [[[mockDelegate expect] andForwardToRealObject] paginator:paginator didFailWithError:OCMOCK_ANY objectLoader:OCMOCK_ANY];
    paginator.delegate = mockDelegate;
    [paginator loadPage:999];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testOnDidFailWithErrorBlockIsInvokedOnError
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    __block NSError *expectedError = nil;
    paginator.onDidFailWithError = ^(NSError *error, ORKObjectLoader *loader) {
        expectedError = error;
    };
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:999];
    [testDelegate waitForLoad];
    assertThat(expectedError, is(notNilValue()));
}

- (void)testDelegateIsInformedOnLoadOfFirstPage
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    id mockDelegate = [OCMockObject partialMockForObject:testDelegate];
    [[mockDelegate expect] paginatorDidLoadFirstPage:paginator];
    paginator.delegate = mockDelegate;
    [paginator loadPage:1];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testDelegateIsInformedOnLoadOfLastPage
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    id mockDelegate = [OCMockObject partialMockForObject:testDelegate];
    [[mockDelegate expect] paginatorDidLoadLastPage:paginator];
    paginator.delegate = mockDelegate;
    [paginator loadPage:2];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testLoadingNextPageOfObjects
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.currentPage, is(equalToInteger(1)));
    [paginator loadNextPage];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.currentPage, is(equalToInteger(2)));
    assertThat([[testDelegate paginatedObjects] valueForKey:@"name"], is(equalTo([NSArray arrayWithObjects:@"Asia", @"Roy", @"Lola", nil])));
}

- (void)testLoadingPreviousPageOfObjects
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:2];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.currentPage, is(equalToInteger(2)));
    [paginator loadPreviousPage];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.currentPage, is(equalToInteger(1)));
    assertThat([[testDelegate paginatedObjects] valueForKey:@"name"], is(equalTo([NSArray arrayWithObjects:@"Blake", @"Sarah", @"Colin", nil])));
}

- (void)testFailureWhenLoadingAPageOfObjects
{
    ORKURL *patternURL = [[ORKTestFactory baseURL] URLByAppendingResourcePath:ORKObjectPaginatorTestResourcePathPattern];
    ORKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    ORKObjectPaginator *paginator = [ORKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    ORKTestPaginatorDelegate *testDelegate = [ORKTestPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:3];
    [testDelegate waitForLoad];
    assertThat(testDelegate.paginationError, is(notNilValue()));
}

- (void)testKnowledgeOfHasANextPage
{
    ORKObjectPaginator *paginator = [[ORKObjectPaginator new] autorelease];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    BOOL isLoaded = YES;
    NSUInteger perPage = 5;
    NSUInteger pageCount = 3;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(isLoaded)] isLoaded];
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(perPage)] perPage];
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(pageCount)] pageCount];

    NSUInteger currentPage = 1;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasNextPage], is(equalToBool(YES)));
    currentPage = 2;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasNextPage], is(equalToBool(YES)));
    currentPage = 3;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasNextPage], is(equalToBool(NO)));
}

- (void)testHasNextPageRaisesExpectionWhenNotLoaded
{
    ORKObjectPaginator *paginator = [[ORKObjectPaginator new] autorelease];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    BOOL loaded = NO;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(loaded)] isLoaded];
    STAssertThrows([mockPaginator hasNextPage], @"Expected exception due to isLoaded == NO");
}

- (void)testHasNextPageRaisesExpectionWhenPageCountIsUnknown
{
    ORKObjectPaginator *paginator = [[ORKObjectPaginator new] autorelease];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    BOOL loaded = YES;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(loaded)] isLoaded];
    BOOL hasPageCount = NO;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(hasPageCount)] hasPageCount];
    STAssertThrows([mockPaginator hasNextPage], @"Expected exception due to pageCount == NSUIntegerMax");
}

- (void)testHasPreviousPageRaisesExpectionWhenNotLoaded
{
    ORKObjectPaginator *paginator = [[ORKObjectPaginator new] autorelease];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    BOOL loaded = NO;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(loaded)] isLoaded];
    STAssertThrows([mockPaginator hasPreviousPage], @"Expected exception due to isLoaded == NO");
}

- (void)testKnowledgeOfPreviousPage
{
    ORKObjectPaginator *paginator = [[ORKObjectPaginator new] autorelease];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    BOOL isLoaded = YES;
    NSUInteger perPage = 5;
    NSUInteger pageCount = 3;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(isLoaded)] isLoaded];
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(perPage)] perPage];
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(pageCount)] pageCount];

    NSUInteger currentPage = 3;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasPreviousPage], is(equalToBool(YES)));
    currentPage = 2;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasPreviousPage], is(equalToBool(YES)));
    currentPage = 1;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasPreviousPage], is(equalToBool(NO)));
}

@end
