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

- (void)drawBackgroundTrackAtTrackIndex:(int)trackIndex trackItemsTall:(int)trackItems;
- (void)drawRect:(NSRect)aRect withCornerRadius:(float)radius fillColor:(NSColor *)color andStroke:(BOOL)yesOrNo;
- (void)drawAudioClipsAtTrackIndex:(int)trackIndex trackItemsTall:(int)trackItems;
- (void)drawControlBoxCommandClustersAtTrackIndex:(int)trackIndex trackItemsTall:(int)trackItems controlBoxIndex:(int)controlBoxIndex;
- (void)drawCommandsForCommandCluster:(NSMutableDictionary *)commandCluster atTrackIndex:(int)trackIndex trackItemsTall:(int)trackItems forControlBoxOrChannelGroup:(int)boxOrChannelGroup;
- (void)drawChannelGroupCommandClustersAtTrackIndex:(int)trackIndex trackItemsTall:(int)trackItems channelGroupIndex:(int)channelGroupIndex;

- (void)drawTimelineBar;
- (void)drawInvertedTriangleAndLineWithTipPoint:(NSPoint)point width:(int)width andHeight:(int)height;

- (void)updateTimeAtLeftEdgeOfTimelineView:(NSTimer*)theTimer;
- (float)roundUpNumber:(float)numberToRound toNearestMultipleOfNumber:(float)multiple;

@end


@implementation MNTimelineTracksView

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
    [data setTimeAtLeftEdgeOfTimelineView:(scrollViewOrigin.x / [data zoomLevel] / PIXEL_TO_ZOOM_RATIO)];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"TimelineTrackBackgroundImage.png"]] set];
    NSRectFill(self.bounds);
    
    currentSequence = [data currentSequence];
    int trackItemsCount = [data trackItemsCount];
    
    // Set the Frame
    if(trackItemsCount * TRACK_ITEM_HEIGHT + TOP_BAR_HEIGHT > [[self superview] frame].size.height)
    {
        [self setFrame:NSMakeRect(0.0, 0.0, 999999, trackItemsCount * TRACK_ITEM_HEIGHT + TOP_BAR_HEIGHT)];
    }
    else
    {
        [self setFrame:NSMakeRect(0.0, 0.0, 999999, [[self superview] frame].size.height)];
    }
    
    trackItemsCount = 0;
    int thisTrackItemsCount = 0;
    int audioClipsCount = 0, controlBoxCount = 0, channelGroupCount = 0;
    int channelGroupIndex = 0, controlBoxIndex = 0;
    // Draw the audio track
    if([data audioClipFilePathsCountForSequence:currentSequence] > 0)
    {
        thisTrackItemsCount = [data audioClipFilePathsCountForSequence:currentSequence];
        [self drawBackgroundTrackAtTrackIndex:trackItemsCount trackItemsTall:thisTrackItemsCount];
        [self drawAudioClipsAtTrackIndex:trackItemsCount trackItemsTall:thisTrackItemsCount];
        trackItemsCount += thisTrackItemsCount;
        audioClipsCount += thisTrackItemsCount;
    }
    // Draw the controlBox tracks
    for(int i = 0; i < [data controlBoxFilePathsCountForSequence:currentSequence]; i ++)
    {
        thisTrackItemsCount = [data channelsCountForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:i]]];
        [self drawBackgroundTrackAtTrackIndex:trackItemsCount trackItemsTall:thisTrackItemsCount];
        controlBoxIndex = (audioClipsCount > 0 ? trackItemsCount - audioClipsCount : trackItemsCount);
        [self drawControlBoxCommandClustersAtTrackIndex:trackItemsCount trackItemsTall:thisTrackItemsCount controlBoxIndex:controlBoxIndex];
        trackItemsCount += thisTrackItemsCount;
        controlBoxCount += thisTrackItemsCount;
    }
    // Draw the channelGroup tracks
    for(int i = 0; i < [data channelGroupFilePathsCountForSequence:currentSequence]; i ++)
    {
        thisTrackItemsCount = [data itemsCountForChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathAtIndex:i]]];
        [self drawBackgroundTrackAtTrackIndex:trackItemsCount trackItemsTall:thisTrackItemsCount];
        channelGroupIndex = (audioClipsCount > 0 ? trackItemsCount - audioClipsCount : trackItemsCount);
        channelGroupIndex = (controlBoxCount > 0 ? channelGroupIndex - controlBoxCount : channelGroupIndex);
        [self drawChannelGroupCommandClustersAtTrackIndex:trackItemsCount trackItemsTall:thisTrackItemsCount channelGroupIndex:channelGroupIndex];
        trackItemsCount += thisTrackItemsCount;
        channelGroupCount += thisTrackItemsCount;
    }
    
    // Draw the timeline on top of everything
    [self drawTimelineBar];
}

