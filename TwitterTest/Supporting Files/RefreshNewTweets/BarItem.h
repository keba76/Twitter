//
//  BarItem.h
//  TwitterTest
//
//  Created by Ievgen Keba on 4/7/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BarItem : UIView

@property (nonatomic) CGFloat translationX;

- (instancetype)initWithFrame:(CGRect)frame startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint color:(UIColor *)color lineWidth:(CGFloat)lineWidth;
- (void)setupWithFrame:(CGRect)rect;
- (void)setHorizontalRandomness:(int)horizontalRandomness dropHeight:(CGFloat)dropHeight;

@end
