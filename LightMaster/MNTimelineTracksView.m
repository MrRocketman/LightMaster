//
//  MNTimelineTracksView.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNTimelineTracksView.h"
#import "MNTimelineTrackHeadersView.h"

@interface MNTimelineTracksView()

- (void)drawTrackBackgroundAtIndex:(int)index;
- (void)drawRect:(NSRect)aRect withCornerRadius:(float)radius fillColor:(NSColor *)color andStroke:(BOOL)yesOrNo;
- (void)drawAudioClipsAtTrackIndex:(int)index;
- (void)drawControlBoxCommandClustersAtTrackIndex:(int)index controlBoxIndex:(int)controlBoxIndex;
- (void)drawCommandsForCommandCluster:(NSMutableDictionary *)commandCluster atTrackIndex:(int)index forControlBoxOrChannelGroup:(int)boxOrChannelGroup;
- (void)drawChannelGroupCommandClustersAtTrackIndex:(int)index channelGroupIndex:(int)channelGroupIndex;

- (void)drawTimelineBar;
- (void)drawInvertedTriangleAndLineWithTipPoint:(NSPoint)point width:(int)width andHeight:(int)height;

- (void)updateTimeAtLeftEdgeOfTimelineView:(NSTimer*)theTimer;

@end

@implementation MNTimelineTracksView

@synthesize data;

#pragma mark - System methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Custom initialization code here
        clusterBackgroundImage = [NSImage imageNamed:@"CommandClusterBackground.tiff"];
        topBarBackgroundImage = [NSImage imageNamed:@"Toolbar.tiff"];
        
        // Register for the notifications on the scrollView
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchronizedViewContentBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[self superview]];
    }
    
    return self;
}

#pragma mark - Drawing Methods

- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification
{
    NSClipView *changedScrollView = [notification object];
    
    scrollViewOrigin = [changedScrollView documentVisibleRect].origin;
    scrollViewVisibleSize = [changedScrollView documentVisibleRect].size;
    [self.data setTimeAtLeftEdgeOfTimelineView:(scrollViewOrigin.x / [data zoomLevel] / PIXEL_TO_ZOOM_RATIO)];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor blackColor] set];
    NSRectFill(self.bounds);
    
    currentSequence = [data currentSequence];
    int tracksCount = [data audioClipFilePathsCountForSequence:currentSequence] + [data controlBoxFilePathsCountForSequence:currentSequence] + [data channelGroupFilePathsCountForSequence:currentSequence];
    // Set the Frame
    if(tracksCount * TRACK_HEIGHT + TOP_BAR_HEIGHT > [[self superview] frame].size.height)
    {
        [self setFrame:NSMakeRect(0.0, 0.0, 999999, tracksCount * TRACK_HEIGHT + TOP_BAR_HEIGHT)];
    }
    else
    {
        [self setFrame:NSMakeRect(0.0, 0.0, 999999, [[self superview] frame].size.height)];
    }
    
    tracksCount = 0;
    int audioClipsCount = 0, controlBoxCount = 0, channelGroupCount = 0;
    int channelGroupIndex = 0, controlBoxIndex = 0;
    // Draw the audio track
    if([data audioClipFilePathsCountForSequence:currentSequence] > 0)
    {
        [self drawTrackBackgroundAtIndex:tracksCount];
        [self drawAudioClipsAtTrackIndex:tracksCount];
        tracksCount ++;
        audioClipsCount ++;
    }
    // Draw the controlBox tracks
    for(int i = 0; i < [data controlBoxFilePathsCountForSequence:currentSequence]; i ++)
    {
        [self drawTrackBackgroundAtIndex:tracksCount];
        controlBoxIndex = (audioClipsCount > 0 ? tracksCount - audioClipsCount : tracksCount);
        [self drawControlBoxCommandClustersAtTrackIndex:tracksCount controlBoxIndex:controlBoxIndex];
        tracksCount ++;
        controlBoxCount ++;
    }
    // Draw the channelGroup tracks
    for(int i = 0; i < [data channelGroupFilePathsCountForSequence:currentSequence]; i ++)
    {
        [self drawTrackBackgroundAtIndex:tracksCount];
        channelGroupIndex = (audioClipsCount > 0 ? tracksCount - audioClipsCount : tracksCount);
        channelGroupIndex = (controlBoxCount > 0 ? channelGroupIndex - controlBoxCount : channelGroupIndex);
        [self drawChannelGroupCommandClustersAtTrackIndex:tracksCount channelGroupIndex:channelGroupIndex];
        tracksCount ++;
        channelGroupCount ++;
    }
    
    // Draw the timeline on top of everything
    [self drawTimelineBar];
}

