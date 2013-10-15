//
//  ORKMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 2/17/12.
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

#import "ORKMappingTest.h"

BOOL ORKObjectIsValueEqualToValue(id sourceValue, id destinationValue);

///-----------------------------------------------------------------------------
///-----------------------------------------------------------------------------

@interface ORKMappingTestEvent : NSObject

@property (nonatomic, strong, readonly) ORKObjectAttributeMapping *mapping;
@property (nonatomic, strong, readonly) id value;

@property (nonatomic, readonly) NSString *sourceKeyPath;
@property (nonatomic, readonly) NSString *destinationKeyPath;

+ (ORKMappingTestEvent *)eventWithMapping:(ORKObjectAttributeMapping *)mapping value:(id)value;

@end

@interface ORKMappingTestEvent ()
@property (nonatomic, strong, readwrite) id value;
@property (nonatomic, strong, readwrite) ORKObjectAttributeMapping *mapping;
@end

@implementation ORKMappingTestEvent

@synthesize value;
@synthesize mapping;

+ (ORKMappingTestEvent *)eventWithMapping:(ORKObjectAttributeMapping *)mapping value:(id)value
{
    ORKMappingTestEvent *event = [ORKMappingTestEvent new];
    event.value = value;
    event.mapping = mapping;

    return event;
}

- (NSString *)sourceKeyPath
{
    return self.mapping.sourceKeyPath;
}

- (NSString *)destinationKeyPath
{
    return self.mapping.destinationKeyPath;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: mapped sourceKeyPath '%@' => destinationKeyPath '%@' with value: %@", [self class], self.sourceKeyPath, self.destinationKeyPath, self.value];
}

@end

///-----------------------------------------------------------------------------
///-----------------------------------------------------------------------------

@interface ORKMappingTest () <ORKObjectMappingOperationDelegate>
@property (nonatomic, strong, readwrite) ORKObjectMapping *mapping;
@property (nonatomic, strong, readwrite) id sourceObject;
@property (nonatomic, strong, readwrite) id destinationObject;
@property (nonatomic, strong) NSMutableArray *expectations;
@property (nonatomic, strong) NSMutableArray *events;
@property (nonatomic, assign, getter = hasPerformedMapping) BOOL performedMapping;

// Method Definitions for old compilers
- (void)performMapping;
- (void)verifyExpectation:(ORKMappingTestExpectation *)expectation;

@end

@implementation ORKMappingTest

@synthesize sourceObject = _sourceObject;
@synthesize destinationObject = _destinationObject;
@synthesize mapping = _mapping;
@synthesize rootKeyPath = _rootKeyPath;
@synthesize expectations = _expectations;
@synthesize events = _events;
@synthesize verifiesOnExpect = _verifiesOnExpect;
@synthesize performedMapping = _performedMapping;

+ (ORKMappingTest *)testForMapping:(ORKObjectMapping *)mapping object:(id)sourceObject
{
    return [[self alloc] initWithMapping:mapping sourceObject:sourceObject destinationObject:nil];
}

