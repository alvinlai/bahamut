//
//  SDVolumeSliderCell.m
//  Bahamut
//
//  Created by Steven on 8/25/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "SDVolumeSliderCell.h"

#import "SDColors.h"

@implementation SDVolumeSliderCell

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped {
    aRect = NSInsetRect(aRect, 0.0, 1.0);
    CGFloat r = 2.0;
    
    [[NSColor colorWithCalibratedWhite:1.00 alpha:1.0] setFill];
    [[NSBezierPath bezierPathWithRoundedRect:aRect xRadius:r yRadius:r] fill];
}

- (void)drawKnob:(NSRect)knobRect {
    knobRect = NSInsetRect(knobRect, 3.0, 8.0);
    
    CGFloat r = 0.0;
    
    [SDVolumeSliderForeColor setFill];
    [[NSBezierPath bezierPathWithRoundedRect:knobRect xRadius:r yRadius:r] fill];
}

//- (NSRect)knobRectFlipped:(BOOL)flipped {
//    NSRect r = [super knobRectFlipped:flipped];
//    r.size.width /= 2.0;
//    r.origin.x += r.size.width / 2.0;
//    return r;
//}

@end
