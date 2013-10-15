//
//  ORKBackgroundRequestExample.m
//  ORKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "ORKBackgroundRequestExample.h"

@implementation ORKBackgroundRequestExample

@synthesize sendButton = _sendButton;
@synthesize segmentedControl = _segmentedControl;
@synthesize statusLabel = _statusLabel;

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
    [[ORKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];

    [super dealloc];
}

- (IBAction)sendRequest
{
    ORKRequest *request = [[ORKClient sharedClient] requestWithResourcePath:@"/ORKBackgroundRequestExample"];
    request.delegate = self;
    request.backgroundPolicy = _segmentedControl.selectedSegmentIndex;
    [request send];
    _sendButton.enabled = NO;
}

- (void)requestDidStartLoad:(ORKRequest *)request
{
    _statusLabel.text = [NSString stringWithFormat:@"Sent request with background policy %d at %@", request.backgroundPolicy, [NSDate date]];
}

- (void)requestDidTimeout:(ORKRequest *)request
{
    _statusLabel.text = @"Request timed out during background processing";
    _sendButton.enabled = YES;
}

- (void)requestDidCancelLoad:(ORKRequest *)request
{
    _statusLabel.text = @"Request canceled";
    _sendButton.enabled = YES;
}

- (void)request:(ORKRequest *)request didLoadResponse:(ORKResponse *)response
{
    _statusLabel.text = [NSString stringWithFormat:@"Request completed with response: '%@'", [response bodyAsString]];
    _sendButton.enabled = YES;
}

- (void)request:(ORKRequest *)request didFailLoadWithError:(NSError *)error
{
    _statusLabel.text = [NSString stringWithFormat:@"Request failed with error: %@", [error localizedDescription]];
    _sendButton.enabled = YES;
}

@end