- (void)drawTrackBackgroundAtIndex:(int)index
{
    // Draw the Track Background
    NSRect backgroundFrame = NSMakeRect(0, self.frame.size.height - (index + 1) * TRACK_HEIGHT - TOP_BAR_HEIGHT, self.frame.size.width, TRACK_HEIGHT);
    NSSize imageSize = [clusterBackgroundImage size];
    [clusterBackgroundImage drawInRect:backgroundFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawRect:(NSRect)aRect withCornerRadius:(float)radius fillColor:(NSColor *)color andStroke:(BOOL)yesOrNo
{
    NSBezierPath *thePath = [NSBezierPath bezierPathWithRoundedRect:aRect xRadius:radius yRadius:radius];
	[color setFill];
	
	//NSLog(@"drawRect x:%f, y:%f, w:%f, h:%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
	[[NSColor whiteColor] setStroke];
	if(yesOrNo)
    {
        [thePath stroke];
    }
	[thePath fill];
}

- (void)drawAudioClipsAtTrackIndex:(int)index
{
    for(int i = 0; i < [data audioClipFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSMutableDictionary *currentAudioClip = [data audioClipFromFilePath:[data audioClipFilePathAtIndex:i forSequence:currentSequence]];
        NSRect audioClipRect = NSMakeRect([data timeToX:[data startTimeForAudioClip:currentAudioClip]], self.frame.size.height - (index + 1) * TRACK_HEIGHT - TOP_BAR_HEIGHT + 1, [data widthForTimeInterval:[data endTimeForAudioClip:currentAudioClip] - [data startTimeForAudioClip:currentAudioClip]], TRACK_HEIGHT - 2);
        
        // AudioClip Mouse Checking here
        if([[NSBezierPath bezierPathWithRect:audioClipRect] containsPoint:mousePoint] && mouseAction == MNMouseUp && mouseEvent != nil)
        {
            [self drawRect:audioClipRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
            selectedAudioClip = currentAudioClip;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectAudioClip" object:selectedAudioClip];
            mouseEvent = nil;
        }
        else
        {
            [self drawRect:audioClipRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.7] andStroke:YES];
            selectedAudioClip = nil;
        }
    }
}

- (void)drawControlBoxCommandClustersAtTrackIndex:(int)index controlBoxIndex:(int)controlBoxIndex
{
    for(int i = 0; i < [data commandClusterFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSMutableDictionary *currentCommandCluster = [data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:i forSequence:currentSequence]];
        // Command Cluster is for this controlBox
        if([[data controlBoxFilePathForCommandCluster:currentCommandCluster] isEqualToString:[data controlBoxFilePathAtIndex:controlBoxIndex forSequence:currentSequence]])
        {
            NSRect commandClusterRect = NSMakeRect([data timeToX:[data startTimeForCommandCluster:currentCommandCluster]], self.frame.size.height - (index + 1) * TRACK_HEIGHT - TOP_BAR_HEIGHT + 1, [data widthForTimeInterval:[data endTimeForCommandCluster:currentCommandCluster] - [data startTimeForCommandCluster:currentCommandCluster]], TRACK_HEIGHT - 2);
            
            // Command Cluster Mouse Checking here
            if([[NSBezierPath bezierPathWithRect:commandClusterRect] containsPoint:mousePoint] && mouseAction == MNMouseUp && mouseEvent != nil)
            {
                [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
                selectedCommandCluster = currentCommandCluster;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommandCluster" object:selectedCommandCluster];
            }
            else
            {
                [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.0 alpha:0.7] andStroke:YES];
                selectedCommandCluster = nil;
            }
            
            // Draw the commands and check for mouse clicks
            [self drawCommandsForCommandCluster:currentCommandCluster atTrackIndex:index forControlBoxOrChannelGroup:MNControlBox];
            
            // Get rid of the mouseEvent
            if(selectedCommandCluster != nil)
            {
                mouseEvent = nil;
            }
        }
    }
}

- (void)drawChannelGroupCommandClustersAtTrackIndex:(int)index channelGroupIndex:(int)channelGroupIndex
{
    for(int i = 0; i < [data commandClusterFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSMutableDictionary *currentCommandCluster = [data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:i forSequence:currentSequence]];
        // Command Cluster is for this channelGroup
        if([[data channelGroupFilePathForCommandCluster:currentCommandCluster] isEqualToString:[data channelGroupFilePathAtIndex:channelGroupIndex forSequence:currentSequence]])
        {
            NSRect commandClusterRect = NSMakeRect([data timeToX:[data startTimeForCommandCluster:currentCommandCluster]], self.frame.size.height - (index + 1) * TRACK_HEIGHT - TOP_BAR_HEIGHT + 1, [data widthForTimeInterval:[data endTimeForCommandCluster:currentCommandCluster] - [data startTimeForCommandCluster:currentCommandCluster]], TRACK_HEIGHT - 2);
            
            // Command Cluster Mouse Checking here
            if([[NSBezierPath bezierPathWithRect:commandClusterRect] containsPoint:mousePoint] && mouseAction == MNMouseUp && mouseEvent != nil)
            {
                [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
                selectedCommandCluster = currentCommandCluster;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommandCluster" object:selectedCommandCluster];
            }
            else
            {
                [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.7] andStroke:YES];
                selectedCommandCluster = nil;
            }
            
            // Draw the commands and check for mouse clicks
            [self drawCommandsForCommandCluster:currentCommandCluster atTrackIndex:index forControlBoxOrChannelGroup:MNChannelGroup];
            
            // Get rid of the mouseEvent
            if(selectedCommandCluster != nil)
            {
                mouseEvent = nil;
            }
        }
    }
}

- (void)drawCommandsForCommandCluster:(NSMutableDictionary *)commandCluster atTrackIndex:(int)index forControlBoxOrChannelGroup:(int)boxOrChannelGroup
{
    int numberOfChannelsForCommandCluster = 0;
    if(boxOrChannelGroup == MNControlBox)
    {
        numberOfChannelsForCommandCluster = [data channelsCountForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:commandCluster]]];
    }
    else if(boxOrChannelGroup == MNChannelGroup)
    {
        numberOfChannelsForCommandCluster = [data itemsCountForChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathForCommandCluster:commandCluster]]];
    }
    float channelHeightForCommandCluster = (TRACK_HEIGHT - 10) / numberOfChannelsForCommandCluster;
    
    for(int i = 0; i < [data commandsCountForCommandCluster:commandCluster]; i ++)
    {
        NSMutableDictionary *currentCommand = [data commandAtIndex:i fromCommandCluster:commandCluster];
        NSRect commandRect = NSMakeRect([data timeToX:[data startTimeForCommand:currentCommand]], self.frame.size.height - (index + 1) * TRACK_HEIGHT - TOP_BAR_HEIGHT + (TRACK_HEIGHT - 5) - channelHeightForCommandCluster * ([data channelIndexForCommand:currentCommand] + 1), [data widthForTimeInterval:[data endTimeForCommand:currentCommand] - [data startTimeForCommand:currentCommand]], channelHeightForCommandCluster);
        
        // Command Mouse Checking Here
        if([[NSBezierPath bezierPathWithRect:commandRect] containsPoint:mousePoint] && mouseAction == MNMouseUp && mouseEvent != nil)
        {
            [self drawRect:commandRect withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
            selectedCommand = currentCommand;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommand" object:selectedCommand];
            mouseEvent = nil;
        }
        else
        {
            [self drawRect:commandRect withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.2 green:0.2 blue:0.2 alpha:0.7] andStroke:YES];
            selectedCommand = nil;
        }
    }
}