+ (ORKMappingTest *)testForMapping:(ORKObjectMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject
{
    return [[self alloc] initWithMapping:mapping sourceObject:sourceObject destinationObject:destinationObject];
}

- (id)initWithMapping:(ORKObjectMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject
{
    NSAssert(sourceObject != nil, @"Cannot perform a mapping operation without a sourceObject object");
    NSAssert(mapping != nil, @"Cannot perform a mapping operation without a mapping");

    self = [super init];
    if (self) {
        _sourceObject = sourceObject;
        _destinationObject = destinationObject;
        _mapping = mapping;
        _expectations = [NSMutableArray new];
        _events = [NSMutableArray new];
        _verifiesOnExpect = NO;
        _performedMapping = NO;
    }

    return self;
}

- (void)addExpectation:(ORKMappingTestExpectation *)expectation
{
    [self.expectations addObject:expectation];

    if (self.verifiesOnExpect) {
        [self performMapping];
        [self verifyExpectation:expectation];
    }
}

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath
{
    [self addExpectation:[ORKMappingTestExpectation expectationWithSourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath]];
}

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withValue:(id)value
{
    [self addExpectation:[ORKMappingTestExpectation expectationWithSourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath value:value]];
}

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath passingTest:(BOOL (^)(ORKObjectAttributeMapping *mapping, id value))evaluationBlock
{
    [self addExpectation:[ORKMappingTestExpectation expectationWithSourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath evaluationBlock:evaluationBlock]];
}

- (ORKMappingTestEvent *)eventMatchingKeyPathsForExpectation:(ORKMappingTestExpectation *)expectation
{
    for (ORKMappingTestEvent *event in self.events) {
        if ([event.sourceKeyPath isEqualToString:expectation.sourceKeyPath] && [event.destinationKeyPath isEqualToString:expectation.destinationKeyPath]) {
            return event;
        }
    }

    return nil;
}

- (BOOL)event:(ORKMappingTestEvent *)event satisfiesExpectation:(ORKMappingTestExpectation *)expectation
{
    if (expectation.evaluationBlock) {
        // Let the expectation block evaluate the match
        return expectation.evaluationBlock(event.mapping, event.value);
    } else if (expectation.value) {
        // Use RestKit comparison magic to match values
        return ORKObjectIsValueEqualToValue(event.value, expectation.value);
    }

    // We only wanted to know that a mapping occured between the keyPaths
    return YES;
}

- (void)performMapping
{
    NSAssert(self.mapping.objectClass, @"Cannot test a mapping that does not have a destination objectClass");

    // Ensure repeated invocations of verify only result in a single mapping operation
    if (! self.hasPerformedMapping) {
        id sourceObject = self.rootKeyPath ? [self.sourceObject valueForKeyPath:self.rootKeyPath] : self.sourceObject;
        if (nil == self.destinationObject) {
            self.destinationObject = [self.mapping mappableObjectForData:self.sourceObject];
        }
        ORKObjectMappingOperation *mappingOperation = [ORKObjectMappingOperation mappingOperationFromObject:sourceObject toObject:self.destinationObject withMapping:self.mapping];
        NSError *error = nil;
        mappingOperation.delegate = self;
        BOOL success = [mappingOperation performMapping:&error];
        if (! success) {
            [NSException raise:NSInternalInconsistencyException format:@"%@: failure when mapping from %@ to %@ with mapping %@",
             [self description], self.sourceObject, self.destinationObject, self.mapping];
        }

        self.performedMapping = YES;
    }
}

- (void)verifyExpectation:(ORKMappingTestExpectation *)expectation
{
    ORKMappingTestEvent *event = [self eventMatchingKeyPathsForExpectation:expectation];
    if (event) {
        // Found a matching event, check if it satisfies the expectation
        if (! [self event:event satisfiesExpectation:expectation]) {
            [NSException raise:NSInternalInconsistencyException format:@"%@: expectation not satisfied: %@, but instead got %@ '%@'",
             [self description], expectation, [event.value class], event.value];
        }
    } else {
        // No match
        [NSException raise:NSInternalInconsistencyException format:@"%@: expectation not satisfied: %@, but did not.",
         [self description], [expectation mappingDescription]];
    }
}

- (void)verify
{
    [self performMapping];

    for (ORKMappingTestExpectation *expectation in self.expectations) {
        [self verifyExpectation:expectation];
    }
}

#pragma mark - ORKObjecMappingOperationDelegate

- (void)addEvent:(ORKMappingTestEvent *)event
{
    [self.events addObject:event];
}

- (void)objectMappingOperation:(ORKObjectMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(ORKObjectAttributeMapping *)mapping
{
    [self addEvent:[ORKMappingTestEvent eventWithMapping:mapping value:value]];
}

- (void)objectMappingOperation:(ORKObjectMappingOperation *)operation didNotSetUnchangedValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(ORKObjectAttributeMapping *)mapping
{
    [self addEvent:[ORKMappingTestEvent eventWithMapping:mapping value:value]];
}

@end
