//
//  ORKTableControllerTest.m
//  RestKit
//
//  Created by Blake Watters on 8/3/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "ORKTableController.h"
#import "ORKTableSection.h"
#import "ORKTestUser.h"
#import "ORKMappableObject.h"
#import "ORKAbstractTableController_Internals.h"
#import "ORKTableControllerTestDelegate.h"

// Expose the object loader delegate for testing purposes...
@interface ORKTableController () <ORKObjectLoaderDelegate>
- (void)animationDidStopAddingSwipeView:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
@end

@interface ORKTableControllerTestTableViewController : UITableViewController
@end

@implementation ORKTableControllerTestTableViewController
@end

@interface ORKTableControllerTestViewController : UIViewController
@end

@implementation ORKTableControllerTestViewController
@end

@interface ORKTestUserTableViewCell : UITableViewCell
@end

@implementation ORKTestUserTableViewCell
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface ORKTableControllerTest : ORKTestCase

@end

@implementation ORKTableControllerTest

- (void)setUp
{
    [ORKTestFactory setUp];
}

- (void)tearDown
{
    [ORKTestFactory tearDown];
}

- (void)testInitializeWithATableViewController
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    assertThat(viewController.tableView, is(notNilValue()));
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.tableView, is(equalTo(viewController.tableView)));
}

- (void)testInitializeWithATableViewAndViewController
{
    UITableView *tableView = [UITableView new];
    ORKTableControllerTestViewController *viewController = [ORKTableControllerTestViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerWithTableView:tableView forViewController:viewController];
    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.tableView, is(equalTo(tableView)));
}

- (void)testInitializesToUnloadedState
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
}

- (void)testAlwaysHaveAtLeastOneSection
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    assertThat(viewController.tableView, is(notNilValue()));
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
}

- (void)testDisconnectFromTheTableViewOnDealloc
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
    [pool drain];
    assertThat(viewController.tableView.delegate, is(nilValue()));
    assertThat(viewController.tableView.dataSource, is(nilValue()));
}

- (void)testNotDisconnectFromTheTableViewIfDelegateOrDataSourceAreNotSelf
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [[ORKTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    viewController.tableView.delegate = viewController;
    viewController.tableView.dataSource = viewController;
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
    [tableController release];
    assertThat(viewController.tableView.delegate, isNot(nilValue()));
    assertThat(viewController.tableView.dataSource, isNot(nilValue()));
}

#pragma mark - Section Management

- (void)testAddASection
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    [tableController addSection:section];
    assertThatInt([tableController.sections count], is(equalToInt(2)));
}

- (void)testConnectTheSectionToTheTableModelOnAdd
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    [tableController addSection:section];
    assertThat(section.tableController, is(equalTo(tableController)));
}

- (void)testConnectTheSectionToTheCellMappingsOfTheTableModelWhenNil
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    assertThat(section.cellMappings, is(nilValue()));
    [tableController addSection:section];
    assertThat(section.cellMappings, is(equalTo(tableController.cellMappings)));
}

- (void)testNotConnectTheSectionToTheCellMappingsOfTheTableModelWhenNonNil
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    section.cellMappings = [NSMutableDictionary dictionary];
    [tableController addSection:section];
    assertThatBool(section.cellMappings == tableController.cellMappings, is(equalToBool(NO)));
}

- (void)testCountTheSections
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    [tableController addSection:section];
    assertThatInt(tableController.sectionCount, is(equalToInt(2)));
}

- (void)testRemoveASection
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    [tableController addSection:section];
    assertThatInt(tableController.sectionCount, is(equalToInt(2)));
    [tableController removeSection:section];
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
}

- (void)testNotLetRemoveTheLastSection
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    [tableController addSection:section];
    assertThatInt(tableController.sectionCount, is(equalToInt(2)));
    [tableController removeSection:section];
}

- (void)testInsertASectionAtATestificIndex
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *referenceSection = [ORKTableSection section];
    [tableController addSection:[ORKTableSection section]];
    [tableController addSection:[ORKTableSection section]];
    [tableController addSection:[ORKTableSection section]];
    [tableController addSection:[ORKTableSection section]];
    [tableController insertSection:referenceSection atIndex:2];
    assertThatInt(tableController.sectionCount, is(equalToInt(6)));
    assertThat([tableController.sections objectAtIndex:2], is(equalTo(referenceSection)));
}

- (void)testRemoveASectionByIndex
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    [tableController addSection:section];
    assertThatInt(tableController.sectionCount, is(equalToInt(2)));
    [tableController removeSectionAtIndex:1];
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
}

- (void)testRaiseAnExceptionWhenAttemptingToRemoveTheLastSection
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    NSException *exception = nil;
    @try {
        [tableController removeSectionAtIndex:0];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, isNot(nilValue()));
    }
}

- (void)testReturnTheSectionAtAGivenIndex
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *referenceSection = [ORKTableSection section];
    [tableController addSection:[ORKTableSection section]];
    [tableController addSection:[ORKTableSection section]];
    [tableController addSection:[ORKTableSection section]];
    [tableController addSection:[ORKTableSection section]];
    [tableController insertSection:referenceSection atIndex:2];
    assertThatInt(tableController.sectionCount, is(equalToInt(6)));
    assertThat([tableController sectionAtIndex:2], is(equalTo(referenceSection)));
}

- (void)testRemoveAllSections
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController addSection:[ORKTableSection section]];
    [tableController addSection:[ORKTableSection section]];
    [tableController addSection:[ORKTableSection section]];
    [tableController addSection:[ORKTableSection section]];
    assertThatInt(tableController.sectionCount, is(equalToInt(5)));
    [tableController removeAllSections];
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
}

- (void)testReturnASectionByHeaderTitle
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController addSection:[ORKTableSection section]];
    [tableController addSection:[ORKTableSection section]];
    ORKTableSection *titledSection = [ORKTableSection section];
    titledSection.headerTitle = @"Testing";
    [tableController addSection:titledSection];
    [tableController addSection:[ORKTableSection section]];
    assertThat([tableController sectionWithHeaderTitle:@"Testing"], is(equalTo(titledSection)));
}

