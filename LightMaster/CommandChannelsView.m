//
//  CommandChannelsView.m
//  LightMaster
//
//  Created by James Adams on 12/24/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import "CommandChannelsView.h"

@implementation CommandChannelsView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Custom initialization code here
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [[NSColor greenColor] set];
    NSRectFill([self bounds]);
}

@end
