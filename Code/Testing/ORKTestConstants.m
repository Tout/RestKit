//
//  ORKTestConstants.m
//  RestKit
//
//  Created by Blake Watters on 5/4/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

/*
 This file defines constants used by the Testing module. It is necessary due to strange
 linking errors when building for the Device. When these constants were defined within
 ORKTestFactory.m, they would resolve on the Simulator but produce linker when building
 for Device. [sbw - 05/04/2012]
 */
NSString * const ORKTestFactoryDefaultNamesClient = @"client";
NSString * const ORKTestFactoryDefaultNamesObjectManager = @"objectManager";
NSString * const ORKTestFactoryDefaultNamesMappingProvider = @"mappingProvider";
NSString * const ORKTestFactoryDefaultNamesManagedObjectStore = @"managedObjectStore";
NSString * const ORKTestFactoryDefaultStoreFilename = @"ORKTests.sqlite";