- (void)testNotifyTheTableViewOnSectionInsertion
{
    ORKTableControllerTestViewController *viewController = [ORKTableControllerTestViewController new];
    id mockTableView = [OCMockObject niceMockForClass:[UITableView class]];
    ORKTableController *tableController = [ORKTableController tableControllerWithTableView:mockTableView forViewController:viewController];
    [[mockTableView expect] insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableController.defaultRowAnimation];
    [tableController addSection:[ORKTableSection section]];
    [mockTableView verify];
}

- (void)testNotifyTheTableViewOnSectionRemoval
{
    ORKTableControllerTestViewController *viewController = [ORKTableControllerTestViewController new];
    id mockTableView = [OCMockObject niceMockForClass:[UITableView class]];
    ORKTableController *tableController = [ORKTableController tableControllerWithTableView:mockTableView forViewController:viewController];
    [[mockTableView expect] insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableController.defaultRowAnimation];
    [[mockTableView expect] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableController.defaultRowAnimation];
    ORKTableSection *section = [ORKTableSection section];
    [tableController addSection:section];
    [tableController removeSection:section];
    [mockTableView verify];
}

- (void)testNotifyTheTableOfSectionRemovalAndReaddWhenRemovingAllSections
{
    ORKTableControllerTestViewController *viewController = [ORKTableControllerTestViewController new];
    id mockTableView = [OCMockObject niceMockForClass:[UITableView class]];
    ORKTableController *tableController = [ORKTableController tableControllerWithTableView:mockTableView forViewController:viewController];
    [[mockTableView expect] deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:tableController.defaultRowAnimation];
    [[mockTableView expect] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableController.defaultRowAnimation];
    [[mockTableView expect] insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:tableController.defaultRowAnimation];
    ORKTableSection *section = [ORKTableSection section];
    [tableController addSection:section];
    [tableController removeAllSections];
    [mockTableView verify];
}

#pragma mark - UITableViewDataSource Tests

- (void)testRaiseAnExceptionIfSentAMessageWithATableViewItIsNotBoundTo
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
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
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatInt([tableController numberOfSectionsInTableView:viewController.tableView], is(equalToInt(1)));
    [tableController addSection:[ORKTableSection section]];
    assertThatInt([tableController numberOfSectionsInTableView:viewController.tableView], is(equalToInt(2)));
}

- (void)testReturnTheNumberOfRowsInSectionInTableView
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatInt([tableController tableView:viewController.tableView numberOfRowsInSection:0], is(equalToInt(0)));
    NSArray *objects = [NSArray arrayWithObject:@"one"];
    [tableController loadObjects:objects];
    assertThatInt([tableController tableView:viewController.tableView numberOfRowsInSection:0], is(equalToInt(1)));
}

- (void)testReturnTheHeaderTitleForSection
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    [tableController addSection:section];
    assertThat([tableController tableView:viewController.tableView titleForHeaderInSection:1], is(nilValue()));
    section.headerTitle = @"RestKit!";
    assertThat([tableController tableView:viewController.tableView titleForHeaderInSection:1], is(equalTo(@"RestKit!")));
}

- (void)testReturnTheTitleForFooterInSection
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    [tableController addSection:section];
    assertThat([tableController tableView:viewController.tableView titleForFooterInSection:1], is(nilValue()));
    section.footerTitle = @"RestKit!";
    assertThat([tableController tableView:viewController.tableView titleForFooterInSection:1], is(equalTo(@"RestKit!")));
}

- (void)testReturnTheNumberOfRowsAcrossAllSections
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableSection *section = [ORKTableSection section];
    id sectionMock = [OCMockObject partialMockForObject:section];
    NSUInteger rowCount = 5;
    [[[sectionMock stub] andReturnValue:OCMOCK_VALUE(rowCount)] rowCount];
    [tableController addSection:section];
    assertThatInt(tableController.rowCount, is(equalToInt(5)));
}

- (void)testReturnTheTableViewCellForRowAtIndexPath
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableItem *item = [ORKTableItem tableItemWithText:@"Test!" detailText:@"Details!" image:nil];
    [tableController loadTableItems:[NSArray arrayWithObject:item] inSection:0 withMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        // Detail text label won't appear with default style...
        cellMapping.style = UITableViewCellStyleValue1;
        [cellMapping addDefaultMappings];
    }]];
    UITableViewCell *cell = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell.textLabel.text, is(equalTo(@"Test!")));
    assertThat(cell.detailTextLabel.text, is(equalTo(@"Details!")));

}

#pragma mark - Table Cell Mapping

- (void)testInitializeCellMappings
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThat(tableController.cellMappings, is(notNilValue()));
}

- (void)testRegisterMappingsForObjectsToTableViewCell
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThat([tableController.cellMappings cellMappingForClass:[ORKTestUser class]], is(nilValue()));
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMapping]];
    ORKObjectMapping *mapping = [tableController.cellMappings cellMappingForClass:[ORKTestUser class]];
    assertThat(mapping, isNot(nilValue()));
    assertThatBool([mapping.objectClass isSubclassOfClass:[UITableViewCell class]], is(equalToBool(YES)));
}

- (void)testDefaultTheReuseIdentifierToTheNameOfTheObjectClass
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThat([tableController.cellMappings cellMappingForClass:[ORKTestUser class]], is(nilValue()));
    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping cellMapping];
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:cellMapping];
    assertThat(cellMapping.reuseIdentifier, is(equalTo(@"UITableViewCell")));
}

- (void)testDefaultTheReuseIdentifierToTheNameOfTheObjectClassWhenCreatingMappingWithBlockSyntax
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThat([tableController.cellMappings cellMappingForClass:[ORKTestUser class]], is(nilValue()));
    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.cellClass = [ORKTestUserTableViewCell class];
    }];
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:cellMapping];
    assertThat(cellMapping.reuseIdentifier, is(equalTo(@"ORKTestUserTableViewCell")));
}

