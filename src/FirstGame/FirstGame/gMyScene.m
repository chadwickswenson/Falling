//
//  gMyScene.m
//  FirstGame
//
//  Created by Chad Swenson on 2/11/14.
//  Copyright (c) 2014 Chad Swenson. All rights reserved.
//

#import "gMyScene.h"

static const uint32_t shipCategory =  0x1 << 0;
static const uint32_t obstacleCategory =  0x1 << 1;

static const float BG_VELOCITY = 150.0; //Velocity with which our background is going to move
static const float BLOCK_HEIGHT = 15.0;
static const float SIDE_SPEED = 4.0;

static inline CGPoint CGPointAdd(const CGPoint a, const CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a, const CGFloat b)
{
    return CGPointMake(a.x * b, a.y * b);
}

@implementation gMyScene{
    SKSpriteNode *ship;
    SKAction *actionMoveUp;
    SKAction *actionMoveDown;
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    NSTimeInterval _lastMissileAdded;
    float brickMoved;
    NSInteger numBricks;
    NSInteger score;
    SKLabelNode *labelScore;
    NSInteger leftBricksNum;
    NSInteger rightBricksNum;
    NSInteger whiteSpace;
    NSInteger whiteSpaceMin;
    NSInteger whiteSpaceMax;
    NSInteger whiteSpaceOffset;
    NSInteger whiteSpaceOffsetMin;
    NSInteger whiteSpaceOffsetMax;
    NSInteger numBrickNeeded;
    UIColor * colorGreen;
    UIColor * colorDarkGreen;
    UIColor * colorGreenBg;
}

-(id)initWithSize:(CGSize)size {
    
    if (self = [super initWithSize:size]) {
        brickMoved = 0;
        self.backgroundColor = [UIColor colorWithRed:160 green:97 blue:5 alpha:1];
        //[self initalizingScrollingBackground];
        [self addShip];
        //Making self delegate of physics World
        self.physicsWorld.gravity = CGVectorMake(0,0);
        self.physicsWorld.contactDelegate = self;
    }
    
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    
    screenWidth = screenSize.width;
    screenHeight = screenSize.height;
    numBrickNeeded = screenWidth/BLOCK_HEIGHT;
    numBricks = 8;
    score = 0;
    leftBricksNum = 0;
    rightBricksNum = 0;
    whiteSpace = numBrickNeeded/(2);
    whiteSpaceMin = whiteSpace - (numBrickNeeded / 6) + 5;
    whiteSpaceMax = whiteSpace + (numBrickNeeded / 10);
    whiteSpaceOffset = numBrickNeeded/(3);
    whiteSpaceOffsetMin = 0;
    whiteSpaceOffsetMax = numBrickNeeded - whiteSpaceMax;
    labelScore = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    labelScore.text = @"score";
    labelScore.zPosition = 10;
    labelScore.fontSize = 40;
    labelScore.fontColor = [SKColor blackColor];
    labelScore.position = CGPointMake(self.size.width/2, 30);
    
    //assign colors
    colorGreen = [UIColor colorWithRed:39.0f/255.0f green:197.0f/255.0f blue:165.0f/255.0f alpha:1.0f];
    colorDarkGreen = [UIColor colorWithRed:33.0f/255.0f green:168.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
    colorGreenBg = [UIColor colorWithRed:184.0f/255.0f green:223.0f/255.0f blue:215.0f/255.0f alpha:1.0f];
    [self addBrickRow];
    [self addChild:labelScore];
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = .2;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 [self outputAccelertionData:accelerometerData.acceleration];
                                                 if(error)
                                                 {
                                                     NSLog(@"%@", error);
                                                 }
    }];
    
    return self;
}



-(void)addShip
{
    //initalizing spaceship node
    ship = [SKSpriteNode new];
    ship = [SKSpriteNode spriteNodeWithImageNamed:@"monkey4"];
    [ship setScale:0.2];
    ship.zRotation = - M_PI / 2;
    
    //Adding SpriteKit physicsBody for collision detection
    ship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ship.size];
    ship.physicsBody.categoryBitMask = shipCategory;
    ship.physicsBody.dynamic = YES;
    ship.physicsBody.contactTestBitMask = obstacleCategory;
    ship.physicsBody.collisionBitMask = 0;
    ship.name = @"ship";
    ship.position = CGPointMake(120,500);
    ship.physicsBody.mass = 3000.00;
    [self addChild:ship];
    
    actionMoveUp = [SKAction moveByX:0 y:30 duration:.2];
    actionMoveDown = [SKAction moveByX:0 y:-30 duration:.2];
    
    /*SKSpriteNode * brick = [SKSpriteNode new];
    brick = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(50.0,50.0)];
    brick.physicsBody.categoryBitMask = shipCategory;
    brick.physicsBody.dynamic = YES;
    brick.physicsBody.contactTestBitMask = obstacleCategory;
    brick.physicsBody.collisionBitMask = 0;
    brick.name = @"brick";
    brick.position = CGPointMake(20,100);
    
    [self addChild:brick];*/

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

