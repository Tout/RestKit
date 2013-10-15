//
//  ORKConfigurationDelegate.h
//  RestKit
//
//  Created by Blake Watters on 1/7/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

@class ORKRequest, ORKObjectLoader;

/**
 The ORKConfigurationDelegate formal protocol defines
 methods enabling the centralization of ORKRequest and
 ORKObjectLoader configuration. An object conforming to
 the protocol can be used to set headers, authentication
 credentials, etc.

 ORKClient and ORKObjectManager conform to ORKConfigurationDelegate
 to configure request and object loader instances they build.
 */
@protocol ORKConfigurationDelegate <NSObject>

@optional

/**
 Configure a request before it is utilized

 @param request A request object being configured for dispatch
 */
- (void)configureRequest:(ORKRequest *)request;

/**
 Configure an object loader before it is utilized

 @param request An object loader being configured for dispatch
 */
- (void)configureObjectLoader:(ORKObjectLoader *)objectLoader;

@end
