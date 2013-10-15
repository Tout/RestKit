//
//  ORKFetchedResultsTableControllerTest.m
//  RestKit
//
//  Created by Jeff Arena on 8/12/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "ORKFetchedResultsTableController.h"
#import "ORKManagedObjectStore.h"
#import "ORKManagedObjectMapping.h"
#import "ORKHuman.h"
#import "ORKEvent.h"
#import "ORKAbstractTableController_Internals.h"
#import "ORKManagedObjectCaching.h"
#import "ORKTableControllerTestDelegate.h"

// Expose the object loader delegate for testing purposes...
@interface ORKFetchedResultsTableController () <ORKObjectLoaderDelegate>

- (BOOL)isHeaderSection:(NSUInteger)section;
- (BOOL)isHeaderRow:(NSUInteger)row;
- (BOOL)isFooterSection:(NSUInteger)section;
- (BOOL)isFooterRow:(NSUInteger)row;
- (BOOL)isEmptySection:(NSUInteger)section;
- (BOOL)isEmptyRow:(NSUInteger)row;
- (BOOL)isHeaderIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isFooterIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isEmptyItemIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)fetchedResultsIndexPathForIndexPath:(NSIndexPath *)indexPath;

@end

@interface ORKFetchedResultsTableControllerSpecViewController : UITableViewController
@end

@implementation ORKFetchedResultsTableControllerSpecViewController
@end

@interface ORKFetchedResultsTableControllerTest : ORKTestCase
@end

@implementation ORKFetchedResultsTableControllerTest

- (void)setUp
{
    [ORKTestFactory setUp];

    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setRootViewController:nil];
}

- (void)tearDown
{
    [ORKTestFactory tearDown];
}

- (void)bootstrapStoreAndCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForEntityWithName:@"ORKHuman" inManagedObjectStore:store];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";

    [ORKHuman truncateAll];
    assertThatInt([ORKHuman count:nil], is(equalToInt(0)));
    ORKHuman *blake = [ORKHuman createEntity];
    blake.railsID = [NSNumber numberWithInt:1234];
    blake.name = @"blake";
    ORKHuman *other = [ORKHuman createEntity];
    other.railsID = [NSNumber numberWithInt:5678];
    other.name = @"other";
    NSError *error = nil;
    [store save:&error];
    assertThat(error, is(nilValue()));
    assertThatInt([ORKHuman count:nil], is(equalToInt(2)));

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    objectManager.objectStore = store;

    [objectManager.mappingProvider setObjectMapping:humanMapping forResourcePathPattern:@"/JSON/humans/all\\.json" withFetchRequestBlock:^NSFetchRequest *(NSString *resourcePath) {
        return [ORKHuman requestAllSortedBy:@"name" ascending:YES];
    }];
}

- (void)bootstrapNakedObjectStoreAndCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *eventMapping = [ORKManagedObjectMapping mappingForClass:[ORKEvent class] inManagedObjectStore:store];
    [eventMapping mapKeyPath:@"event_id" toAttribute:@"eventID"];
    [eventMapping mapKeyPath:@"type" toAttribute:@"eventType"];
    [eventMapping mapAttributes:@"location", @"summary", nil];
    eventMapping.primaryKeyAttribute = @"eventID";
    [ORKEvent truncateAll];

    assertThatInt([ORKEvent count:nil], is(equalToInt(0)));
    ORKEvent *nakedEvent = [ORKEvent createEntity];
    nakedEvent.eventID = @"ORK4424";
    nakedEvent.eventType = @"Concert";
    nakedEvent.location = @"Performance Hall";
    nakedEvent.summary = @"Shindig";
    NSError *error = nil;
    [store save:&error];
    assertThat(error, is(nilValue()));
    assertThatInt([ORKEvent count:nil], is(equalToInt(1)));

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.mappingProvider addObjectMapping:eventMapping];
    objectManager.objectStore = store;

    id mockMappingProvider = [OCMockObject partialMockForObject:objectManager.mappingProvider];
    [[[mockMappingProvider stub] andReturn:[ORKEvent requestAllSortedBy:@"eventType" ascending:YES]] fetchRequestForResourcePath:@"/JSON/NakedEvents.json"];
}