- (void)testReturnTheObjectForARowAtIndexPath
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTestUser *user = [ORKTestUser user];
    [tableController loadObjects:[NSArray arrayWithObject:user]];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    assertThatBool(user == [tableController objectForRowAtIndexPath:indexPath], is(equalToBool(YES)));
}

- (void)testReturnTheCellMappingForTheRowAtIndexPath
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping cellMapping];
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:cellMapping];
    [tableController loadObjects:[NSArray arrayWithObject:[ORKTestUser user]]];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    assertThat([tableController cellMappingForObjectAtIndexPath:indexPath], is(equalTo(cellMapping)));
}

- (void)testReturnATableViewCellForTheObjectAtAGivenIndexPath
{
    ORKMappableObject *object = [ORKMappableObject new];
    object.stringTest = @"Testing!!";
    ORKTableViewCellMapping *cellMapping = [ORKTableViewCellMapping mappingForClass:[UITableViewCell class]];
    [cellMapping mapKeyPath:@"stringTest" toAttribute:@"textLabel.text"];
    NSArray *objects = [NSArray arrayWithObject:object];
    ORKTableViewCellMappings *mappings = [ORKTableViewCellMappings new];
    [mappings setCellMapping:cellMapping forClass:[ORKMappableObject class]];
    ORKTableSection *section = [ORKTableSection sectionForObjects:objects withMappings:mappings];
    UITableViewController *tableViewController = [UITableViewController new];
    tableViewController.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStylePlain];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:tableViewController];
    [tableController insertSection:section atIndex:0];
    tableController.cellMappings = mappings;

    UITableViewCell *cell = [tableController cellForObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell, isNot(nilValue()));
    assertThat(cell.textLabel.text, is(equalTo(@"Testing!!")));
}

- (void)testChangeTheReuseIdentifierWhenMutatedWithinTheBlockInitializer
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThat([tableController.cellMappings cellMappingForClass:[ORKTestUser class]], is(nilValue()));
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.cellClass = [ORKTestUserTableViewCell class];
        cellMapping.reuseIdentifier = @"ORKTestUserOverride";
    }]];
    ORKTableViewCellMapping *userCellMapping = [tableController.cellMappings cellMappingForClass:[ORKTestUser class]];
    assertThat(userCellMapping, isNot(nilValue()));
    assertThat(userCellMapping.reuseIdentifier, is(equalTo(@"ORKTestUserOverride")));
}

#pragma mark - Static Object Loading

- (void)testLoadAnArrayOfObjects
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    NSArray *objects = [NSArray arrayWithObject:@"one"];
    assertThat([tableController sectionAtIndex:0].objects, is(empty()));
    [tableController loadObjects:objects];
    assertThat([tableController sectionAtIndex:0].objects, is(equalTo(objects)));
}

- (void)testLoadAnArrayOfObjectsToTheTestifiedSection
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController addSection:[ORKTableSection section]];
    NSArray *objects = [NSArray arrayWithObject:@"one"];
    assertThat([tableController sectionAtIndex:1].objects, is(empty()));
    [tableController loadObjects:objects inSection:1];
    assertThat([tableController sectionAtIndex:1].objects, is(equalTo(objects)));
}

- (void)testLoadAnArrayOfTableItems
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    NSArray *tableItems = [ORKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableController loadTableItems:tableItems];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
    UITableViewCell *cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"One")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Three")));
}

- (void)testAllowYouToTriggerAnEmptyLoad
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

#pragma mark - Network Load

- (void)testLoadCollectionOfObjectsAndMapThemIntoTableViewCells
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.client.cachePolicy = ORKRequestCachePolicyNone;
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate tableControllerDelegate];
    delegate.timeout = 10;
    tableController.delegate = delegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
}

- (void)testSetTheModelToTheLoadedStateIfObjectsAreLoadedSuccessfully
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    NSArray *objects = [NSArray arrayWithObject:[ORKTestUser new]];
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    [tableController objectLoader:mockLoader didLoadObjects:objects];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
}

- (void)testSetTheModelToErrorStateIfTheObjectLoaderFailsWithAnError
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    id mockObjectLoader = [OCMockObject niceMockForClass:[ORKObjectLoader class]];
    NSError *error = [NSError errorWithDomain:@"Test" code:0 userInfo:nil];
    [tableController objectLoader:mockObjectLoader didFailWithError:error];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatBool([tableController isError], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

- (void)testErrorIsClearedAfterSubsequentLoad
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    id mockObjectLoader = [OCMockObject niceMockForClass:[ORKObjectLoader class]];
    NSError *error = [NSError errorWithDomain:@"Test" code:0 userInfo:nil];
    [tableController objectLoader:mockObjectLoader didFailWithError:error];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatBool([tableController isError], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));

    [tableController objectLoader:mockObjectLoader didLoadObjects:[NSArray array]];
    assertThatBool([tableController isError], is(equalToBool(NO)));
    assertThat(tableController.error, is(nilValue()));
}

- (void)testDisplayOfErrorImageTakesPresendenceOverEmpty
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    UIImage *imageForEmpty = [ORKTestFixture imageWithContentsOfFixture:@"blake.png"];
    UIImage *imageForError = [imageForEmpty copy];
    tableController.imageForEmpty = imageForEmpty;
    tableController.imageForError = imageForError;

    id mockObjectLoader = [OCMockObject niceMockForClass:[ORKObjectLoader class]];
    NSError *error = [NSError errorWithDomain:@"Test" code:0 userInfo:nil];
    [tableController objectLoader:mockObjectLoader didFailWithError:error];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatBool([tableController isError], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));

    UIImage *overlayImage = [tableController overlayImage];
    assertThat(overlayImage, isNot(nilValue()));
    assertThat(overlayImage, is(equalTo(imageForError)));
}

