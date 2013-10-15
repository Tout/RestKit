//
//  ORKParamsExample.m
//  ORKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKParamsExample.h"

@implementation ORKParamsExample

@synthesize progressView = _progressView;
@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize imageView = _imageView;
@synthesize uploadButton = _uploadButton;
@synthesize statusLabel = _statusLabel;

- (void)dealloc
{
    [ORKClient setSharedClient:nil];
    [_client release];
    [super dealloc];
}

- (void)viewDidLoad
{
    _client = [[ORKClient alloc] initWithBaseURL:gORKCatalogBaseURL];
}

- (IBAction)uploadButtonWasTouched:(id)sender
{
    ORKParams *params = [ORKParams params];

    // Attach the Image from Image View
    NSLog(@"Got image: %@", [_imageView image]);
    NSData *imageData = UIImagePNGRepresentation([_imageView image]);
    [params setData:imageData MIMEType:@"image/png" forParam:@"image1"];

    // Attach an Image from the App Bundle
    UIImage *image = [UIImage imageNamed:@"RestKit.png"];
    imageData = UIImagePNGRepresentation(image);
    [params setData:imageData MIMEType:@"image/png" forParam:@"image2"];

    // Log info about the serialization
    NSLog(@"ORKParams HTTPHeaderValueForContentType = %@", [params HTTPHeaderValueForContentType]);
    NSLog(@"ORKParams HTTPHeaderValueForContentLength = %d", [params HTTPHeaderValueForContentLength]);

    // Send it for processing!
    [_client post:@"/ORKParamsExample" params:params delegate:self];
}

- (void)requestDidStartLoad:(ORKRequest *)request
{
    _uploadButton.enabled = NO;
    [_activityIndicatorView startAnimating];
}

- (void)request:(ORKRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    _progressView.progress = (totalBytesWritten / totalBytesExpectedToWrite) * 100.0;
}

- (void)request:(ORKRequest *)request didLoadResponse:(ORKResponse *)response
{
    _uploadButton.enabled = YES;
    [_activityIndicatorView stopAnimating];

    if ([response isOK]) {
        _statusLabel.text = @"Upload Successful!";
        _statusLabel.textColor = [UIColor greenColor];
    } else {
        _statusLabel.text = [NSString stringWithFormat:@"Upload failed with status code: %d", [response statusCode]];
        _statusLabel.textColor = [UIColor redColor];
    }
}

- (void)request:(ORKRequest *)request didFailLoadWithError:(NSError *)error
{
    _uploadButton.enabled = YES;
    [_activityIndicatorView stopAnimating];
    _progressView.progress = 0.0;

    _statusLabel.text = [NSString stringWithFormat:@"Upload failed with error: %@", [error localizedDescription]];
    _statusLabel.textColor = [UIColor redColor];
}

@end