- (void)drawBackgroundTrackAtTrackIndex:(int)trackIndex trackItemsTall:(int)trackItems
{
    // Draw the Track Background
    NSRect backgroundFrame = NSMakeRect(0, self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - trackItems * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT, self.frame.size.width, TRACK_ITEM_HEIGHT * trackItems);
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

- (void)drawAudioClipsAtTrackIndex:(int)trackIndex trackItemsTall:(int)trackItems
{
    trackItems = 1;
    
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    for(int i = 0; i < [data audioClipFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSMutableDictionary *currentAudioClip = [data audioClipFromFilePath:[data audioClipFilePathAtIndex:i forSequence:currentSequence]];
        
        // Check to see if this audioClip is in the visible range
        if(([data startTimeForAudioClip:currentAudioClip] > timeAtLeftEdge && [data startTimeForAudioClip:currentAudioClip] < timeAtRightEdge) || ([data endTimeForAudioClip:currentAudioClip] > timeAtLeftEdge && [data endTimeForAudioClip:currentAudioClip] < timeAtRightEdge) || ([data startTimeForAudioClip:currentAudioClip] <= timeAtLeftEdge && [data endTimeForAudioClip:currentAudioClip] >= timeAtRightEdge))
        {
            NSRect audioClipRect = NSMakeRect([data timeToX:[data startTimeForAudioClip:currentAudioClip]], self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - trackItems * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1, [data widthForTimeInterval:[data endTimeForAudioClip:currentAudioClip] - [data startTimeForAudioClip:currentAudioClip]], TRACK_ITEM_HEIGHT - 2);
            
            // AudioClip Mouse Checking here
            if((mouseAction == MNMouseDown || mouseAction == MNMouseDragged) && ([[NSBezierPath bezierPathWithRect:audioClipRect] containsPoint:mousePoint] && mouseEvent != nil))
            {
                [self drawRect:audioClipRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
                
                if(mouseAction == MNMouseDown)
                {
                    selectedAudioClip = currentAudioClip;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectAudioClip" object:selectedAudioClip];
                }
                else if(mouseAction == MNMouseDragged)
                {
                    [data moveAudioClip:currentAudioClip byTime:[data xToTime:[mouseEvent deltaX]]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                }
                
                mouseEvent = nil;
            }
            else
            {
                [self drawRect:audioClipRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.7] andStroke:YES];
                selectedAudioClip = nil;
            }
        }
        
        trackIndex++;
    }
}

- (void)drawControlBoxCommandClustersAtTrackIndex:(int)trackIndex trackItemsTall:(int)trackItems controlBoxIndex:(int)controlBoxIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    for(int i = 0; i < [data commandClusterFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSMutableDictionary *currentCommandCluster = [data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:i forSequence:currentSequence]];
        
        // Command Cluster is for this controlBox
        if([[data controlBoxFilePathForCommandCluster:currentCommandCluster] isEqualToString:[data controlBoxFilePathAtIndex:controlBoxIndex forSequence:currentSequence]])
        {
            // Check to see if this commandCluster is in the visible range
            if(([data startTimeForCommandCluster:currentCommandCluster] > timeAtLeftEdge && [data startTimeForCommandCluster:currentCommandCluster] < timeAtRightEdge) || ([data endTimeForCommandCluster:currentCommandCluster] > timeAtLeftEdge && [data endTimeForCommandCluster:currentCommandCluster] < timeAtRightEdge) || ([data startTimeForCommandCluster:currentCommandCluster] <= timeAtLeftEdge && [data endTimeForCommandCluster:currentCommandCluster] >= timeAtRightEdge))
            {
                NSRect commandClusterRect = NSMakeRect([data timeToX:[data startTimeForCommandCluster:currentCommandCluster]], self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - trackItems * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1, [data widthForTimeInterval:[data endTimeForCommandCluster:currentCommandCluster] - [data startTimeForCommandCluster:currentCommandCluster]], TRACK_ITEM_HEIGHT * trackItems - 2);
                
                // Command Cluster is selected
                if((mouseAction == MNMouseDown || mouseAction == MNMouseDragged) && ([[NSBezierPath bezierPathWithRect:commandClusterRect] containsPoint:mousePoint] && mouseEvent != nil))
                {
                    // Draw the commands first and check for mouse clicks
                    [self drawCommandsForCommandCluster:currentCommandCluster atTrackIndex:trackIndex trackItemsTall:trackItems forControlBoxOrChannelGroup:MNControlBox];
                    
                    // If a command didn't capture the mouse event, we use it
                    if(mouseEvent != nil)
                    {
                        [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
                        
                        if(mouseAction == MNMouseDown)
                        {
                            selectedCommandCluster = currentCommandCluster;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommandCluster" object:selectedCommandCluster];
                        }
                        else if(mouseAction == MNMouseDragged)
                        {
                            [data moveCommandCluster:currentCommandCluster byTime:[data xToTime:[mouseEvent deltaX]]];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                        }
                        
                        mouseEvent = nil;
                    }
                    // Else just draw normally
                    else
                    {
                        [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.0 alpha:0.7] andStroke:YES];
                        selectedCommandCluster = nil;
                    }
                }
                // Normal comand cluster
                else
                {
                    [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.0 alpha:0.7] andStroke:YES];
                    selectedCommandCluster = nil;
                    
                    // Draw the commands first and check for mouse clicks
                    [self drawCommandsForCommandCluster:currentCommandCluster atTrackIndex:trackIndex trackItemsTall:trackItems forControlBoxOrChannelGroup:MNControlBox];
                }
            }
        }
    }
}

- (void)drawChannelGroupCommandClustersAtTrackIndex:(int)trackIndex trackItemsTall:(int)trackItems channelGroupIndex:(int)channelGroupIndex
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    for(int i = 0; i < [data commandClusterFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSMutableDictionary *currentCommandCluster = [data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:i forSequence:currentSequence]];
        // Command Cluster is for this channelGroup
        if([[data channelGroupFilePathForCommandCluster:currentCommandCluster] isEqualToString:[data channelGroupFilePathAtIndex:channelGroupIndex forSequence:currentSequence]])
        {
            // Check to see if this commandCluster is in the visible range
            if(([data startTimeForCommandCluster:currentCommandCluster] > timeAtLeftEdge && [data startTimeForCommandCluster:currentCommandCluster] < timeAtRightEdge) || ([data endTimeForCommandCluster:currentCommandCluster] > timeAtLeftEdge && [data endTimeForCommandCluster:currentCommandCluster] < timeAtRightEdge) || ([data startTimeForCommandCluster:currentCommandCluster] <= timeAtLeftEdge && [data endTimeForCommandCluster:currentCommandCluster] >= timeAtRightEdge))
            {
                NSRect commandClusterRect = NSMakeRect([data timeToX:[data startTimeForCommandCluster:currentCommandCluster]], self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - trackItems * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1, [data widthForTimeInterval:[data endTimeForCommandCluster:currentCommandCluster] - [data startTimeForCommandCluster:currentCommandCluster]], TRACK_ITEM_HEIGHT * trackItems - 2);
                
                // Command Cluster Mouse Checking here
                if((mouseAction == MNMouseDown || mouseAction == MNMouseDragged) && ([[NSBezierPath bezierPathWithRect:commandClusterRect] containsPoint:mousePoint] && mouseEvent != nil))
                {
                    // Draw the commands first and check for mouse clicks
                    [self drawCommandsForCommandCluster:currentCommandCluster atTrackIndex:trackIndex trackItemsTall:trackItems forControlBoxOrChannelGroup:MNChannelGroup];
                    
                    // If a command didn't capture the mouse event, we use it
                    if(mouseEvent != nil)
                    {
                        [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
                        
                        if(mouseAction == MNMouseDown)
                        {
                            selectedCommandCluster = currentCommandCluster;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommandCluster" object:selectedCommandCluster];
                        }
                        else if(mouseAction == MNMouseDragged)
                        {
                            [data moveCommandCluster:currentCommandCluster byTime:[data xToTime:[mouseEvent deltaX]]];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                        }
                        
                        mouseEvent = nil;
                    }
                    // Just draw normally
                    else
                    {
                        [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.7] andStroke:YES];
                        selectedCommandCluster = nil;
                    }
                }
                else
                {
                    [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.7] andStroke:YES];
                    selectedCommandCluster = nil;
                    
                    // Draw the commands and check for mouse clicks
                    [self drawCommandsForCommandCluster:currentCommandCluster atTrackIndex:trackIndex trackItemsTall:trackItems forControlBoxOrChannelGroup:MNChannelGroup];
                }
            }
        }
    }
}