- (void)testBitwiseLoadingTransition
{
    ORKTableControllerState oldState = ORKTableControllerStateNotYetLoaded;
    ORKTableControllerState newState = ORKTableControllerStateLoading;

    BOOL loadingTransitioned = ((oldState ^ newState) & ORKTableControllerStateLoading);
    assertThatBool(loadingTransitioned, is(equalToBool(YES)));

    oldState = ORKTableControllerStateOffline | ORKTableControllerStateEmpty;
    newState = ORKTableControllerStateOffline | ORKTableControllerStateEmpty | ORKTableControllerStateLoading;
    loadingTransitioned = ((oldState ^ newState) & ORKTableControllerStateLoading);
    assertThatBool(loadingTransitioned, is(equalToBool(YES)));

    oldState = ORKTableControllerStateNormal;
    newState = ORKTableControllerStateLoading;
    loadingTransitioned = ((oldState ^ newState) & ORKTableControllerStateLoading);
    assertThatBool(loadingTransitioned, is(equalToBool(YES)));

    oldState = ORKTableControllerStateOffline | ORKTableControllerStateEmpty | ORKTableControllerStateLoading;
    newState = ORKTableControllerStateOffline | ORKTableControllerStateLoading;
    loadingTransitioned = ((oldState ^ newState) & ORKTableControllerStateLoading);
    assertThatBool(loadingTransitioned, is(equalToBool(NO)));

    oldState = ORKTableControllerStateNotYetLoaded;
    newState = ORKTableControllerStateOffline;
    loadingTransitioned = ((oldState ^ newState) & ORKTableControllerStateLoading);
    assertThatBool(loadingTransitioned, is(equalToBool(NO)));
}

- (void)testSetTheModelToAnEmptyStateIfTheObjectLoaderReturnsAnEmptyCollection
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    NSArray *objects = [NSArray array];
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    [tableController objectLoader:mockLoader didLoadObjects:objects];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

- (void)testSetTheModelToALoadedStateEvenIfTheObjectLoaderReturnsAnEmptyCollection
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    NSArray *objects = [NSArray array];
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    [tableController objectLoader:mockLoader didLoadObjects:objects];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
}

- (void)testEnterTheLoadingStateWhenTheRequestStartsLoading
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
}

- (void)testExitTheLoadingStateWhenTheRequestFinishesLoading
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject niceMockForClass:[ORKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
    [tableController objectLoaderDidFinishLoading:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
}

- (void)testClearTheLoadingStateWhenARequestIsCancelled
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
    [tableController requestDidCancelLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
}

- (void)testClearTheLoadingStateWhenARequestTimesOut
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
    [tableController requestDidTimeout:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
}

- (void)testDoSomethingWhenTheRequestLoadsAnUnexpectedResponse
{
    ORKLogCritical(@"PENDING - Undefined Behavior!!!");
}

- (void)testLoadCollectionOfObjectsAndMapThemIntoSections
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.client.cachePolicy = ORKRequestCachePolicyNone;
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    tableController.sectionNameKeyPath = @"name";
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate tableControllerDelegate];
    delegate.timeout = 10;
    tableController.delegate = delegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.sectionCount, is(equalToInt(3)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
}

- (void)testLoadingACollectionOfObjectsIntoSectionsAndThenLoadingAnEmptyCollectionChangesTableToEmpty
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.client.cachePolicy = ORKRequestCachePolicyNone;
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    tableController.sectionNameKeyPath = @"name";
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate tableControllerDelegate];
    delegate.timeout = 10;
    tableController.delegate = delegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.sectionCount, is(equalToInt(3)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
    delegate = [ORKTableControllerTestDelegate tableControllerDelegate];
    delegate.timeout = 10;
    tableController.delegate = delegate;
    [tableController loadTableFromResourcePath:@"/204" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

#pragma mark - ORKTableViewDelegate Tests

- (void)testNotifyTheDelegateWhenLoadingStarts
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    id mockDelegate = [OCMockObject partialMockForObject:[ORKTableControllerTestDelegate new]];
    [[[mockDelegate expect] andForwardToRealObject] tableControllerDidStartLoad:tableController];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenLoadingFinishes
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableControllerDidFinishLoad:tableController];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateOnDidFinalizeLoad
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[mockDelegate expect] tableControllerDidFinalizeLoad:tableController];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenAnErrorOccurs
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController didFailLoadWithError:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/fail" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenAnEmptyCollectionIsLoaded
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.client.cachePolicy = ORKRequestCachePolicyNone;
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    delegate.timeout = 5;
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableControllerDidBecomeEmpty:tableController];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/empty/array" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenModelWillLoadWithObjectLoader
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController willLoadTableWithObjectLoader:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/empty/array" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenModelDidLoadWithObjectLoader
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController didLoadTableWithObjectLoader:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/empty/array" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenModelDidCancelLoad
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableControllerDidCancelLoad:tableController];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/empty/array" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [tableController cancelLoad];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenDidEndEditingARow
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                     didEndEditing:OCMOCK_ANY
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    tableController.delegate = mockDelegate;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableController tableView:tableController.tableView didEndEditingRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenWillBeginEditingARow
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  willBeginEditing:OCMOCK_ANY
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    tableController.delegate = mockDelegate;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableController tableView:tableController.tableView willBeginEditingRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenAnObjectIsInserted
{
    NSArray *objects = [NSArray arrayWithObject:@"first object"];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"first object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"new object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableController.delegate = mockDelegate;
    [tableController loadObjects:objects];
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"first object")));
    [[tableController.sections objectAtIndex:0] insertObject:@"new object" atIndex:1];
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"new object")));
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenAnObjectIsUpdated
{
    NSArray *objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"first object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didUpdateObject:@"new second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableController.delegate = mockDelegate;
    [tableController loadObjects:objects];
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"second object")));
    [[tableController.sections objectAtIndex:0] replaceObjectAtIndex:1 withObject:@"new second object"];
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"new second object")));
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenAnObjectIsDeleted
{
    NSArray *objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"first object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didDeleteObject:@"second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableController.delegate = mockDelegate;
    [tableController loadObjects:objects];
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"second object")));
    [[tableController.sections objectAtIndex:0] removeObjectAtIndex:1];
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testNotifyTheDelegateWhenObjectsAreLoadedInASection
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[mockDelegate expect] tableController:tableController didLoadObjects:OCMOCK_ANY inSection:OCMOCK_ANY];
    tableController.delegate = mockDelegate;

    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testDelegateIsNotifiedOfWillDisplayCellForObjectAtIndexPath
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    }]];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController willLoadTableWithObjectLoader:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [[mockDelegate expect] tableController:tableController willDisplayCell:OCMOCK_ANY forObject:OCMOCK_ANY atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[mockDelegate expect] tableController:tableController willDisplayCell:OCMOCK_ANY forObject:OCMOCK_ANY atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [[mockDelegate expect] tableController:tableController willDisplayCell:OCMOCK_ANY forObject:OCMOCK_ANY atIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [[[UIApplication sharedApplication].windows objectAtIndex:0] setRootViewController:viewController];
    [mockDelegate waitForLoad];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testDelegateIsNotifiedOfDidSelectRowForObjectAtIndexPath
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    }]];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController willLoadTableWithObjectLoader:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [[mockDelegate expect] tableController:tableController didSelectCell:OCMOCK_ANY forObject:OCMOCK_ANY atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[UIApplication sharedApplication].windows objectAtIndex:0] setRootViewController:viewController];
    [mockDelegate waitForLoad];
    [tableController tableView:tableController.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    STAssertNoThrow([mockDelegate verify], nil);
}

