//
//  ORKMappingTestExpectation.m
//  RestKit
//
//  Created by Blake Watters on 2/17/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKMappingTestExpectation.h"

@interface ORKMappingTestExpectation ()
@property (nonatomic, copy, readwrite) NSString *sourceKeyPath;
@property (nonatomic, copy, readwrite) NSString *destinationKeyPath;
@property (nonatomic, strong, readwrite) id value;
@property (nonatomic, copy, readwrite) BOOL (^evaluationBlock)(ORKObjectAttributeMapping *mapping, id value);
@end


@implementation ORKMappingTestExpectation

@synthesize sourceKeyPath;
@synthesize destinationKeyPath;
@synthesize value;
@synthesize evaluationBlock;

+ (ORKMappingTestExpectation *)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath
{
    ORKMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;

    return expectation;
}

+ (ORKMappingTestExpectation *)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath value:(id)value
{
    ORKMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;
    expectation.value = value;

    return expectation;
}

+ (ORKMappingTestExpectation *)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath evaluationBlock:(BOOL (^)(ORKObjectAttributeMapping *mapping, id value))testBlock
{
    ORKMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;
    expectation.evaluationBlock = testBlock;

    return expectation;
}

- (NSString *)mappingDescription
{
    return [NSString stringWithFormat:@"expected sourceKeyPath '%@' to map to destinationKeyPath '%@'",
            self.sourceKeyPath, self.destinationKeyPath];
}

- (NSString *)description
{
    if (self.value) {
        return [NSString stringWithFormat:@"expected sourceKeyPath '%@' to map to destinationKeyPath '%@' with %@ value '%@'",
                self.sourceKeyPath, self.destinationKeyPath, [self.value class], self.value];
    } else if (self.evaluationBlock) {
        return [NSString stringWithFormat:@"expected sourceKeyPath '%@' to map to destinationKeyPath '%@' satisfying evaluation block",
                self.sourceKeyPath, self.destinationKeyPath];
    }

    return [self mappingDescription];
}

@end
