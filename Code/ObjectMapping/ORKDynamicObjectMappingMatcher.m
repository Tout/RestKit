//
//  ORKDynamicObjectMappingMatcher.m
//  RestKit
//
//  Created by Jeff Arena on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKDynamicObjectMappingMatcher.h"


// Implemented in ORKObjectMappingOperation
BOOL ORKObjectIsValueEqualToValue(id sourceValue, id destinationValue);

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation ORKDynamicObjectMappingMatcher

@synthesize objectMapping = _objectMapping;
@synthesize primaryKeyAttribute = _primaryKeyAttribute;

- (id)initWithKey:(NSString *)key value:(id)value objectMapping:(ORKObjectMapping *)objectMapping
{
    self = [super init];
    if (self) {
        _keyPath = [key retain];
        _value = [value retain];
        _objectMapping = [objectMapping retain];
    }

    return self;
}

- (id)initWithKey:(NSString *)key value:(id)value primaryKeyAttribute:(NSString *)primaryKeyAttribute
{
    self = [super init];
    if (self) {
        _keyPath = [key retain];
        _value = [value retain];
        _primaryKeyAttribute = [primaryKeyAttribute retain];
    }

    return self;
}

- (id)initWithPrimaryKeyAttribute:(NSString *)primaryKeyAttribute evaluationBlock:(BOOL (^)(id data))block
{
    self = [super init];
    if (self) {
        _primaryKeyAttribute = [primaryKeyAttribute retain];
        _isMatchForDataBlock = Block_copy(block);
    }
    return self;
}

- (void)dealloc
{
    [_keyPath release];
    [_value release];
    [_objectMapping release];
    [_primaryKeyAttribute release];
    if (_isMatchForDataBlock) {
        Block_release(_isMatchForDataBlock);
    }
    [super dealloc];
}

- (BOOL)isMatchForData:(id)data
{
    if (_isMatchForDataBlock) {
        return _isMatchForDataBlock(data);
    }
    return ORKObjectIsValueEqualToValue([data valueForKeyPath:_keyPath], _value);
}

- (NSString *)matchDescription
{
    if (_isMatchForDataBlock) {
        return @"No description available. Using block to perform match.";
    }
    return [NSString stringWithFormat:@"%@ == %@", _keyPath, _value];
}

@end