- (void)drawTimelineBar
{
    // Draw the Top Bar
    NSRect superViewFrame = [[self superview] frame];
    //NSRect topBarFrame = NSMakeRect(0, self.frame.size.height - TOP_BAR_HEIGHT, self.frame.size.width, TOP_BAR_HEIGHT);
    NSRect topBarFrame = NSMakeRect(0, scrollViewOrigin.y + superViewFrame.size.height - TOP_BAR_HEIGHT, self.frame.size.width, TOP_BAR_HEIGHT);
    NSSize imageSize = [topBarBackgroundImage size];
    [topBarBackgroundImage drawInRect:topBarFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    
    // TopBar Mouse Checking
    if([[NSBezierPath bezierPathWithRect:topBarFrame] containsPoint:mousePoint] && mouseAction == MNMouseUp && mouseEvent != nil && ![data currentTimeMarkerIsSelected])
    {
        [data setCurrentTime:[data xToTime:mousePoint.x]];
        mouseEvent = nil;
    }
    
    // Draw timeline
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:12];
    [attributes setObject:font forKey:NSFontAttributeName];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeMarkerDifference = 0.0;
    if(timeSpan >= 10.0)
    {
        timeMarkerDifference = 1.0;
    }
    else if(timeSpan >= 5.0)
    {
        timeMarkerDifference = 0.5;
    }
    else if(timeSpan >= 2.5)
    {
        timeMarkerDifference = 0.25;
    }
    else if(timeSpan >= 1.25)
    {
        timeMarkerDifference = 0.125;
    }
    else
    {
        timeMarkerDifference = 0.0625;
    }
	for(int i = 0; i < timeSpan / timeMarkerDifference + 5; i ++)
	{
        float someTime = ((int)[data timeAtLeftEdgeOfTimelineView] - timeMarkerDifference + i * timeMarkerDifference);
        NSString *time = [NSString stringWithFormat:@"%.03f", someTime];
        NSRect textFrame = NSMakeRect([data timeToX:someTime], topBarFrame.origin.y, 40, topBarFrame.size.height);
        [time drawInRect:textFrame withAttributes:attributes];
        
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect(textFrame.origin.x, scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor whiteColor] set];
        NSRectFill(markerLineFrame);
	}
    
    // Mouse Checking
    if(mouseAction == MNMouseDragged && [data currentTimeMarkerIsSelected] && mouseEvent != nil)
    {
        float newCurrentTime = [data xToTime:mousePoint.x];
        // Bind the minimum time to 0
        if(newCurrentTime < 0.0)
        {
            newCurrentTime = 0.0;
        }
        [data setCurrentTime:newCurrentTime];
        
        if([data timeToX:newCurrentTime] > superViewFrame.size.width - AUTO_SCROLL_PIXEL_BUFFER || [data timeToX:newCurrentTime] < AUTO_SCROLL_PIXEL_BUFFER)
        {
            [autoScrollTimer invalidate];
            autoScrollTimer = nil;
            [[self superview] autoscroll:mouseEvent];
            autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:AUTO_SCROLL_REFRESH_RATE target:self selector:@selector(updateTimeAtLeftEdgeOfTimelineView:) userInfo:nil repeats:YES];
            timerIsRunning = YES;
        }
    }
    else if(timerIsRunning)
    {
        [autoScrollTimer invalidate];
        autoScrollTimer = nil;
        timerIsRunning = NO;
    }
    
    // Draw the currentTime marker
    NSPoint trianglePoint = NSMakePoint((float)[data timeToX:[data currentTime]], topBarFrame.origin.y);
    [self drawInvertedTriangleAndLineWithTipPoint:trianglePoint width:20 andHeight:20];
}

