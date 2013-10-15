//
//  ORKDynamicObjectMappingMatcher.h
//  RestKit
//
//  Created by Jeff Arena on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORKObjectMapping.h"


@interface ORKDynamicObjectMappingMatcher : NSObject {
    NSString *_keyPath;
    id _value;
    BOOL (^_isMatchForDataBlock)(id data);
}

@property (nonatomic, readonly) ORKObjectMapping *objectMapping;
@property (nonatomic, readonly) NSString *primaryKeyAttribute;

- (id)initWithKey:(NSString *)key value:(id)value objectMapping:(ORKObjectMapping *)objectMapping;
- (id)initWithKey:(NSString *)key value:(id)value primaryKeyAttribute:(NSString *)primaryKeyAttribute;
- (id)initWithPrimaryKeyAttribute:(NSString *)primaryKeyAttribute evaluationBlock:(BOOL (^)(id data))block;
- (BOOL)isMatchForData:(id)data;
- (NSString *)matchDescription;

@end