#pragma mark - Notifications

- (void)testPostANotificationWhenLoadingStarts
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:ORKTableControllerDidStartLoadNotification object:tableController];
    [[observerMock expect] notificationWithName:ORKTableControllerDidStartLoadNotification object:tableController];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    tableController.delegate = delegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

- (void)testPostANotificationWhenLoadingFinishes
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:ORKTableControllerDidFinishLoadNotification object:tableController];
    [[observerMock expect] notificationWithName:ORKTableControllerDidFinishLoadNotification object:tableController];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    tableController.delegate = delegate;

    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

- (void)testPostANotificationWhenObjectsAreLoaded
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:ORKTableControllerDidLoadObjectsNotification object:tableController];
    [[observerMock expect] notificationWithName:ORKTableControllerDidLoadObjectsNotification object:tableController];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    tableController.delegate = delegate;

    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

- (void)testPostANotificationWhenAnErrorOccurs
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:ORKTableControllerDidLoadErrorNotification object:tableController];
    [[observerMock expect] notificationWithName:ORKTableControllerDidLoadErrorNotification object:tableController userInfo:OCMOCK_ANY];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    tableController.delegate = delegate;

    [tableController loadTableFromResourcePath:@"/fail" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

- (void)testPostANotificationWhenAnEmptyCollectionIsLoaded
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    objectManager.client.cachePolicy = ORKRequestCachePolicyNone;
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[ORKTestUser class] toTableCellsWithMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *mapping) {
        mapping.cellClass = [ORKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:ORKTableControllerDidLoadEmptyNotification object:tableController];
    [[observerMock expect] notificationWithName:ORKTableControllerDidLoadEmptyNotification object:tableController];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    tableController.delegate = delegate;
    [tableController loadTableFromResourcePath:@"/empty/array" usingBlock:^(ORKObjectLoader *objectLoader) {
        objectLoader.objectMapping = [ORKObjectMapping mappingForClass:[ORKTestUser class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

#pragma mark - State Transitions

- (void)testInitializesToNotYetLoadedState
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool(tableController.state == ORKTableControllerStateNotYetLoaded, is(equalToBool(YES)));
}

- (void)testInitialLoadSetsStateToLoading
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
}

- (void)testSuccessfulLoadSetsStateToNormal
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    [tableController objectLoader:mockLoader didLoadObjects:[NSArray arrayWithObject:@"test"]];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInteger(tableController.state, is(equalToInteger(ORKTableControllerStateNormal)));
}

- (void)testErrorLoadsSetsStateToError
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    NSError *error = [NSError errorWithDomain:@"Test" code:1234 userInfo:nil];
    [tableController objectLoader:mockLoader didFailWithError:error];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatBool([tableController isError], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

- (void)testSecondaryLoadAfterErrorSetsStateToErrorAndLoading
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    NSError *error = [NSError errorWithDomain:@"Test" code:1234 userInfo:nil];
    [tableController objectLoader:mockLoader didFailWithError:error];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatBool([tableController isError], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
    assertThatBool([tableController isError], is(equalToBool(YES)));
}

- (void)testEmptyLoadSetsStateToEmpty
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController loadEmpty];
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

- (void)testSecondaryLoadAfterEmptySetsStateToEmptyAndLoading
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController loadEmpty];
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

- (void)testTransitionToOfflineAfterLoadSetsStateToOfflineAndLoaded
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL isOnline = YES;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(isOnline)] isOnline];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = mockManager;
    [tableController loadEmpty];
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isOffline], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[ORKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    isOnline = NO;
    id mockManager2 = [OCMockObject partialMockForObject:objectManager];
    [[[mockManager2 stub] andReturnValue:OCMOCK_VALUE(isOnline)] isOnline];
    tableController.objectManager = mockManager2;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOfflineNotification object:tableController.objectManager];
    assertThatBool(tableController.isOffline, is(equalToBool(YES)));
}

#pragma mark - State Views

- (void)testPermitYouToOverlayAnImageOnTheTable
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    UIImage *image = [ORKTestFixture imageWithContentsOfFixture:@"blake.png"];
    [tableController showImageInOverlay:image];
    UIImageView *imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)testPermitYouToRemoveAnImageOverlayFromTheTable
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    UIImage *image = [ORKTestFixture imageWithContentsOfFixture:@"blake.png"];
    [tableController showImageInOverlay:image];
    assertThat([tableController.tableView.superview subviews], isNot(empty()));
    [tableController removeImageOverlay];
    assertThat([tableController.tableView.superview subviews], is(nilValue()));
}

