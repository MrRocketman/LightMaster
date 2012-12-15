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
#define AUTO_SCROLL_REFRESH_RATE 0.03
#define TIME_ADJUST_PIXEL_BUFFER 8.0

enum
{
    MNControlBox,
    MNChannelGroup
};

enum
{
    MNMouseDragNotInUse,
    MNAudioClipMouseDrag,
    MNControlBoxCommandClusterMouseDrag,
    MNChannelGroupCommandClusterMouseDrag,
    MNCommandMouseDrag,
    MNCommandMouseDragEndTime,
    MNCommandMouseDragStartTime,
    MNCommandMouseDragBetweenChannels,
    MNTimeMarkerMouseDrag,
    MNNewClusterMouseDrag,
    MNControlBoxCommandClusterMouseDragStartTime,
    MNControlBoxCommandClusterMouseDragEndTime,
    MNControlBoxCommandClusterMouseDragBetweenChannels,
};

@interface MNTimelineTracksView : NSView
{
    IBOutlet MNData *data;
    
    NSImage *clusterBackgroundImage;
    NSImage *topBarBackgroundImage;
    
    NSPoint scrollViewOrigin;
    NSSize scrollViewVisibleSize;
    
    NSPoint mouseClickDownPoint;
    NSPoint currentMousePoint;
    int mouseAction;
    NSEvent *mouseEvent;
    NSTimer *autoScrollTimer;
    int mouseDraggingEvent;
    int mouseDraggingEventObjectIndex;
    BOOL autoscrollTimerIsRunning;
    BOOL currentTimeMarkerIsSelected;
    
    BOOL highlightedACluster;
    int selectedCommandClusterIndex;
    int selectedCommandIndex;
    int commandClusterIndexForSelectedCommand;
    NSMutableDictionary *selectedAudioClip;
    
    NSMutableArray *audioClipNSSounds;
}

@property(readwrite, assign) int selectedCommandClusterIndex;

@end