- (void)bootstrapEmptyStoreAndCache
{
    ORKManagedObjectStore *store = [ORKTestFactory managedObjectStore];
    ORKManagedObjectMapping *humanMapping = [ORKManagedObjectMapping mappingForEntityWithName:@"ORKHuman" inManagedObjectStore:store];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";

    [ORKHuman truncateAll];
    assertThatInt([ORKHuman count:nil], is(equalToInt(0)));

    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    objectManager.objectStore = store;

    id mockMappingProvider = [OCMockObject partialMockForObject:objectManager.mappingProvider];
    [[[mockMappingProvider stub] andReturn:[ORKHuman requestAllSortedBy:@"name" ascending:YES]] fetchRequestForResourcePath:@"/JSON/humans/all.json"];
    [[[mockMappingProvider stub] andReturn:[ORKHuman requestAllSortedBy:@"name" ascending:YES]] fetchRequestForResourcePath:@"/empty/array"];
}

- (void)stubObjectManagerToOnline
{
    ORKObjectManager *objectManager = [ORKObjectManager sharedManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    ORKObjectManagerNetworkStatus networkStatus = ORKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
}

- (void)testLoadWithATableViewControllerAndResourcePath
{
    [self bootstrapStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.tableView, is(equalTo(viewController.tableView)));
    assertThat(tableController.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
}

- (void)testLoadWithATableViewControllerAndResourcePathFromNakedObjects
{
    [self bootstrapNakedObjectStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/NakedEvents.json";
    [tableController setObjectMappingForClass:[ORKEvent class]];
    [tableController loadTable];

    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.tableView, is(equalTo(viewController.tableView)));
    assertThat(tableController.resourcePath, is(equalTo(@"/JSON/NakedEvents.json")));

    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping mappingForClass:[UITableViewCell class]];
    [cellMapping mapKeyPath:@"summary" toAttribute:@"textLabel.text"];
    ORKTableViewCellMappings *mappings = [ORKTableViewCellMappings new];
    [mappings setCellMapping:cellMapping forClass:[ORKEvent class]];
    tableController.cellMappings = mappings;

    UITableViewCell *cell = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell.textLabel.text, is(equalTo(@"Shindig")));
}


- (void)testLoadWithATableViewControllerAndResourcePathAndPredicateAndSortDescriptors
{
    [self bootstrapStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    NSPredicate *predicate = [NSPredicate predicateWithValue:TRUE];
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                      ascending:YES]];
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.predicate = predicate;
    tableController.sortDescriptors = sortDescriptors;
    [tableController loadTable];

    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
    assertThat(tableController.fetchRequest, is(notNilValue()));
    assertThat([tableController.fetchRequest predicate], is(equalTo(predicate)));
    assertThat([tableController.fetchRequest sortDescriptors], is(equalTo(sortDescriptors)));
}

- (void)testLoadWithATableViewControllerAndResourcePathAndSectionNameAndCacheName
{
    [self bootstrapStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    tableController.cacheName = @"allHumansCache";
    [tableController loadTable];

    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
    assertThat(tableController.fetchRequest, is(notNilValue()));
    assertThat(tableController.fetchedResultsController.sectionNameKeyPath, is(equalTo(@"name")));
    assertThat(tableController.fetchedResultsController.cacheName, is(equalTo(@"allHumansCache")));
}

- (void)testLoadWithAllParams
{
    [self bootstrapStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    NSPredicate *predicate = [NSPredicate predicateWithValue:TRUE];
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                      ascending:YES]];
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.predicate = predicate;
    tableController.sortDescriptors = sortDescriptors;
    tableController.sectionNameKeyPath = @"name";
    tableController.cacheName = @"allHumansCache";
    [tableController loadTable];

    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
    assertThat(tableController.fetchRequest, is(notNilValue()));
    assertThat([tableController.fetchRequest predicate], is(equalTo(predicate)));
    assertThat([tableController.fetchRequest sortDescriptors], is(equalTo(sortDescriptors)));
    assertThat(tableController.fetchedResultsController.sectionNameKeyPath, is(equalTo(@"name")));
    assertThat(tableController.fetchedResultsController.cacheName, is(equalTo(@"allHumansCache")));
}

- (void)testAlwaysHaveAtLeastOneSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
}

#pragma mark - Section Management

- (void)testProperlyCountSections
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController loadTable];
    assertThatInt(tableController.sectionCount, is(equalToInt(2)));
}

- (void)testProperlyCountRows
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
}

- (void)testProperlyCountRowsWithHeaderItems
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(3)));
}

- (void)testProperlyCountRowsWithEmptyItemWhenEmpty
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(1)));
}

- (void)testProperlyCountRowsWithEmptyItemWhenFull
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
}

- (void)testProperlyCountRowsWithHeaderAndEmptyItemsWhenEmptyDontShowHeaders
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(1)));
}

- (void)testProperlyCountRowsWithHeaderAndEmptyItemsWhenEmptyShowHeaders
{
    [self bootstrapEmptyStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = YES;
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
}

- (void)testProperlyCountRowsWithHeaderAndEmptyItemsWhenFull
{
    [self bootstrapStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(3)));
}

#pragma mark - UITableViewDataSource specs

- (void)testRaiseAnExceptionIfSentAMessageWithATableViewItIsNotBoundTo
{
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerWithTableView:tableView forViewController:viewController];
    NSException *exception = nil;
    @try {
        [tableController numberOfSectionsInTableView:[UITableView new]];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

- (void)testReturnTheNumberOfSectionsInTableView
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController loadTable];

    assertThatInt([tableController numberOfSectionsInTableView:tableView], is(equalToInt(2)));
}

- (void)testReturnTheNumberOfRowsInSectionInTableView
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    assertThatInt([tableController tableView:tableView numberOfRowsInSection:0], is(equalToInt(2)));
}

- (void)testReturnTheHeaderTitleForSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController loadTable];

    assertThat([tableController tableView:tableView titleForHeaderInSection:1], is(equalTo(@"other")));
}

- (void)testReturnTheTableViewCellForRowAtIndexPath
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping mappingForClass:[UITableViewCell class]];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    ORKTableViewCellMappings *mappings = [ORKTableViewCellMappings new];
    [mappings setCellMapping:cellMapping forClass:[ORKHuman class]];
    tableController.cellMappings = mappings;

    UITableViewCell *cell = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell.textLabel.text, is(equalTo(@"blake")));
}

#pragma mark - Table Cell Mapping

- (void)testReturnTheObjectForARowAtIndexPath
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    ORKHuman *blake = [ORKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    assertThatBool(blake == [tableController objectForRowAtIndexPath:indexPath], is(equalToBool(YES)));
    [tableController release];
}

#pragma mark - Editing

- (void)testFireADeleteRequestWhenTheCanEditRowsPropertyIsSet
{
    [self bootstrapStoreAndCache];
    [self stubObjectManagerToOnline];
    [[ORKObjectManager sharedManager].router routeClass:[ORKHuman class]
                                        toResourcePath:@"/humans/:railsID"
                                             forMethod:ORKRequestMethodDELETE];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController = [ORKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.canEditRows = YES;
    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping cellMapping];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [tableController mapObjectsWithClass:[ORKHuman class] toTableCellsWithMapping:cellMapping];
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    NSIndexPath *deleteIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    ORKHuman *blake = [ORKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    ORKHuman *other = [ORKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(other)));
    assertThat([tableController objectForRowAtIndexPath:deleteIndexPath], is(equalTo(blake)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                                canEditRowAtIndexPath:deleteIndexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));

    [ORKTestNotificationObserver waitForNotificationWithName:ORKRequestDidLoadResponseNotification usingBlock:^{
        [tableController tableView:tableController.tableView
                commitEditingStyle:UITableViewCellEditingStyleDelete
                 forRowAtIndexPath:deleteIndexPath];
    }];

    assertThatInt([tableController rowCount], is(equalToInt(1)));
    assertThat([tableController objectForRowAtIndexPath:deleteIndexPath], is(equalTo(other)));
    assertThatBool([blake isDeleted], is(equalToBool(YES)));
}