- (void)testTriggerDisplayOfTheErrorViewOnTransitionToErrorState
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    UIImage *image = [ORKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForError = image;
    id mockError = [OCMockObject mockForClass:[NSError class]];
    [tableController objectLoader:nil didFailWithError:mockError];
    assertThatBool([tableController isError], is(equalToBool(YES)));
    UIImageView *imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)testTriggerHidingOfTheErrorViewOnTransitionOutOfTheErrorState
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    UIImage *image = [ORKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForError = image;
    id mockError = [OCMockObject niceMockForClass:[NSError class]];
    [tableController objectLoader:nil didFailWithError:mockError];
    assertThatBool([tableController isError], is(equalToBool(YES)));
    UIImageView *imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
    [tableController loadTableItems:[NSArray arrayWithObject:[ORKTableItem tableItem]]];
    assertThat(tableController.error, is(nilValue()));
    assertThat(tableController.stateOverlayImageView.image, is(nilValue()));
}

- (void)testTriggerDisplayOfTheEmptyViewOnTransitionToEmptyState
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    UIImage *image = [ORKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForEmpty = image;
    [tableController loadEmpty];
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UIImageView *imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)testTriggerHidingOfTheEmptyViewOnTransitionOutOfTheEmptyState
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    UIImage *image = [ORKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForEmpty = image;
    [tableController loadEmpty];
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UIImageView *imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
    [tableController loadTableItems:[NSArray arrayWithObject:[ORKTableItem tableItem]]];
    assertThat(tableController.stateOverlayImageView.image, is(nilValue()));
}

- (void)testTriggerDisplayOfTheLoadingViewOnTransitionToTheLoadingState
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    tableController.loadingView = spinner;
    [tableController setValue:[NSNumber numberWithBool:YES] forKey:@"loading"];
    UIView *view = [tableController.tableOverlayView.subviews lastObject];
    assertThatBool(view == spinner, is(equalToBool(YES)));
}

- (void)testTriggerHidingOfTheLoadingViewOnTransitionOutOfTheLoadingState
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    tableController.loadingView = spinner;
    [tableController setValue:[NSNumber numberWithBool:YES] forKey:@"loading"];
    UIView *loadingView = [tableController.tableOverlayView.subviews lastObject];
    assertThatBool(loadingView == spinner, is(equalToBool(YES)));
    [tableController setValue:[NSNumber numberWithBool:NO] forKey:@"loading"];
    loadingView = [tableController.tableOverlayView.subviews lastObject];
    assertThat(loadingView, is(nilValue()));
}

#pragma mark - Header, Footer, and Empty Rows

- (void)testShowHeaderRows
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    NSArray *tableItems = [ORKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableController loadTableItems:tableItems];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(4)));
    UITableViewCell *cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITableViewCell *cellFour = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"One")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellFour.textLabel.text, is(equalTo(@"Three")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellFour forRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
    assertThatBool(cellFour.hidden, is(equalToBool(NO)));
}

- (void)testShowFooterRows
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    NSArray *tableItems = [ORKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableController loadTableItems:tableItems];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(4)));
    UITableViewCell *cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITableViewCell *cellFour = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"One")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Three")));
    assertThat(cellFour.textLabel.text, is(equalTo(@"Footer")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellFour forRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
    assertThatBool(cellFour.hidden, is(equalToBool(NO)));
}

- (void)testHideHeaderRowsWhenEmptyWhenPropertyIsNotSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController addHeaderRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(1)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UITableViewCell *cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Header")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(YES)));
}

- (void)testHideFooterRowsWhenEmptyWhenPropertyIsNotSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController addFooterRowForItem:[ORKTableItem tableItemUsingBlock:^(ORKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(1)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UITableViewCell *cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Footer")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(YES)));
}

- (void)testRemoveHeaderAndFooterCountsWhenDeterminingIsEmpty
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
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
    tableController.showsFooterRowsWhenEmpty = NO;
    tableController.showsHeaderRowsWhenEmpty = NO;
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

- (void)testNotShowTheEmptyItemWhenTheTableIsNotEmpty
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
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
    NSArray *tableItems = [ORKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableController loadTableItems:tableItems];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(6)));
    UITableViewCell *cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITableViewCell *cellFour = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    UITableViewCell *cellFive = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    UITableViewCell *cellSix = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Empty")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"One")));
    assertThat(cellFour.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellFive.textLabel.text, is(equalTo(@"Three")));
    assertThat(cellSix.textLabel.text, is(equalTo(@"Footer")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellFour forRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellFive forRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellSix forRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(YES)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
    assertThatBool(cellFour.hidden, is(equalToBool(NO)));
    assertThatBool(cellFive.hidden, is(equalToBool(NO)));
    assertThatBool(cellSix.hidden, is(equalToBool(NO)));
}

- (void)testShowTheEmptyItemWhenTheTableIsEmpty
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
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
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UITableViewCell *cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Empty")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Footer")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(YES)));
    assertThatBool(cellThree.hidden, is(equalToBool(YES)));
}

- (void)testShowTheEmptyItemPlusHeadersAndFootersWhenTheTableIsEmpty
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
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
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UITableViewCell *cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Empty")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Footer")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
}

#pragma mark - UITableViewDelegate Tests

- (void)testInvokeTheOnSelectCellForObjectAtIndexPathBlockHandler
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    __block BOOL dispatched = NO;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.onSelectCellForObjectAtIndexPath = ^(UITableViewCell *cell, id object, NSIndexPath *indexPath) {
            dispatched = YES;
        };
    }]];
    [tableController tableView:tableController.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
     assertThatBool(dispatched, is(equalToBool(YES)));
}

- (void)testInvokeTheOnCellWillAppearForObjectAtIndexPathBlockHandler
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    __block BOOL dispatched = NO;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.onCellWillAppearForObjectAtIndexPath = ^(UITableViewCell *cell, id object, NSIndexPath *indexPath) {
            dispatched = YES;
        };
    }]];
    id mockCell = [OCMockObject niceMockForClass:[UITableViewCell class]];
    [tableController tableView:tableController.tableView willDisplayCell:mockCell forRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:0]];
    assertThatBool(dispatched, is(equalToBool(YES)));
}

