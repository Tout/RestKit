//
//  ORKObjectMapper.h
//  RestKit
//
//  Created by Blake Watters on 5/6/11.
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

#import <Foundation/Foundation.h>
#import "ORKObjectMapping.h"
#import "ORKObjectMappingOperation.h"
#import "ORKObjectMappingResult.h"
#import "ORKObjectMappingProvider.h"
#import "ORKMappingOperationQueue.h"
#import "Support.h"

@class ORKObjectMapper;

@protocol ORKObjectMapperDelegate <NSObject>

@optional

- (void)objectMapperWillBeginMapping:(ORKObjectMapper *)objectMapper;
- (void)objectMapperDidFinishMapping:(ORKObjectMapper *)objectMapper;
- (void)objectMapper:(ORKObjectMapper *)objectMapper didAddError:(NSError *)error;
- (void)objectMapper:(ORKObjectMapper *)objectMapper didFindMappableObject:(id)object atKeyPath:(NSString *)keyPath withMapping:(ORKObjectMappingDefinition *)mapping;
- (void)objectMapper:(ORKObjectMapper *)objectMapper didNotFindMappableObjectAtKeyPath:(NSString *)keyPath;

- (void)objectMapper:(ORKObjectMapper *)objectMapper willMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString *)keyPath usingMapping:(ORKObjectMappingDefinition *)objectMapping;
- (void)objectMapper:(ORKObjectMapper *)objectMapper didMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString *)keyPath usingMapping:(ORKObjectMappingDefinition *)objectMapping;
- (void)objectMapper:(ORKObjectMapper *)objectMapper didFailMappingFromObject:(id)sourceObject toObject:(id)destinationObject withError:(NSError *)error atKeyPath:(NSString *)keyPath usingMapping:(ORKObjectMappingDefinition *)objectMapping;
@end

/**

 */
@interface ORKObjectMapper : NSObject {
  @protected
    ORKMappingOperationQueue *operationQueue;
    NSMutableArray *errors;
}

@property (nonatomic, readonly) id sourceObject;
@property (nonatomic, assign) id targetObject;
@property (nonatomic, readonly) ORKObjectMappingProvider *mappingProvider;
@property (nonatomic, assign) ORKObjectMappingProviderContext context;
@property (nonatomic, assign) id<ORKObjectMapperDelegate> delegate;
@property (nonatomic, readonly) NSArray *errors;

+ (id)mapperWithObject:(id)object mappingProvider:(ORKObjectMappingProvider *)mappingProvider;
- (id)initWithObject:(id)object mappingProvider:(ORKObjectMappingProvider *)mappingProvider;

// Primary entry point for the mapper. Examines the type of object and processes it appropriately...
- (ORKObjectMappingResult *)performMapping;
- (NSUInteger)errorCount;

@end