- (void)testLocallyCommitADeleteWhenTheCanEditRowsPropertyIsSet
{
    [self bootstrapStoreAndCache];
    [self stubObjectManagerToOnline];

    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.canEditRows = YES;
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSIndexPath *deleteIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    ORKHuman *blake = [ORKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    ORKHuman *other = [ORKHuman findFirstByAttribute:@"name" withValue:@"other"];
    blake.railsID = nil;
    other.railsID = nil;

    NSError *error = nil;
    [blake.managedObjectContext save:&error];
    assertThat(error, is(nilValue()));

    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:deleteIndexPath], is(equalTo(other)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                                canEditRowAtIndexPath:deleteIndexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
            commitEditingStyle:UITableViewCellEditingStyleDelete
             forRowAtIndexPath:deleteIndexPath];
    assertThatInt([tableController rowCount], is(equalToInt(1)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
}

- (void)testNotCommitADeletionWhenTheCanEditRowsPropertyIsNotSet
{
    [self bootstrapStoreAndCache];
    [self stubObjectManagerToOnline];

    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    ORKHuman *blake = [ORKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    ORKHuman *other = [ORKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                                canEditRowAtIndexPath:indexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(NO)));
    [tableController tableView:tableController.tableView
            commitEditingStyle:UITableViewCellEditingStyleDelete
             forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(other)));
}

- (void)testDoNothingToCommitAnInsertionWhenTheCanEditRowsPropertyIsSet
{
    [self bootstrapStoreAndCache];
    [self stubObjectManagerToOnline];

    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.canEditRows = YES;
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    ORKHuman *blake = [ORKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    ORKHuman *other = [ORKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                                canEditRowAtIndexPath:indexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
            commitEditingStyle:UITableViewCellEditingStyleInsert
             forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(other)));
}

- (void)testNotMoveARowWhenTheCanMoveRowsPropertyIsSet
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.canMoveRows = YES;
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    ORKHuman *blake = [ORKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    ORKHuman *other = [ORKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanMove = [tableController tableView:tableController.tableView
                                canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
            moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                   toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(other)));
}

#pragma mark - Header, Footer, and Empty Rows

- (void)testDetermineIfASectionIndexIsAHeaderSection
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];
    assertThatBool([tableController isHeaderSection:0], is(equalToBool(YES)));
    assertThatBool([tableController isHeaderSection:1], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderSection:2], is(equalToBool(NO)));
}

- (void)testDetermineIfARowIndexIsAHeaderRow
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isHeaderRow:0], is(equalToBool(YES)));
    assertThatBool([tableController isHeaderRow:1], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderRow:2], is(equalToBool(NO)));
}

- (void)testDetermineIfASectionIndexIsAFooterSectionSingleSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isFooterSection:0], is(equalToBool(YES)));
    assertThatBool([tableController isFooterSection:1], is(equalToBool(NO)));
    assertThatBool([tableController isFooterSection:2], is(equalToBool(NO)));
}

- (void)testDetermineIfASectionIndexIsAFooterSectionMultipleSections
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isFooterSection:0], is(equalToBool(NO)));
    assertThatBool([tableController isFooterSection:1], is(equalToBool(YES)));
    assertThatBool([tableController isFooterSection:2], is(equalToBool(NO)));
}