- (void)testOptionallyHideHeaderRowsWhenTheyAppearAndTheTableIsEmpty
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.showsHeaderRowsWhenEmpty = NO;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    [tableController addHeaderRowForItem:tableItem];
    [tableController loadEmpty];
    id mockCell = [OCMockObject niceMockForClass:[UITableViewCell class]];
    [[mockCell expect] setHidden:YES];
    [tableController tableView:tableController.tableView willDisplayCell:mockCell forRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:0]];
    [mockCell verify];
}

- (void)testOptionallyHideFooterRowsWhenTheyAppearAndTheTableIsEmpty
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.showsFooterRowsWhenEmpty = NO;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    [tableController addFooterRowForItem:tableItem];
    [tableController loadEmpty];
    id mockCell = [OCMockObject niceMockForClass:[UITableViewCell class]];
    [[mockCell expect] setHidden:YES];
    [tableController tableView:tableController.tableView willDisplayCell:mockCell forRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:0]];
    [mockCell verify];
}

- (void)testInvokeABlockCallbackWhenTheCellAccessoryButtonIsTapped
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    __block BOOL dispatched = NO;
    ORKTableViewCellMapping *mapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.onTapAccessoryButtonForObjectAtIndexPath = ^(UITableViewCell *cell, id object, NSIndexPath *indexPath) {
            dispatched = YES;
        };
    }];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:mapping];
    [tableController tableView:tableController.tableView accessoryButtonTappedForRowWithIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(dispatched, is(equalToBool(YES)));
}

- (void)testInvokeABlockCallbackWhenTheDeleteConfirmationButtonTitleIsDetermined
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    NSString *deleteTitle = @"Delete Me";
    ORKTableViewCellMapping *mapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.titleForDeleteButtonForObjectAtIndexPath = ^ NSString*(UITableViewCell *cell, id object, NSIndexPath *indexPath) {
            return deleteTitle;
        };
    }];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:mapping];
    NSString *delegateTitle = [tableController tableView:tableController.tableView
      titleForDeleteConfirmationButtonForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(delegateTitle, is(equalTo(deleteTitle)));
}

- (void)testInvokeABlockCallbackWhenCellEditingStyleIsDetermined
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.canEditRows = YES;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    ORKTableViewCellMapping *mapping = [ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.editingStyleForObjectAtIndexPath = ^ UITableViewCellEditingStyle(UITableViewCell *cell, id object, NSIndexPath *indexPath) {
            return UITableViewCellEditingStyleInsert;
        };
    }];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:mapping];
    UITableViewCellEditingStyle delegateStyle = [tableController tableView:tableController.tableView
                                            editingStyleForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatInt(delegateStyle, is(equalToInt(UITableViewCellEditingStyleInsert)));
}

- (void)testInvokeABlockCallbackWhenACellIsMoved
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.canMoveRows = YES;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    NSIndexPath *moveToIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.targetIndexPathForMove = ^ NSIndexPath*(UITableViewCell *cell, id object, NSIndexPath *sourceIndexPath, NSIndexPath *destinationIndexPath) {
            return moveToIndexPath;
        };
    }]];
    NSIndexPath *delegateIndexPath = [tableController tableView:tableController.tableView
                      targetIndexPathForMoveFromRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] toProposedIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThat(delegateIndexPath, is(equalTo(moveToIndexPath)));
}

#pragma mark Variable Height Rows

- (void)testReturnTheRowHeightConfiguredOnTheTableViewWhenVariableHeightRowsIsDisabled
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.variableHeightRows = NO;
    tableController.tableView.rowHeight = 55;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.rowHeight = 200;
    }]];
    CGFloat height = [tableController tableView:tableController.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatFloat(height, is(equalToFloat(55)));
}

- (void)testReturnTheHeightFromTheTableCellMappingWhenVariableHeightRowsAreEnabled
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.variableHeightRows = YES;
    tableController.tableView.rowHeight = 55;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.rowHeight = 200;
    }]];
    CGFloat height = [tableController tableView:tableController.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatFloat(height, is(equalToFloat(200)));
}

- (void)testInvokeAnBlockCallbackToDetermineTheCellHeightWhenVariableHeightRowsAreEnabled
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.variableHeightRows = YES;
    tableController.tableView.rowHeight = 55;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:[ORKTableViewCellMapping cellMappingUsingBlock:^(ORKTableViewCellMapping *cellMapping) {
        cellMapping.rowHeight = 200;
        cellMapping.heightOfCellForObjectAtIndexPath = ^ CGFloat(id object, NSIndexPath *indexPath) { return 150; };
    }]];
    CGFloat height = [tableController tableView:tableController.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatFloat(height, is(equalToFloat(150)));
}

#pragma mark - Editing

- (void)testAllowEditingWhenTheCanEditRowsPropertyIsSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.canEditRows = YES;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
}

- (void)testCommitADeletionWhenTheCanEditRowsPropertyIsSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.canEditRows = YES;
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
           commitEditingStyle:UITableViewCellEditingStyleDelete
            forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(1)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
}

- (void)testNotCommitADeletionWhenTheCanEditRowsPropertyIsNotSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(NO)));
    [tableController tableView:tableController.tableView
           commitEditingStyle:UITableViewCellEditingStyleDelete
            forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)testDoNothingToCommitAnInsertionWhenTheCanEditRowsPropertyIsSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.canEditRows = YES;
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
           commitEditingStyle:UITableViewCellEditingStyleInsert
            forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)testAllowMovingWhenTheCanMoveRowsPropertyIsSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.canMoveRows = YES;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    BOOL delegateCanMove = [tableController tableView:tableController.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
}

