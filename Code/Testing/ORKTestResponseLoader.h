//
//  ORKTestResponseLoader.h
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
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
#import "ORKObjectLoader.h"

/**
 An ORKTestResponseLoader object provides testing support for asynchronously loading an ORKRequest or
 ORKObjectLoader object while blocking the execution of the current thread by spinning the run loop.
 This enables a straight-forward unit testing workflow for asynchronous network operations.

 ORKTestResponseLoader instances are designed to act as as the delegate for an ORKObjectLoader or ORKRequest
 object under test. Once assigned as the delegate to a request and the request has been sent,
 waitForResponse: is invoked to block execution until the response is loaded.
 */
@interface ORKTestResponseLoader : NSObject <ORKObjectLoaderDelegate, ORKOAuthClientDelegate>

/**
 The ORKResponse object loaded from the ORKRequest or ORKObjectLoader the receiver is acting as the delegate for.
 **/
@property (nonatomic, retain, readonly) ORKResponse *response;

/**
 The collection of objects loaded from the ORKObjectLoader the receiver is acting as the delegate for.
 */
@property (nonatomic, retain, readonly) NSArray *objects;

/**
 A Boolean value that indicates whether a response was loaded successfully.

 @return YES if a response was loaded successfully.
 */
@property (nonatomic, readonly, getter = wasSuccessful) BOOL successful;

/**
 A Boolean value that indicates whether the ORKRequest or ORKObjectLoader the receiver is acting as the delegate for was cancelled.

 @return YES if the request was cancelled
 */
@property (nonatomic, readonly, getter = wasCancelled) BOOL cancelled;

/**
 A Boolean value that indicates if an unexpected response was loaded.

 @return YES if the request loaded an unknown response.
 @see [ORKObjectLoaderDelegate objectLoaderDidLoadUnexpectedResponse:]
 */
@property (nonatomic, readonly, getter = loadedUnexpectedResponse) BOOL unexpectedResponse;

/**
 An NSError value that was loaded from the ORKRequest or ORKObjectLoader the receiver is acting as the delegate for.

 @see [ORKRequestDelegate request:didFailLoadWithError:]
 @see [ORKObjectLoaderDelegate objectLoader:didFailWithError:]
 */
@property (nonatomic, copy, readonly) NSError *error;

/**
 The timeout interval, in seconds, to wait for a response to load.

 The default value is 4 seconds.

 @see [ORKTestResponseLoader waitForResponse]
 */
@property (nonatomic, assign) NSTimeInterval timeout;

/**
 Creates and returns a test response loader object.

 @return A new response loader object.
 */
+ (id)responseLoader;

/**
 Waits for an asynchronous ORKRequest or ORKObjectLoader network operation to load a response
 by spinning the current run loop to block the current thread of execution.

 The wait operation is guarded by a timeout
 */
- (void)waitForResponse;

/**
 Returns the localized description error message for the error.

 TODO: Why not just move this to NSError+ORKAdditions?

 @return The localized description of the error or nil.
 */
- (NSString *)errorMessage;

@end
