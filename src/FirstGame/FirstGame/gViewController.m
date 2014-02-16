//
//  gViewController.m
//  FirstGame
//
//  Created by Chad Swenson on 2/11/14.
//  Copyright (c) 2014 Chad Swenson. All rights reserved.
//

#import "gViewController.h"
#import "gMyScene.h"

@implementation gViewController

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    
    SKView * skView = (SKView *)self.view;
    
    if (!skView.scene) {
        skView.showsFPS = YES;
        skView.showsNodeCount = YES;
        
        // Create and configure the scene.
        SKScene * scene = [gMyScene sceneWithSize:skView.bounds.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        
        // Present the scene.
        [skView presentScene:scene];
    }
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

@end
