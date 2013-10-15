//
//  ORKRequestQueueExample.m
//  ORKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "ORKRequestQueueExample.h"

@implementation ORKRequestQueueExample

@synthesize requestQueue;
@synthesize statusLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        ORKClient *client = [ORKClient clientWithBaseURL:gORKCatalogBaseURL];
        [ORKClient setSharedClient:client];

        // Ask RestKit to spin the network activity indicator for us
        client.requestQueue.delegate = self;
        client.requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;
    }

    return self;
}

// We have been dismissed -- clean up any open requests
- (void)dealloc
{
    [[ORKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
    [requestQueue cancelAllRequests];
    [requestQueue release];
    requestQueue = nil;

    [super dealloc];
}

// We have been obscured -- cancel any pending requests
- (void)viewWillDisappear:(BOOL)animated
{
    [[ORKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
}

- (IBAction)sendRequest
{
    /**
     * Ask ORKClient to load us some data. This causes an ORKRequest object to be created
     * transparently pushed onto the ORKClient's ORKRequestQueue instance
     */
    [[ORKClient sharedClient] get:@"/ORKRequestQueueExample" delegate:self];
}

- (IBAction)queueRequests
{
    ORKRequestQueue *queue = [ORKRequestQueue requestQueue];
    queue.delegate = self;
    queue.concurrentRequestsLimit = 1;
    queue.showsNetworkActivityIndicatorWhenBusy = YES;

    // Queue up 4 requests
    ORKRequest *request = [[ORKClient sharedClient] requestWithResourcePath:@"/ORKRequestQueueExample"];
    request.delegate = self;
    [queue addRequest:request];

    request = [[ORKClient sharedClient] requestWithResourcePath:@"/ORKRequestQueueExample"];
    request.delegate = self;
    [queue addRequest:request];

    request = [[ORKClient sharedClient] requestWithResourcePath:@"/ORKRequestQueueExample"];
    request.delegate = self;
    [queue addRequest:request];

    request = [[ORKClient sharedClient] requestWithResourcePath:@"/ORKRequestQueueExample"];
    request.delegate = self;
    [queue addRequest:request];

    // Start processing!
    [queue start];
    self.requestQueue = queue;
}

- (void)requestQueue:(ORKRequestQueue *)queue didSendRequest:(ORKRequest *)request
{
    statusLabel.text = [NSString stringWithFormat:@"ORKRequestQueue %@ is current loading %d of %d requests",
                         queue, [queue loadingCount], [queue count]];
}

- (void)requestQueueDidBeginLoading:(ORKRequestQueue *)queue
{
    statusLabel.text = [NSString stringWithFormat:@"Queue %@ Began Loading...", queue];
}

- (void)requestQueueDidFinishLoading:(ORKRequestQueue *)queue
{
    statusLabel.text = [NSString stringWithFormat:@"Queue %@ Finished Loading...", queue];
}

@end
