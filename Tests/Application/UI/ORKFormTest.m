//
//  ORKFormTest.m
//  RestKit
//
//  Created by Blake Watters on 8/29/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestEnvironment.h"
#import "ORKForm.h"
#import "ORKMappableObject.h"
#import "ORKTableController.h"

@interface UISwitch (ControlValue)
@property (nonatomic, assign) NSNumber *controlValue;
@end

@implementation UISwitch (ControlValue)

- (NSNumber *)controlValue
{
    return [NSNumber numberWithBool:self.isOn];
}

- (void)setControlValue:(NSNumber *)controlValue
{
    self.on = [controlValue boolValue];
}

@end

@interface ORKTestTextField : UIControl
@property (nonatomic, retain) NSString *text;
@end

@implementation ORKTestTextField

@synthesize text;

@end

///////////////////////////////////////////////////////////////

@interface ORKFormSpecTableViewCell : UITableViewCell {
}

@property (nonatomic, retain) NSString *someTextProperty;

@end

@implementation ORKFormSpecTableViewCell

@synthesize someTextProperty;

@end

///////////////////////////////////////////////////////////////

@interface ORKFormTest : ORKTestCase

@end

@implementation ORKFormTest

- (void)testCommitValuesBackToTheFormObjectWithBuiltInTypes
{
    ORKMappableObject *mappableObject = [[ORKMappableObject new] autorelease];
    ORKForm *form = [ORKForm formForObject:mappableObject usingBlock:^(ORKForm *form) {
        [form addRowForAttribute:@"stringTest" withControlType:ORKFormControlTypeTextField usingBlock:^(ORKControlTableItem *tableItem) {
            tableItem.textField.text = @"testing 123";
        }];
        [form addRowForAttribute:@"numberTest" withControlType:ORKFormControlTypeSwitch usingBlock:^(ORKControlTableItem *tableItem) {
            tableItem.switchControl.on = YES;
        }];
    }];
    [form commitValuesToObject];
    assertThat(mappableObject.stringTest, is(equalTo(@"testing 123")));
    assertThatBool([mappableObject.numberTest boolValue], is(equalToBool(YES)));
}

- (void)testCommitValuesBackToTheFormObjectFromUserConfiguredControls
{
    ORKTestTextField *textField = [[ORKTestTextField new] autorelease];
    textField.text = @"testing 123";
    UISwitch *switchControl = [[UISwitch new] autorelease];
    switchControl.on = YES;
    ORKMappableObject *mappableObject = [[ORKMappableObject new] autorelease];
    ORKForm *form = [ORKForm formForObject:mappableObject usingBlock:^(ORKForm *form) {
        [form addRowMappingAttribute:@"stringTest" toKeyPath:@"text" onControl:textField];
        [form addRowMappingAttribute:@"numberTest" toKeyPath:@"controlValue" onControl:switchControl];
    }];
    [form commitValuesToObject];
    assertThat(mappableObject.stringTest, is(equalTo(@"testing 123")));
    assertThatBool([mappableObject.numberTest boolValue], is(equalToBool(YES)));
}

- (void)testCommitValuesBackToTheFormObjectFromCellKeyPaths
{
    ORKMappableObject *mappableObject = [[ORKMappableObject new] autorelease];
    ORKForm *form = [ORKForm formForObject:mappableObject usingBlock:^(ORKForm *form) {
        [form addRowMappingAttribute:@"stringTest" toKeyPath:@"someTextProperty" onCellWithClass:[ORKFormSpecTableViewCell class]];
    }];

    ORKTableItem *tableItem = [form.tableItems lastObject];
    ORKFormSpecTableViewCell *cell = [[ORKFormSpecTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.someTextProperty = @"testing 123";
    id mockTableController = [OCMockObject niceMockForClass:[ORKTableController class]];
    [[[mockTableController expect] andReturn:cell] cellForObject:tableItem];
    [form didLoadInTableController:mockTableController];

    // Create a cell
    // Create a fake table view model
    // stub out returning the cell from the table view model

    [form commitValuesToObject];
    assertThat(mappableObject.stringTest, is(equalTo(@"testing 123")));
}

- (void)testMakeTheTableItemPassKVCInvocationsThroughToTheUnderlyingMappedControlKeyPath
{
    // TODO: Implement me
    // add a control
    // invoke valueForKey: with the control value keyPath on the table item...
}

- (void)testInvokeValueForKeyPathOnTheControlIfControlValueReturnsNil
{
    // TODO: Implement me
    // add a custom control to the form
    // the control value should return nil so that valueForKeyPath is invoked directly
}

@end
