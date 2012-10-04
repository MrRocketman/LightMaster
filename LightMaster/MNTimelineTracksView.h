//
//  MNTimelineTracksView.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MNSynchronizedScrollView.h"
#import "MNData.h"

#define CLUSTER_CORNER_RADIUS 5.0
#define COMMAND_CORNER_RADIUS 3.0
#define AUTO_SCROLL_PIXEL_BUFFER 15
#define AUTO_SCROLL_REFRESH_RATE 0.03

enum
{
    MNMouseDown,
    MNMouseDragged,
    MNMouseUp
};

enum
{
    MNControlBox,
    MNChannelGroup
};

@interface MNTimelineTracksView : NSView
{
    MNData *__weak data;
    
    NSImage *clusterBackgroundImage;
    NSImage *topBarBackgroundImage;
    
    NSPoint scrollViewOrigin;
    NSSize scrollViewVisibleSize;
    
    NSMutableDictionary *currentSequence;
    NSPoint mousePoint;
    int mouseAction;
    NSEvent *mouseEvent;
    NSTimer *autoScrollTimer;
    BOOL timerIsRunning;
    
    NSMutableDictionary *selectedCommandCluster;
    NSMutableDictionary *selectedCommand;
    NSMutableDictionary *selectedAudioClip;
}

@property(readwrite, weak) MNData *data;

@end