- (void)testMoveARowWithinASectionWhenTheCanMoveRowsPropertyIsSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.canMoveRows = YES;
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanMove = [tableController tableView:tableController.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
           moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                  toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)testMoveARowAcrossSectionsWhenTheCanMoveRowsPropertyIsSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.canMoveRows = YES;
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThatInt([tableController sectionCount], is(equalToInt(1)));
    BOOL delegateCanMove = [tableController tableView:tableController.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
           moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                  toIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThatInt([tableController sectionCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]],
               is(equalTo(@"First Object")));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)testNotMoveARowWhenTheCanMoveRowsPropertyIsNotSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanMove = [tableController tableView:tableController.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(NO)));
    [tableController tableView:tableController.tableView
           moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                  toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"Second Object")));
}

#pragma mark - Reachability Integration

- (void)testTransitionToTheOnlineStateWhenAReachabilityNoticeIsReceived
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = YES;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOnlineNotification object:objectManager];
    assertThatBool(tableController.isOnline, is(equalToBool(YES)));
}

- (void)testTransitionToTheOfflineStateWhenAReachabilityNoticeIsReceived
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = NO;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOfflineNotification object:objectManager];
    assertThatBool(tableController.isOnline, is(equalToBool(NO)));
}

- (void)testNotifyTheDelegateOnTransitionToOffline
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    ORKObjectManagerNetworkStatus networkStatus = ORKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(ORKTableControllerDelegate)];
    [[mockDelegate expect] tableControllerDidBecomeOffline:tableController];
    tableController.delegate = mockDelegate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOfflineNotification object:objectManager];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testPostANotificationOnTransitionToOffline
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    ORKObjectManagerNetworkStatus networkStatus = ORKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:ORKTableControllerDidBecomeOffline object:tableController];
    [[observerMock expect] notificationWithName:ORKTableControllerDidBecomeOffline object:tableController];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOfflineNotification object:objectManager];
    [observerMock verify];
}

- (void)testNotifyTheDelegateOnTransitionToOnline
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = NO;
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = YES;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    [ORKObjectManager setSharedManager:nil]; // Don't want the controller to initialize with the sharedManager...
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(ORKTableControllerDelegate)];
    [[mockDelegate expect] tableControllerDidBecomeOnline:tableController];
    tableController.delegate = mockDelegate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOnlineNotification object:objectManager];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testPostANotificationOnTransitionToOnline
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = NO;
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = YES;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    [ORKObjectManager setSharedManager:nil]; // Don't want the controller to initialize with the sharedManager...
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:ORKTableControllerDidBecomeOnline object:tableController];
    [[observerMock expect] notificationWithName:ORKTableControllerDidBecomeOnline object:tableController];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOnlineNotification object:objectManager];
    [observerMock verify];
}

- (void)testShowTheOfflineImageOnTransitionToOffline
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    ORKObjectManagerNetworkStatus networkStatus = ORKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    UIImage *image = [ORKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForOffline = image;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOfflineNotification object:objectManager];
    assertThatBool(tableController.isOnline, is(equalToBool(NO)));
    UIImageView *imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)testRemoveTheOfflineImageOnTransitionToOnlineFromOffline
{
    ORKObjectManager *objectManager = [ORKTestFactory objectManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    ORKObjectManagerNetworkStatus networkStatus = ORKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    [tableController loadEmpty]; // Load to change the isLoaded state
    UIImage *image = [ORKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForOffline = image;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOfflineNotification object:objectManager];
    assertThatBool(tableController.isOnline, is(equalToBool(NO)));
    UIImageView *imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));

    online = YES;
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKObjectManagerDidBecomeOnlineNotification object:objectManager];
    assertThatBool(tableController.isOnline, is(equalToBool(YES)));
    imageView = tableController.stateOverlayImageView;
    assertThat(imageView.image, is(nilValue()));
}

#pragma mark - Swipe Menus

- (void)testAllowSwipeMenusWhenTheSwipeViewsEnabledPropertyIsSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.cellSwipeViewsEnabled = YES;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    assertThatBool(tableController.canEditRows, is(equalToBool(NO)));
    assertThatBool(tableController.cellSwipeViewsEnabled, is(equalToBool(YES)));
}

- (void)testNotAllowEditingWhenTheSwipeViewsEnabledPropertyIsSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.cellSwipeViewsEnabled = YES;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(NO)));
}

- (void)testRaiseAnExceptionWhenEnablingSwipeViewsWhenTheCanEditRowsPropertyIsSet
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.canEditRows = YES;

    NSException *exception = nil;
    @try {
        tableController.cellSwipeViewsEnabled = YES;
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, isNot(nilValue()));
    }
}

- (void)testCallTheDelegateBeforeShowingTheSwipeView
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.cellSwipeViewsEnabled = YES;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  willAddSwipeView:OCMOCK_ANY
                                                            toCell:OCMOCK_ANY
                                                         forObject:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableController addSwipeViewTo:[ORKTestUserTableViewCell new]
                        withObject:@"object"
                         direction:UISwipeGestureRecognizerDirectionRight];
    STAssertNoThrow([mockDelegate verify], nil);
}

- (void)testCallTheDelegateBeforeHidingTheSwipeView
{
    ORKTableControllerTestTableViewController *viewController = [ORKTableControllerTestTableViewController new];
    ORKTableController *tableController = [ORKTableController tableControllerForTableViewController:viewController];
    tableController.cellSwipeViewsEnabled = YES;
    ORKTableItem *tableItem = [ORKTableItem tableItem];
    ORKTableControllerTestDelegate *delegate = [ORKTableControllerTestDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  willAddSwipeView:OCMOCK_ANY
                                                            toCell:OCMOCK_ANY
                                                         forObject:OCMOCK_ANY];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                               willRemoveSwipeView:OCMOCK_ANY
                                                          fromCell:OCMOCK_ANY
                                                         forObject:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableController addSwipeViewTo:[ORKTestUserTableViewCell new]
                        withObject:@"object"
                         direction:UISwipeGestureRecognizerDirectionRight];
    [tableController animationDidStopAddingSwipeView:nil
                                           finished:nil
                                            context:nil];
    [tableController removeSwipeView:YES];
    STAssertNoThrow([mockDelegate verify], nil);
}

@end
