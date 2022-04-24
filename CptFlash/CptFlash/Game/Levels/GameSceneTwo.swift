//
//  GameSceneTwo.swift
//  CptFlash
//
//  Created by James Murphy on 23/04/2022.
//

import SpriteKit
import GameplayKit
import CoreMotion
import GameKit


@objcMembers
class GameSceneTwo: SKScene, SKPhysicsContactDelegate {
    
    //To store removed nodes before update removes
    private var trash:[SKNode] = []
    
    //Player Image
    let player = SKSpriteNode(imageNamed: "Player.png")
    
    let leaderboardID = "com.fyp.flash_leaders"
    
    //Enemy Sprites
    var enemy1 = SKSpriteNode()
    var enemy2 = SKSpriteNode()
    var enemy3 = SKSpriteNode()
    var enemyLaser = SKSpriteNode()
    
    //Boss Sprite
    var boss = SKSpriteNode()
    var bossLaser = SKSpriteNode()
    
    //Boss Health
    var bossHealth = 50
    static var bossIsDead: Bool = false
    
    //Invincibilty
    var invincible = false
    
    //Timers
    var bossTimer = Timer()
    var astroidTimer:Timer!
    var bossFiringTimer = Timer()
    
    //Array for different astroids
    var astroidArray = ["astroid1", "astroid2"]
    
    //For collision
    let playerCategory:UInt32 = 0x1 << 1
    let playerLaserCategory:UInt32 = 0x1 << 2
    let shieldPickupCategory:UInt32 = 0x1 << 3
    let lifePickupCategory:UInt32 = 0x1 << 4
    let weaponPickupCategory:UInt32 = 0x1 << 5
    let astroidCategory:UInt32 = 0x1 << 6
    let enemyCategory:UInt32 = 0x1 << 7
    let bossCategory:UInt32 = 0x1 << 8
    let enemyLaserCategory:UInt32 = 0x1 << 9
    
    //Weapons
    var laser1: Bool = true
    var laser2: Bool = false
    
    //Score Label
    var scoreLabel:SKLabelNode!
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    //Moving player with Accelometer
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    //var yAcceleration:CGFloat = 0
    
    //Create Music
    let music = SKAudioNode(fileNamed: "Level3.mp3")
    
    
    override func didMove(to view: SKView) {
        
        //Create and position background
        let background = SKSpriteNode(imageNamed: "Space_BG_03.png")
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
        player.position = CGPoint(x: 0, y: -400)
        player.zPosition = 1
        addChild(player)
        
        //Player Physics for collision
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = astroidCategory | enemyCategory | bossCategory | shieldPickupCategory | lifePickupCategory | enemyLaserCategory
        //avoid any unwanted collisions
        player.physicsBody?.collisionBitMask = 0
        
        //Physics for World
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        //Score Label
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: -300, y: 525)
        scoreLabel.fontName = "Symbol"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = UIColor.white
        score = GameScene.score
        addChild(scoreLabel)
        
        //Adding music
        addChild(music)
        
    }
}