- (void)testDetermineIfARowIndexIsAFooterRow
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isFooterRow:0], is(equalToBool(NO)));
    assertThatBool([tableController isFooterRow:1], is(equalToBool(NO)));
    assertThatBool([tableController isFooterRow:2], is(equalToBool(YES)));
}

- (void)testDetermineIfASectionIndexIsAnEmptySection
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];
    assertThatBool([tableController isEmptySection:0], is(equalToBool(YES)));
    assertThatBool([tableController isEmptySection:1], is(equalToBool(NO)));
    assertThatBool([tableController isEmptySection:2], is(equalToBool(NO)));
}

- (void)testDetermineIfARowIndexIsAnEmptyRow
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];
    assertThatBool([tableController isEmptyRow:0], is(equalToBool(YES)));
    assertThatBool([tableController isEmptyRow:1], is(equalToBool(NO)));
    assertThatBool([tableController isEmptyRow:2], is(equalToBool(NO)));
}

- (void)testDetermineIfAnIndexPathIsAHeaderIndexPath
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalToBool(YES)));
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalToBool(NO)));
}

- (void)testDetermineIfAnIndexPathIsAFooterIndexPath
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalToBool(YES)));
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalToBool(NO)));
}

- (void)testDetermineIfAnIndexPathIsAnEmptyIndexPathSingleSectionEmptyItemOnly
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalToBool(YES)));
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalToBool(NO)));
}

- (void)testConvertAnIndexPathForHeaderRows
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)testConvertAnIndexPathForFooterRowsSingleSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)testConvertAnIndexPathForFooterRowsMultipleSections
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:1])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:1])));
}

- (void)testConvertAnIndexPathForEmptyRow
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:3 inSection:0])));
}

- (void)testConvertAnIndexPathForHeaderFooterRowsSingleSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)testConvertAnIndexPathForHeaderFooterRowsMultipleSections
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:1])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:1])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:1])));
}

- (void)testConvertAnIndexPathForHeaderFooterEmptyRowsSingleSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:3 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:4 inSection:0])));
}

- (void)testConvertAnIndexPathForHeaderFooterEmptyRowsMultipleSections
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:1])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:1])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:1])));
}

- (void)testConvertAnIndexPathForHeaderEmptyRows
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)testShowHeaderRows
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    ORKTableItem *headerRow = [ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableController addHeaderRowForItem:headerRow];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    ORKHuman *blake = [ORKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    ORKHuman *other = [ORKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(3)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo(headerRow)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]],
               is(equalTo(other)));
}

- (void)testShowFooterRows
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    ORKTableItem *footerRow = [ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableController addFooterRowForItem:footerRow];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    ORKHuman *blake = [ORKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    ORKHuman *other = [ORKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(3)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo(other)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]],
               is(equalTo(footerRow)));
}

- (void)testHideHeaderRowsWhenEmptyWhenPropertyIsNotSet
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(0)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
}

- (void)testHideFooterRowsWhenEmptyWhenPropertyIsNotSet
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(0)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
}

- (void)testRemoveHeaderAndFooterCountsWhenDeterminingIsEmpty
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(1)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
}

- (void)testNotShowTheEmptyItemWhenTheTableIsNotEmpty
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";

    ORKTableItem *headerRow = [ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableController addHeaderRowForItem:headerRow];

    ORKTableItem *footerRow = [ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableController addFooterRowForItem:footerRow];

    ORKTableItem *emptyItem = [ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableController setEmptyItem:emptyItem];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    ORKHuman *blake = [ORKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    ORKHuman *other = [ORKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(4)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo(headerRow)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo(other)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]],
               is(equalTo(footerRow)));
}

- (void)testShowTheEmptyItemWhenTheTableIsEmpty
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(1)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
}

- (void)testShowTheEmptyItemPlusHeadersAndFootersWhenTheTableIsEmpty
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = YES;
    tableController.showsFooterRowsWhenEmpty = YES;
    [tableController loadTable];

    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(3)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
}

