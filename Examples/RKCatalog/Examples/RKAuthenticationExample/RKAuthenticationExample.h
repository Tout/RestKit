//
//  ORKAuthenticationExample.h
//  ORKCatalog
//
//  Created by Blake Watters on 9/27/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "ORKCatalog.h"

@interface ORKAuthenticationExample : UIViewController <ORKRequestDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, retain) ORKRequest *authenticatedRequest;
@property (nonatomic, retain) IBOutlet UITextField  *URLTextField;
@property (nonatomic, retain) IBOutlet UITextField  *usernameTextField;
@property (nonatomic, retain) IBOutlet UITextField  *passwordTextField;
@property (nonatomic, retain) IBOutlet UIPickerView *authenticationTypePickerView;

- (IBAction)sendRequest;

@end
