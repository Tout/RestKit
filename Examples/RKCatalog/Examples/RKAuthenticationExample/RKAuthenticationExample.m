//
//  ORKAuthenticationExample.m
//  ORKCatalog
//
//  Created by Blake Watters on 9/27/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKAuthenticationExample.h"

@implementation ORKAuthenticationExample

@synthesize authenticatedRequest;
@synthesize URLTextField;
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize authenticationTypePickerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        ORKClient *client = [ORKClient clientWithBaseURL:gORKCatalogBaseURL];
        [ORKClient setSharedClient:client];
    }
    return self;
}

- (void)dealloc
{
    [authenticatedRequest cancel];
    [authenticatedRequest release];
    authenticatedRequest = nil;

    [super dealloc];
}

/**
 We are constructing our own ORKRequest here rather than working with the client.
 It is important to remember that ORKClient is really just a factory object for instances
 of ORKRequest. At any time you can directly configure an ORKRequest instead.
 */
- (void)sendRequest
{
    NSURL *URL = [NSURL URLWithString:[URLTextField text]];
    ORKRequest *newRequest = [ORKRequest requestWithURL:URL];
    newRequest.delegate = self;
    newRequest.authenticationType = ORKRequestAuthenticationTypeHTTP;
    newRequest.username = [usernameTextField text];
    newRequest.password = [passwordTextField text];

    self.authenticatedRequest = newRequest;
}

- (void)request:(ORKRequest *)request didFailLoadWithError:(NSError *)error
{
    ORKLogError(@"Load of ORKRequest %@ failed with error: %@", request, error);
    [request release];
}

- (void)request:(ORKRequest *)request didLoadResponse:(ORKResponse *)response
{
    ORKLogCritical(@"Loading of ORKRequest %@ completed with status code %d. Response body: %@", request, response.statusCode, [response bodyAsString]);
    [request release];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 0;
}

@end