- (void)drawCommandsForCommandCluster:(NSMutableDictionary *)commandCluster atTrackIndex:(int)trackIndex trackItemsTall:(int)trackItems forControlBoxOrChannelGroup:(int)boxOrChannelGroup
{
    trackItems = 1;
    
    for(int i = 0; i < [data commandsCountForCommandCluster:commandCluster]; i ++)
    {
        NSMutableDictionary *currentCommand = [data commandAtIndex:i fromCommandCluster:commandCluster];
        
        NSRect commandRect;
        float x, y, width , height;
        x  = [data timeToX:[data startTimeForCommand:currentCommand]];
        y = self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - trackItems * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1;
        width = [data widthForTimeInterval:[data endTimeForCommand:currentCommand] - [data startTimeForCommand:currentCommand]];
        height = TRACK_ITEM_HEIGHT - 2;
        
        // Command extends over the end of it's parent cluster, bind it to the end of the parent cluster
        if([data endTimeForCommand:currentCommand] > [data endTimeForCommandCluster:commandCluster])
        {
            width = [data widthForTimeInterval:[data endTimeForCommandCluster:commandCluster] - [data startTimeForCommand:currentCommand]];
        }
        // Command extends over the beggining of it's parent cluster, bind it to the beginning of the parent cluster
        else if([data startTimeForCommand:currentCommand] < [data startTimeForCommandCluster:commandCluster])
        {
            x = [data timeToX:[data startTimeForCommandCluster:commandCluster]];
        }
        commandRect = NSMakeRect(x, y, width, height);
        
        // Command Mouse Checking Here
        if((mouseAction == MNMouseDown || mouseAction == MNMouseDragged) && ([[NSBezierPath bezierPathWithRect:commandRect] containsPoint:mousePoint] && mouseEvent != nil))
        {
            [self drawRect:commandRect withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
            
            if(mouseAction == MNMouseDown)
            {
                selectedCommand = currentCommand;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommand" object:[NSArray arrayWithObjects:currentCommand, commandCluster, nil]];
            }
            else if(mouseAction == MNMouseDragged)
            {
                [data moveCommandAtIndex:i byTime:[data xToTime:[mouseEvent deltaX]] whichIsPartOfCommandCluster:commandCluster];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
            }
            
            mouseEvent = nil;
        }
        else
        {
            [self drawRect:commandRect withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.2 green:0.2 blue:0.2 alpha:0.7] andStroke:YES];
            selectedCommand = nil;
        }
        
        // Used for drawing the channels
        trackIndex++;
    }
}

