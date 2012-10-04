//
//  MNToolbarViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNToolbarViewController.h"

@interface MNToolbarViewController ()

- (void)updateCurrentTime:(NSNotification *)aNotification;

@end

@implementation MNToolbarViewController

#pragma mark - System Methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Init Code Here
    }
    
    return self;
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCurrentTime:) name:@"CurrentTimeChange" object:nil];
    
    [self updateCurrentTime:nil];
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