- (void)testShowTheEmptyImageAfterLoadingAnEmptyCollectionIntoAnEmptyFetch
{
    [self bootstrapEmptyStoreAndCache];
    [self stubObjectManagerToOnline];

    UITableView *tableView = [UITableView new];

    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController = [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                                                                   viewController:viewController];

    UIImage *image = [ORKTestFixture imageWithContentsOfFixture:@"blake.png"];

    tableController.imageForEmpty = image;
    tableController.resourcePath = @"/empty/array";
    tableController.autoRefreshFromNetwork = YES;
    [tableController.cache invalidateAll];

    [ORKTestNotificationObserver waitForNotificationWithName:ORKTableControllerDidFinishLoadNotification usingBlock:^{
        [tableController loadTable];
    }];
    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(0)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
    assertThat(tableController.stateOverlayImageView.image, is(notNilValue()));
}

- (void)testPostANotificationWhenObjectsAreLoaded
{
    [self bootstrapNakedObjectStoreAndCache];
    UITableView *tableView = [UITableView new];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/NakedEvents.json";
    [tableController setObjectMappingForClass:[ORKEvent class]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:ORKTableControllerDidLoadObjectsNotification object:tableController];
    [[observerMock expect] notificationWithName:ORKTableControllerDidLoadObjectsNotification object:tableController];
    [tableController loadTable];
    [observerMock verify];
}

#pragma mark - Delegate Methods

- (void)testDelegateIsInformedOnInsertSection
{
    [self bootstrapStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping cellMapping];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [tableController mapObjectsWithClass:[ORKHuman class] toTableCellsWithMapping:cellMapping];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.cacheName = @"allHumansCache";

    ORKFetchedResultsTableControllerTestDelegate *delegate = [ORKFetchedResultsTableControllerTestDelegate tableControllerDelegate];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[mockDelegate expect] tableController:tableController didInsertSectionAtIndex:0];
    tableController.delegate = mockDelegate;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setRootViewController:viewController];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThatInt([tableController sectionCount], is(equalToInt(1)));
    [mockDelegate verify];
}

- (void)testDelegateIsInformedOfDidStartLoad
{
    [self bootstrapStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping cellMapping];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [tableController mapObjectsWithClass:[ORKHuman class] toTableCellsWithMapping:cellMapping];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.cacheName = @"allHumansCache";

    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKFetchedResultsTableControllerDelegate)];
    [[mockDelegate expect] tableControllerDidStartLoad:tableController];
    tableController.delegate = mockDelegate;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setRootViewController:viewController];
    [tableController loadTable];
    [mockDelegate verify];
}

- (void)testDelegateIsInformedOfDidFinishLoad
{
    [self bootstrapStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping cellMapping];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [tableController mapObjectsWithClass:[ORKHuman class] toTableCellsWithMapping:cellMapping];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.cacheName = @"allHumansCache";

    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKFetchedResultsTableControllerDelegate)];
    [[mockDelegate expect] tableControllerDidFinishLoad:tableController];
    tableController.delegate = mockDelegate;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setRootViewController:viewController];
    [tableController loadTable];
    [mockDelegate verify];
}

- (void)testDelegateIsInformedOfDidInsertObjectAtIndexPath
{
    [self bootstrapStoreAndCache];
    ORKFetchedResultsTableControllerSpecViewController *viewController = [ORKFetchedResultsTableControllerSpecViewController new];
    ORKFetchedResultsTableController *tableController =
    [[ORKFetchedResultsTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping cellMapping];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [tableController mapObjectsWithClass:[ORKHuman class] toTableCellsWithMapping:cellMapping];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.cacheName = @"allHumansCache";

    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(ORKFetchedResultsTableControllerDelegate)];
    [[mockDelegate expect] tableController:tableController didInsertObject:OCMOCK_ANY atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[mockDelegate expect] tableController:tableController didInsertObject:OCMOCK_ANY atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableController.delegate = mockDelegate;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setRootViewController:viewController];
    [tableController loadTable];
    [mockDelegate verify];
}

@end
