//
//  gMyScene.h
//  FirstGame
//

//  Copyright (c) 2014 Chad Swenson. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <CoreMotion/CoreMotion.h>

@interface gMyScene : SKScene <SKPhysicsContactDelegate>{
    CGRect screenRect;
    CGFloat screenHeight;
    CGFloat screenWidth;
    double currentMaxAccelX;
    double currentMaxAccelY;
    
}

@property (strong, nonatomic) CMMotionManager *motionManager;

@end
