//
//  MNToolbarViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNToolbarViewController.h"
#import "AMSerialPortList.h"


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
    // register for port add/remove notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddPorts:) name:AMSerialPortListDidAddPortsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemovePorts:) name:AMSerialPortListDidRemovePortsNotification object:nil];
	[AMSerialPortList sharedPortList]; // initialize port list to arm notifications
    
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
    
    for (AMSerialPort* aPort in [[AMSerialPortList sharedPortList] serialPorts])
    {
        // print port name
        NSLog(@"Name:%@", [aPort name]);
        NSLog(@"BSDPath:%@", [aPort bsdPath]);
        [serialPortsPopUpButton addItemWithTitle:[aPort bsdPath]];
	}
}

#pragma mark - SERIAL PORT NOTIFICATIONS

- (void)didAddPorts:(NSNotification *)theNotification
{
	NSLog(@"Added Port:%@", [[theNotification userInfo] description]);
    [self updateSerialPortsPopUpButton];
}

- (void)didRemovePorts:(NSNotification *)theNotification
{
	NSLog(@"Removed Port:%@", [[theNotification userInfo] description]);
    [self updateSerialPortsPopUpButton];
}

#pragma mark - IBActions Methods

- (IBAction)serialPortSelection:(id)sender
{
    [data openSerialPort:[[serialPortsPopUpButton selectedItem] title]];
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
