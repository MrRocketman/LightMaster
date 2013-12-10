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
    
    [data.serialPortManager addObserver:self
                             forKeyPath:@"availablePorts"
                                options:NSKeyValueObservingOptionNew
                                context:NULL];
    [serialPortsPopUpButton performSelector:@selector(selectItemAtIndex:) withObject:0 afterDelay:2.0];
    [self performSelector:@selector(serialPortSelection:) withObject:nil afterDelay:2.0];
    
    [self updateCurrentTime:nil];
}

#pragma mark - Private Methods

- (void)updateCurrentTime:(NSNotification *)aNotification
{
    [currentTimeTextField setStringValue:[NSString stringWithFormat:@"%.03f", [data currentTime]]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqual:@"availablePorts"] && [change objectForKey:NSKeyValueChangeNewKey] != nil)
    {
        if([change objectForKey:NSKeyValueChangeNewKey] != [NSNull null])
        {
            if(![[change objectForKey:NSKeyValueChangeNewKey] containsObject:data.serialPort] && data.serialPort != nil)
            {
                // Remove the old port
                data.serialPort.delegate = nil;
                [data.serialPort close];
                data.serialPort = nil;
            }
            else if([[change objectForKey:NSKeyValueChangeNewKey] count] > 0)
            {
                // Open the new port
                [serialPortsPopUpButton performSelector:@selector(selectItemAtIndex:) withObject:0 afterDelay:2.0];
                [self performSelector:@selector(serialPortSelection:) withObject:nil afterDelay:2.0];
            }
        }
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
    [serialPort setBaudRate:@57600];
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

- (IBAction)loopButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoopButtonPress" object:nil];
}

- (IBAction)sectionsCheckboxPress:(id)sender
{
    data.shouldDrawSections = !data.shouldDrawSections;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)barsCheckboxPress:(id)sender
{
    data.shouldDrawBars = !data.shouldDrawBars;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)beatsCheckboxPress:(id)sender
{
    data.shouldDrawBeats = !data.shouldDrawBeats;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)tatumsCheckboxPress:(id)sender
{
    data.shouldDrawTatums = !data.shouldDrawTatums;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)segmentsCheckboxPress:(id)sender
{
    data.shouldDrawSegments = !data.shouldDrawSegments;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)timeCheckboxPress:(id)sender
{
    data.shouldDrawTime = !data.shouldDrawTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

@end
