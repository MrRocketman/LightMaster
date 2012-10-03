//
//  ToolbarViewController.m
//  LightMaster
//
//  Created by James Adams on 12/11/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import "ToolbarViewController.h"

@interface ToolbarViewController()

- (void)updateCurrentTime:(NSNotification *)aNotification;

@end

@implementation ToolbarViewController

@synthesize data;

#pragma mark - System Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Init Code Here
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCurrentTime:) name:@"CurrentTimeChange" object:nil];
    }
    
    return self;
}

- (void)viewWillLoad 
{
    
}

- (void)viewDidLoad 
{
    [self updateCurrentTime:nil];
}

- (void)prepareForDisplay 
{
    [self viewWillLoad];
    [super loadView];
    [self viewDidLoad];
}

#pragma mark - Private Methods

- (void)updateCurrentTime:(NSNotification *)aNotification
{
    [currentTimeTextField setStringValue:[NSString stringWithFormat:@"%.03f", [data currentTime]]];
}

#pragma mark - Button Methods

- (IBAction)rewindButtonPress:(id)sender
{
    
}

- (IBAction)fastForwardButtonPress:(id)sender
{
    
}

- (IBAction)skipBackButtonPress:(id)sender
{
    
}

- (IBAction)playButtonPress:(id)sender
{
    
}

- (IBAction)recordButtonPress:(id)sender
{
    
}

@end
