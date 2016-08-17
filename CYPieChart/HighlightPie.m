//
//  HighlightPie.m
//  TrackDown
//
//  Created by Gocy on 16/8/12.
//  Copyright © 2016年 Gocy. All rights reserved.
//

#import "HighlightPie.h"

@implementation HighlightPie



-(void)awakeFromNib{
    [self initialize];
}

-(instancetype)init{
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}


-(void)initialize{
    
    self.layer.shadowOpacity = 0.6;
    self.layer.shadowOffset = CGSizeMake(0, 6);
    self.backgroundColor = [UIColor clearColor];
}
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    if (self.path && self.fillColor) {
        [self.fillColor setFill];
        [self.path fill];
        
        if (self.borderColor && self.borderWidth > 0) {
            [self.borderColor setStroke];
            self.path.lineWidth = self.borderWidth;
            [self.path stroke];
        }
    }
    self.layer.shadowPath = self.path.CGPath;
}



@end
