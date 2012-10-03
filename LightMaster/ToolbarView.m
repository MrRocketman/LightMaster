//
//  ToolbarView.m
//  LightMaster
//
//  Created by James Adams on 12/14/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import "ToolbarView.h"

@implementation ToolbarView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        // Initialization code here.
        backgroundImage = [NSImage imageNamed:@"Toolbar.tiff"];
        
        [self setNeedsDisplay:YES];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    NSSize imageSize = [backgroundImage size];
    [backgroundImage drawInRect:[self bounds] fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation: NSCompositeCopy fraction:1.0];
}

@end