-(void)initalizingScrollingBackground
{
    for (int i = 0; i < 2; i++) {
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"redbg"];
        bg.position = CGPointMake(0, -i * bg.size.height);
        bg.anchorPoint = CGPointZero;
        bg.name = @"bg";
        [self addChild:bg];
    }
    
}

- (void)moveBg
{
    [self enumerateChildNodesWithName:@"bg" usingBlock: ^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode * bg = (SKSpriteNode *) node;
         CGPoint bgVelocity = CGPointMake(0, BG_VELOCITY);
         CGPoint amtToMove = CGPointMultiplyScalar(bgVelocity,_dt);
         bg.position = CGPointAdd(amtToMove, bg.position);
         
         //Checks if bg node is completely scrolled of the screen, if yes then put it at the end of the other node
         //NSLog(@"%f",bg.position.y);

         if (bg.position.y > bg.size.height)
         {
             bg.position = CGPointMake(bg.position.x, -bg.size.height+2 );
         }
     }];
}

- (void)moveBricks
{
    __block NSInteger x2 = 0;
    
    [self enumerateChildNodesWithName:@"brick" usingBlock: ^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode * b = (SKSpriteNode *) node;
         CGPoint bgVelocity = CGPointMake(0, BG_VELOCITY);
         CGPoint amtToMove = CGPointMultiplyScalar(bgVelocity,_dt);
         
         if(x2 == 0){
             brickMoved += amtToMove.y;
         }
         
         x2 = 1;
         
         
         b.position = CGPointAdd(amtToMove, b.position);
         
         if(b.position.y > screenHeight+10){
             [b removeFromParent];
         }
     }];
    //NSLog(@"%f",brickMoved);
}

- (void)addBrickRow{
    //take the current whitespace ammount and modify it by random amount within limits
    UIColor * primary;
    UIColor * bg;
    NSInteger brickColorRandom = arc4random()%5;
    if(1 == 1){
        primary = colorGreen;
        bg = colorGreenBg;
    }
    if(brickColorRandom == 2){
        primary = colorDarkGreen;
    }
    
    self.backgroundColor = bg;
    
    if (whiteSpace > whiteSpaceMin && whiteSpace < whiteSpaceMax) {
        whiteSpace += arc4random()%5 - 2;
    } else if (whiteSpace >= whiteSpaceMax)
    {
        whiteSpace -= arc4random()%2;
    } else if (whiteSpace <= whiteSpaceMin)
    {
        whiteSpace += arc4random()%2;
    } else
    {
        NSLog(@"Whitespace error");
    }
    
    //change the whitespace left offset by a random amount within limits
    if (whiteSpaceOffset > whiteSpaceOffsetMin && whiteSpaceOffset < whiteSpaceOffsetMax) {
        whiteSpaceOffset += arc4random()%5 - 2;
    } else if (whiteSpaceOffset >= whiteSpaceOffsetMax)
    {
        whiteSpaceOffset -= arc4random()%2;
    }
    else if (whiteSpaceOffset <= whiteSpaceOffsetMin){
        whiteSpaceOffset += arc4random()%2;
    }
    else {
        NSLog(@"White space offset error");
    }
    
        
    NSInteger leftBrickWidth = whiteSpaceOffset*BLOCK_HEIGHT;
    NSInteger rightBrickWidth = (numBrickNeeded - (whiteSpaceOffset + whiteSpace))*BLOCK_HEIGHT;
    
    if (leftBrickWidth < BLOCK_HEIGHT) {
        leftBrickWidth = BLOCK_HEIGHT;
    }
    if (rightBrickWidth < BLOCK_HEIGHT) {
        rightBrickWidth = BLOCK_HEIGHT;
    }
    
    SKSpriteNode * brick = [SKSpriteNode spriteNodeWithColor:primary size:CGSizeMake(leftBrickWidth,BLOCK_HEIGHT)];
    [self addChild:brick];
    
    
    brick.physicsBody.categoryBitMask = obstacleCategory;
    brick.physicsBody.dynamic = NO;
    //brick.physicsBody.static = NO;
    brick.physicsBody.contactTestBitMask = obstacleCategory;
    brick.physicsBody.collisionBitMask = 0;
    brick.name = @"brick";
    brick.position = CGPointMake(leftBrickWidth/2,-BLOCK_HEIGHT);
    brick.zPosition = 3;
    brick.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(leftBrickWidth,BLOCK_HEIGHT)];
    //brick.physicsBody.usesPreciseCollisionDetection = YES;
    
    
    SKSpriteNode * rightBrick = [SKSpriteNode spriteNodeWithColor:primary size:CGSizeMake(rightBrickWidth,BLOCK_HEIGHT)];
    [self addChild:rightBrick];
    
    
    rightBrick.physicsBody.categoryBitMask = obstacleCategory;
    rightBrick.physicsBody.dynamic = NO;
    rightBrick.physicsBody.contactTestBitMask = obstacleCategory;
    rightBrick.physicsBody.collisionBitMask = 0;
    rightBrick.name = @"brick";
    rightBrick.position = CGPointMake(screenWidth - rightBrickWidth/2,-BLOCK_HEIGHT);
    rightBrick.zPosition = 3;
    rightBrick.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(rightBrickWidth,BLOCK_HEIGHT)];
    //brick.physicsBody.usesPreciseCollisionDetection = YES;
    
    
}