- (void)drawInvertedTriangleAndLineWithTipPoint:(NSPoint)point width:(int)width andHeight:(int)height
{
    NSBezierPath *triangle = [NSBezierPath bezierPath];
	
    [triangle moveToPoint:point];
    [triangle lineToPoint:NSMakePoint(point.x - width / 2,  point.y + height)];
    [triangle lineToPoint:NSMakePoint(point.x + width / 2, point.y + height)];
    [triangle closePath];
    
    // CurrentTime Marker Mouse checking
    if([triangle containsPoint:mousePoint] && mouseAction == MNMouseDown && mouseEvent != nil)
    {
        [data setCurrentTimeMarkerIsSelected:YES];
        mouseEvent = nil;
    }
    else if([data currentTimeMarkerIsSelected] && mouseAction == MNMouseUp && mouseEvent != nil)
    {
        [data setCurrentTimeMarkerIsSelected:NO];
        mouseEvent = nil;
    }
	
    // Set the color according to whether it is clicked or not
	if(![data currentTimeMarkerIsSelected])
    {
        [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] setFill];
    }
	else
    {
        [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.5] setFill];
    }
	[triangle fill];
	[[NSColor whiteColor] setStroke];
    [triangle stroke];
    
    NSRect markerLineFrame = NSMakeRect(point.x, scrollViewOrigin.y, 1, [[self superview] frame].size.height - TOP_BAR_HEIGHT);
    [[NSColor redColor] set];
    NSRectFill(markerLineFrame);
}

- (void)updateTimeAtLeftEdgeOfTimelineView:(NSTimer *)theTimer;
{
    [[self superview] autoscroll:mouseEvent];
    [self setNeedsDisplay:YES];
}

#pragma mark Mouse Methods

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	mousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseDown;
    mouseEvent = theEvent;
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	mousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseDragged;
    mouseEvent = theEvent;
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	mousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseUp;
    mouseEvent = theEvent;
    [self setNeedsDisplay:YES];
}

@end
