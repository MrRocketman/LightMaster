//
//  MNAppDelegate.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNAppDelegate.h"
#import "ORSSerialPortManager.h"

@implementation MNAppDelegate

@synthesize data;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"Launch");
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSLog(@"Terminate");
    
    for(uint8_t i = 0; i < 25; i ++)
    {
        // Send the command!
        uint8_t command[64];
        int charCount = 0;
        command[charCount] = i;
        charCount ++;
        command[charCount] = 0x04;
        charCount ++;
        command[charCount] = 0x00;
        charCount ++;
        command[charCount] = 0x00;
        charCount ++;
        command[charCount] = 0x00;
        charCount ++;
        command[charCount] = 0x00;
        charCount ++;
        command[charCount] = 0x00;
        charCount ++;
        command[charCount] = 0x00;
        charCount ++;
        command[charCount] = 0x00;
        charCount ++;
        command[charCount] = 0x00;
        charCount ++;
        command[charCount] = 0xFF;
        charCount ++;
        
        [data sendPacketToSerialPort:command packetLength:charCount];
    }
    
	NSArray *ports = [[data serialPortManager] availablePorts];
    
	for (ORSSerialPort *port in ports)
    {
        [port close];
    }
}

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{
    NSLog(@"size w:%f h:%f", proposedFrameSize.width, proposedFrameSize.height);
    return proposedFrameSize;
}

- (void)windowWillStartLiveResize:(NSNotification *)notification
{
    NSLog(@"notification:%@", notification);
}

#pragma mark - Menu Items

- (IBAction)newSequence:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewSequence" object:nil userInfo:nil];
}

- (IBAction)convertRBC:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ConvertRBC" object:nil userInfo:nil];
}

- (IBAction)newControlBox:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewControlBox" object:nil userInfo:nil];
}

- (IBAction)newChannelGroup:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewChanelGroup" object:nil userInfo:nil];
}

- (IBAction)newCommandCluster:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewCommandCluster" object:nil userInfo:nil];
}

- (IBAction)splitCommandCluster:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SplitCommandCluster" object:nil userInfo:nil];
}

- (IBAction)newEffect:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewEffect" object:nil userInfo:nil];
}

- (IBAction)newAudioClip:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewAudioClip" object:nil userInfo:nil];
}

@end