- (void)drawTimelineBar
{
    // Draw the Top Bar
    NSRect superViewFrame = [[self superview] frame];
    NSRect topBarFrame = NSMakeRect(0, scrollViewOrigin.y + superViewFrame.size.height - TOP_BAR_HEIGHT, self.frame.size.width, TOP_BAR_HEIGHT);
    NSSize imageSize = [topBarBackgroundImage size];
    [topBarBackgroundImage drawInRect:topBarFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    
    // Determine the grid spacing
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeMarkerDifference = 0.0;
    if(timeSpan >= 60.0)
    {
        timeMarkerDifference = 6.0;
    }
    else if(timeSpan >= 50.0)
    {
        timeMarkerDifference = 5.0;
    }
    else if(timeSpan >= 40.0)
    {
        timeMarkerDifference = 4.0;
    }
    else if(timeSpan >= 30.0)
    {
        timeMarkerDifference = 3.0;
    }
    else if(timeSpan >= 20.0)
    {
        timeMarkerDifference = 2.0;
    }
    else if(timeSpan >= 15.0)
    {
        timeMarkerDifference = 1.5;
    }
    else if(timeSpan >= 10.0)
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
    
    // Draw the grid (+ 5 extras so the user doesn't see blank areas)
    float leftEdgeNearestTimeMaker = [self roundUpNumber:[data timeAtLeftEdgeOfTimelineView] toNearestMultipleOfNumber:timeMarkerDifference];
	for(int i = 0; i < timeSpan / timeMarkerDifference + 6; i ++)
	{
        float timeMarker = (leftEdgeNearestTimeMaker - (timeMarkerDifference * 3) + i * timeMarkerDifference);
        // Draw the times
        NSString *time = [NSString stringWithFormat:@"%.02f", timeMarker];
        NSRect textFrame = NSMakeRect([data timeToX:timeMarker], topBarFrame.origin.y, 40, topBarFrame.size.height);
        [time drawInRect:textFrame withAttributes:attributes];
        
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect(textFrame.origin.x, scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor whiteColor] set];
        NSRectFill(markerLineFrame);
	}
    
    // Draw the currentTime marker
    NSPoint trianglePoint = NSMakePoint((float)[data timeToX:[data currentTime]], topBarFrame.origin.y);
    [self drawInvertedTriangleAndLineWithTipPoint:trianglePoint width:20 andHeight:20];
    
    // Mouse Checking
    if(mouseAction == MNMouseDragged && currentTimeMarkerIsSelected && mouseEvent != nil)
    {
        float newCurrentTime = [data xToTime:mousePoint.x];
        
        // Bind the minimum time to 0
        if(newCurrentTime < 0.0)
        {
            newCurrentTime = 0.0;
        }
        
        // Move the cursor to the new position
        [data setCurrentTime:newCurrentTime];
    }
    
    // TopBar Mouse Checking
    if([[NSBezierPath bezierPathWithRect:topBarFrame] containsPoint:mousePoint] && mouseAction == MNMouseDown && mouseEvent != nil && !currentTimeMarkerIsSelected)
    {
        [data setCurrentTime:[data xToTime:mousePoint.x]];
        mouseEvent = nil;
    }
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
        currentTimeMarkerIsSelected = YES;
        mouseEvent = nil;
    }
    else if(currentTimeMarkerIsSelected && mouseAction == MNMouseUp && mouseEvent != nil)
    {
        currentTimeMarkerIsSelected = NO;
        mouseEvent = nil;
    }
	
    // Set the color according to whether it is clicked or not
	if(!currentTimeMarkerIsSelected)
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
    BOOL didAutoscroll = [[self superview] autoscroll:mouseEvent];
    if(didAutoscroll)
    {
        [data setCurrentTime:[data xToTime:[data currentTime] + mouseEvent.deltaX]];
        [self setNeedsDisplay:YES];
    }
}

- (float)roundUpNumber:(float)numberToRound toNearestMultipleOfNumber:(float)multiple
{
    // Only works to the nearest thousandth
    int intNumberToRound = (int)(numberToRound * 1000000);
    int intMultiple = (int)(multiple * 1000000);
    
    if(multiple == 0)
    {
        return intNumberToRound / 1000000;
    }
    
    int remainder = intNumberToRound % intMultiple;
    if(remainder == 0)
    {
        return intNumberToRound / 1000000;
    }
    
    return (intNumberToRound + intMultiple - remainder) / 1000000.0;
}

#pragma mark Mouse Methods

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	mousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseDown;
    mouseEvent = theEvent;
    
    [autoScrollTimer invalidate];
    autoScrollTimer = nil;
    autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:AUTO_SCROLL_REFRESH_RATE target:self selector:@selector(updateTimeAtLeftEdgeOfTimelineView:) userInfo:nil repeats:YES];
    autoscrollTimerIsRunning = YES;
    
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
    
    [autoScrollTimer invalidate];
    autoScrollTimer = nil;
    autoscrollTimerIsRunning = NO;
    
    [self setNeedsDisplay:YES];
}



@end
