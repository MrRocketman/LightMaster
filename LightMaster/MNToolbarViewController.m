//
//  MNToolbarViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNToolbarViewController.h"
#import "ORSSerialPortManager.h"


@interface MNToolbarViewController ()

- (void)updateCurrentTime:(NSNotification *)aNotification;
- (void)updateSerialPortsPopUpButton;

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
    
    [self updateSerialPortsPopUpButton];
    [self updateCurrentTime:nil];
}

#pragma mark - Private Methods

- (void)updateCurrentTime:(NSNotification *)aNotification
{
    [currentTimeTextField setStringValue:[NSString stringWithFormat:@"%.03f", [data currentTime]]];
}

- (void)updateSerialPortsPopUpButton
{
    [serialPortsPopUpButton removeAllItems];
    
    for (ORSSerialPort* aPort in [[data serialPortManager] availablePorts])
    {
        // print port name
        NSLog(@"Name:%@", [aPort name]);
        NSLog(@"BSDPath:%@", [aPort path]);
        [serialPortsPopUpButton addItemWithTitle:[aPort path]];
	}
}

#pragma mark - IBActions Methods

- (IBAction)serialPortSelection:(id)sender
{
    // Remove the old port
    data.serialPort.delegate = nil;
    [data.serialPort close];
    data.serialPort = nil;
    
    // Open the new port
    ORSSerialPort *serialPort = [ORSSerialPort serialPortWithPath:[[serialPortsPopUpButton selectedItem] title]];
    [serialPort setDelegate:data];
    [serialPort setBaudRate:@115200];
    [serialPort open];
    data.serialPort = serialPort;
}

- (IBAction)rewindButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RewindButtonPress" object:nil];
}

- (IBAction)fastForwardButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FastForwardButtonPress" object:nil];
}

- (IBAction)skipBackButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SkipBackButtonPress" object:nil];
}

- (IBAction)playButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayButtonPress" object:nil];
}

- (IBAction)recordButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RecordButtonPress" object:nil];
}

@end
