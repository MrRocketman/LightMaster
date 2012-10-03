//
//  CommandEditorViewController.m
//  LightMaster
//
//  Created by James Adams on 12/4/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import "CommandEditorViewController.h"

@implementation CommandEditorViewController

@synthesize data;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Init Code Here
    }
    
    return self;
}

- (void)viewWillLoad 
{
    
}

- (void)viewDidLoad 
{
    
}

- (void)prepareForDisplay 
{
    [self viewWillLoad];
    [super loadView];
    [self viewDidLoad];
}

@end
