//
//  GameScene.swift
//  CptFlash
//
//  Created by James Murphy on 17/11/2021.
// Exposion sound effect: Explosion, 8-bit, 01.wav By: InspectorJ Website: https://freesound.org/people/InspectorJ/sounds/448226/
//
// Laser Sound effect: Title: Laser00.wav, By: sharesynth, Website: https://freesound.org/people/sharesynth/sounds/341236/

import SpriteKit
import GameplayKit

@objcMembers
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Player Image
    let player = SKSpriteNode(imageNamed: "Player.png")
    
    //Score Label
    var scoreLabel:SKLabelNode!
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    //Timer to spawn enemies
    var gameTimer:Timer!
    
    //Array for different astroids
    var astroidArray = ["astroid1", "astroid2"]
    
    //For collision
    let astroidCategory:UInt32 = 0x1 << 1
    let playerLaserCategory:UInt32 = 0x1 << 0
    
    //Moving player by touch
    var touchingPlayer = false
    
    
    override func didMove(to view: SKView) {
        
        //Create and position background
        let background = SKSpriteNode(imageNamed: "Space_BG_01.png")
        background.zPosition = -2
        addChild(background)
        
        //Create and position Starfield
        if let starfield = SKEmitterNode(fileNamed: "Starfield") {
            starfield.position.y = 1472
            starfield.advanceSimulationTime(20)
            starfield.zPosition = -1
            addChild(starfield)
        }
        
        //Position Player
        player.position.y = -400
        player.zPosition = 1
        addChild(player)
        
        //Physics for World
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        //Score Label
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: -300, y: 525)
        scoreLabel.fontName = "Symbol"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.white
        score = 0
        addChild(scoreLabel)
        
        //Timer to spawn astroids
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAstroid), userInfo: nil, repeats: true)
        
    }
    
    func addAstroid() {
        astroidArray = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: astroidArray) as! [String]
        
        //Select astroid from array
        let astroid = SKSpriteNode(imageNamed: astroidArray[0])
        
        //GameplayKit randomization services to spawn different astroids
        let randomAstroidPosition = GKRandomDistribution(lowestValue: -350, highestValue: 350)
        //Randomly spawn astroid in differnet positions
        let position = CGFloat(randomAstroidPosition.nextInt())
        astroid.position = CGPoint(x: position, y: self.frame.size.height + astroid.size.height)
        
        //Astroid Physics for collision
        astroid.physicsBody = SKPhysicsBody(rectangleOf: astroid.size)
        astroid.physicsBody?.isDynamic = true
        
        astroid.physicsBody?.categoryBitMask = astroidCategory
        astroid.physicsBody?.contactTestBitMask = playerLaserCategory
        astroid.physicsBody?.collisionBitMask = 0
        
        addChild(astroid)
        
        //Astroid speed
        let animationDuration:TimeInterval = 6
        
        //Clean up, remove astroids once reached a certain distince
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -700), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        astroid.run(SKAction.sequence(actionArray))
        
    }
    
    func fireLaser() {
        
        //Sound effect
        self.run(SKAction.playSoundFileNamed("laser.wav", waitForCompletion: false))
        
        //Create and position laser
        let playerLaser = SKSpriteNode(imageNamed: "laser")
        playerLaser.position = player.position
        playerLaser.position.y += 5
        
        //Laser Physics
        playerLaser.physicsBody = SKPhysicsBody(circleOfRadius: playerLaser.size.width / 2)
        playerLaser.physicsBody?.isDynamic = true
        
        playerLaser.physicsBody?.categoryBitMask = playerLaserCategory
        playerLaser.physicsBody?.contactTestBitMask = astroidCategory
        playerLaser.physicsBody?.collisionBitMask = 0
        playerLaser.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(playerLaser)
        
        //Animation for laser firing
        let animationDuration:TimeInterval = 0.3
        
        //Clean up, removes laser blast from game
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        playerLaser.run(SKAction.sequence(actionArray))
    }
    
    //Function for physics to know what object hit what
    func didBegin(_ contact: SKPhysicsContact) {
        var A:SKPhysicsBody
        var B:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            A = contact.bodyA
            B = contact.bodyB
        } else {
            A = contact.bodyB
            B = contact.bodyA
        }
        
        //PlayerLaser is A and Astroid is B
        if (A.categoryBitMask & playerLaserCategory) != 0 && (B.categoryBitMask & astroidCategory) != 0 {
            playerLaserDidCollide(laserNode: A.node as! SKSpriteNode, astroidNode: B.node as! SKSpriteNode)
        }
    }
    
    //Function for playerLaser to destroy what it hits
    func playerLaserDidCollide (laserNode:SKSpriteNode, astroidNode:SKSpriteNode) {
        
        //Create explosion effect
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = astroidNode.position
        addChild(explosion)
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        laserNode.removeFromParent()
        astroidNode.removeFromParent()
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        
        //Add score
        score += 5
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
        //Moving player by touch
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        
        if tappedNodes.contains(player) {
            touchingPlayer = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        //Move player by touch or drag the player around the screen
        guard touchingPlayer else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        player.position = location
 
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireLaser()
        
        //Stop moving player when released
        touchingPlayer = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
}
