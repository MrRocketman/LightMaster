//
//  TimelineClustersView.h
//  LightMaster
//
//  Created by James Adams on 12/14/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Data.h"

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
    MNGroup
};

@interface TimelineClustersView : NSView
{
    Data *__weak data;
    
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
    NSMutableDictionary *selectedSound;
}

@property(readwrite, weak) Data *data;

@end