-(void)update:(CFTimeInterval)currentTime {
    
    /* Called before each frame is rendered */
    
    //NSLog(@"%f",_dt);
    
    if (_lastUpdateTime)
    {
        _dt = currentTime - _lastUpdateTime;
    }
    else
    {
        _dt = 0;
    }
    
    if(brickMoved >= BLOCK_HEIGHT-5){
        brickMoved = 0;
        [self addBrickRow];
        score++;
        labelScore.text = [NSString stringWithFormat:@"%d",score];
    }
    
    _lastUpdateTime = currentTime;
    
    //[self moveBg];
    [self moveBricks];
    
    float maxY = screenWidth - ship.size.width/4;
    float minY = ship.size.width/4;
    
    
    float maxX = screenHeight - ship.size.height/4;
    float minX = ship.size.height/4;
    
    float newY = 0;
    float newX = 0;
    
    if(currentMaxAccelX > 0.05){
        newX = currentMaxAccelX * 1;
        //_plane.texture = [SKTexture textureWithImageNamed:@"PLANE 8 R.png"];
    }
    else if(currentMaxAccelX < -0.05){
        newX = currentMaxAccelX*1;
        //_plane.texture = [SKTexture textureWithImageNamed:@"PLANE 8 L.png"];
    }
    else{
        newX = currentMaxAccelX*1;
        //_plane.texture = [SKTexture textureWithImageNamed:@"PLANE 8 N.png"];
    }
    
    newY =  currentMaxAccelY * 0.01;
    
    newX = MIN(MAX(newX+ship.position.x,minY),maxY);
    newY = MIN(MAX(newY+ship.position.y,minX),maxX);
    
    float dz = 0.1;
    float c = 0.02;
    
    if(currentMaxAccelX < dz && currentMaxAccelX > -dz){
        if(ship.zRotation < -1.5){
            ship.zRotation += c;
        }
        else if(ship.zRotation > -1.5){
            ship.zRotation -= c;
        }
    }
    else if(currentMaxAccelX > dz && ship.zRotation < 0){
        ship.zRotation = ship.zRotation + 0.1 * currentMaxAccelX;
    }
    else if(currentMaxAccelX < -dz && ship.zRotation > -3){
        ship.zRotation = ship.zRotation + (0.1 * currentMaxAccelX);
    }
    
    float speedX = 0;
    
    if(ship.zRotation < -1.5){
        speedX = ((ship.zRotation+1.5)/3) * SIDE_SPEED;
    }
    else{
        speedX = ((ship.zRotation+1.5)/1.5) * SIDE_SPEED;
    }
    //NSLog(@"%f",speedX);
    
    ship.position = CGPointMake(ship.position.x + speedX, ship.position.y);

}

-(void)outputAccelertionData:(CMAcceleration)acceleration
{
    currentMaxAccelX = 0;
    currentMaxAccelY = 0;
    
    if(fabs(acceleration.x) > fabs(currentMaxAccelX))
    {
        currentMaxAccelX = acceleration.x;
    }
    if(fabs(acceleration.y) > fabs(currentMaxAccelY))
    {
        currentMaxAccelY = acceleration.y;
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if ((firstBody.categoryBitMask & shipCategory) != 0 &&
        (secondBody.categoryBitMask & obstacleCategory) != 0)
    {
        score = 0;
        labelScore.text = [NSString stringWithFormat:@"%d",score];
    }
}

@end
