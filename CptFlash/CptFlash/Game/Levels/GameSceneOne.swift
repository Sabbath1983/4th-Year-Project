//
//  GameSceneOne.swift
//  CptFlash
//
//  Created by James Murphy on 23/04/2022.
//

import SpriteKit
import GameplayKit
import CoreMotion
import GameKit


@objcMembers
class GameSceneOne: SKScene, SKPhysicsContactDelegate {
    
    //To store removed nodes before update removes
    private var trash:[SKNode] = []
    
    //Player Image
    let player = SKSpriteNode(imageNamed: "Player.png")
    
    //Leaderboard for Game Center
    let leaderboardID = "com.fyp.flash_leaders"
    
    //Enemy Sprites
    var enemy1 = SKSpriteNode()
    var enemy2 = SKSpriteNode()
    var enemy3 = SKSpriteNode()
    var enemyLaser = SKSpriteNode()
    
    //Boss Sprite and its laser sprite
    var boss = SKSpriteNode()
    var bossLaser = SKSpriteNode()
    
    //Boss Health
    var bossHealth = 50
    static var bossIsDead: Bool = false
    
    //Invincibilty
    var invincible = false
    
    //Weapons
    var laser1: Bool = true
    var laser2: Bool = false
    
    //Score Label
    static var scoreLabel:SKLabelNode!
    static var score:Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    //lives label
    static var livesLabel:SKLabelNode!
    static var numLives:Int = 0 {
        didSet {
            livesLabel.text = "Lives: \(numLives)"
        }
    }
    
    //Timers
    var bossTimer = Timer()
    var astroidTimer:Timer!
    var bossFiringTimer = Timer()
    
    //Array for different asteroid sprites
    var astroidArray = ["astroid1", "astroid2"]
    
    //For collision, assigns each object its ID
    let playerCategory:UInt32 = 0x1 << 1
    let playerLaserCategory:UInt32 = 0x1 << 2
    let shieldPickupCategory:UInt32 = 0x1 << 3
    let lifePickupCategory:UInt32 = 0x1 << 4
    let weaponPickupCategory:UInt32 = 0x1 << 5
    let astroidCategory:UInt32 = 0x1 << 6
    let enemyCategory:UInt32 = 0x1 << 7
    let bossCategory:UInt32 = 0x1 << 8
    let enemyLaserCategory:UInt32 = 0x1 << 9
    
    //Setting up movement for the player with the Accelometer
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    //var yAcceleration:CGFloat = 0
    
    //Create Music for the level
    let music = SKAudioNode(fileNamed: "Retro.mp3")
    
    override func didMove(to view: SKView) {
        
        //Create and position background
        let background = SKSpriteNode(imageNamed: "Space_BG_02.png")
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
        GameSceneOne.scoreLabel = SKLabelNode(text: "Score: 0")
        GameSceneOne.scoreLabel.position = CGPoint(x: -300, y: 525)
        GameSceneOne.scoreLabel.fontName = "Symbol"
        GameSceneOne.scoreLabel.fontSize = 28
        GameSceneOne.scoreLabel.fontColor = UIColor.white
        GameSceneOne.score = GameScene.score
        addChild(GameSceneOne.scoreLabel)
        
        //Lives Label
        GameSceneOne.livesLabel = SKLabelNode(text: "Lives: 0")
        GameSceneOne.livesLabel.position = CGPoint(x: 300, y: 525)
        GameSceneOne.livesLabel.fontName = "Symbol"
        GameSceneOne.livesLabel.fontSize = 28
        GameSceneOne.livesLabel.fontColor = UIColor.white
        GameSceneOne.numLives = GameScene.numLives
        addChild(GameSceneOne.livesLabel)
        
        //Timer to spawn astroids, calls fuction after amount of time
        astroidTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(addAstroid), userInfo: nil, repeats: true)
        

        //Timer to spawn Boss, calls function after amount of time
        bossTimer = Timer.scheduledTimer(timeInterval: 80.0, target: self, selector: #selector(addBoss), userInfo: nil, repeats: false)

        //Spawn Invinabilty pickup, starts the SKAction
        run(SKAction.repeatForever(
          SKAction.sequence([SKAction.run() { [weak self] in
                              self?.addInvincablityPickup()
                            },
          SKAction.wait(forDuration: 33.0)])))

        //Spawn Weapon pickup, starts the SKAction
        run(SKAction.repeatForever(
          SKAction.sequence([SKAction.run() { [weak self] in
                              self?.addWeaponPickup()
                            },
          SKAction.wait(forDuration: 21.0)])))
        
        //Spawn Life pickup, starts the SKAction
        run(SKAction.repeatForever(
          SKAction.sequence([SKAction.run() { [weak self] in
                              self?.addExtraLifePickup()
                            },
          SKAction.wait(forDuration: 47.0)])))


        //Spawn Enemy1, starts the SKAction
        run(SKAction.repeatForever(
          SKAction.sequence([SKAction.run() { [weak self] in
                              self?.addEnemy1()
                            },
                            SKAction.wait(forDuration: 4.0)])), withKey:"enemy1")

        //Spawn Enemy2, starts the SKAction
        run(SKAction.repeatForever(
          SKAction.sequence([SKAction.run() { [weak self] in
                              self?.addEnemy2()
                            },
                            SKAction.wait(forDuration: 5.0)])), withKey:"enemy2")

        //Spawn Enemy3, starts the SKAction
        run(SKAction.repeatForever(
          SKAction.sequence([SKAction.run() { [weak self] in
                              self?.addEnemy3()
                            },
                            SKAction.wait(forDuration: 6.0)])), withKey:"enemy3")
                
        
        //Using Accelometer for movement
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
        
        //Adding music
        addChild(music)
    }
    
    func addWeaponPickup() {
        //Weapon Pickup Image
        let weaponPickUp = SKSpriteNode(imageNamed: "WeaponsPickup.png")
        
        // Spawn weapon pickup off screen randomly and add to scene
        weaponPickUp.position = CGPoint(
            x:CGFloat.random(
                min: frame.minX + weaponPickUp.size.width/2,
                max: frame.maxX - weaponPickUp.size.width/2),
            y:size.height + weaponPickUp.size.height/2)
        
        addChild(weaponPickUp)
        weaponPickUp.zPosition = 1
        
        //Create SKAction commands to dealy object entering screen, its postions to move to and then remove if final destiantion has been reached
        let delay = SKAction.wait(forDuration: 21)
        let actionMove = SKAction.moveTo(y: -600, duration: 5.0)
        let actionRemove = SKAction.removeFromParent()
        weaponPickUp.run(SKAction.sequence([delay, actionMove, actionRemove]))
        
        //Weapon Pickup Physics for collision
        weaponPickUp.physicsBody = SKPhysicsBody(circleOfRadius: weaponPickUp.size.width / 2)
        weaponPickUp.physicsBody?.isDynamic = true
        
        //Set category for object and what its can collide with
        weaponPickUp.physicsBody?.categoryBitMask = weaponPickupCategory
        weaponPickUp.physicsBody?.contactTestBitMask = playerCategory
        
        //avoid any unwanted collisions
        weaponPickUp.physicsBody?.collisionBitMask = 0
    }
    
    func addInvincablityPickup() {
        //Shield Pickup Image
        let shieldPickUp = SKSpriteNode(imageNamed: "ShieldPickup.png")
        // Spawn shield pickup off screen randomly and add to scene
        shieldPickUp.position = CGPoint(
            x:CGFloat.random(
                min: frame.minX + shieldPickUp.size.width/2,
                max: frame.maxX - shieldPickUp.size.width/2),
            y:size.height + shieldPickUp.size.height/2)
        
        addChild(shieldPickUp)
        shieldPickUp.zPosition = 1
        
        //Create SKAction commands to dealy object entering screen, its postions to move to and then remove if final destiantion has been reached
        let delay = SKAction.wait(forDuration: 33)
        let actionMove = SKAction.moveTo(y: -600, duration: 5.0)
        let actionRemove = SKAction.removeFromParent()
        shieldPickUp.run(SKAction.sequence([delay, actionMove, actionRemove]))
        
        //Shield PickUp Physics for collision
        shieldPickUp.physicsBody = SKPhysicsBody(circleOfRadius: shieldPickUp.size.width / 2)
        shieldPickUp.physicsBody?.isDynamic = true
        
        //Set category for object and what its can collide with
        shieldPickUp.physicsBody?.categoryBitMask = shieldPickupCategory
        shieldPickUp.physicsBody?.contactTestBitMask = playerCategory
        
        //avoid any unwanted collisions
        shieldPickUp.physicsBody?.collisionBitMask = 0
    }
    
    func addExtraLifePickup() {
        //Extra Life Pickup Image
        let lifePickUp = SKSpriteNode(imageNamed: "LifePickup.png")
        
        // Spawn life pickup off screen randomly and add to scene
        lifePickUp.position = CGPoint(
            x:CGFloat.random(
                min: frame.minX + lifePickUp.size.width/2,
                max: frame.maxX - lifePickUp.size.width/2),
            y:size.height + lifePickUp.size.height/2)
        
        addChild(lifePickUp)
        lifePickUp.zPosition = 1
        
        //Create SKAction commands to dealy object entering screen, its postions to move to and then remove if final destiantion has been reached
        let delay = SKAction.wait(forDuration: 47)
        let actionMove = SKAction.moveTo(y: -600, duration: 5.0)
        let actionRemove = SKAction.removeFromParent()
        lifePickUp.run(SKAction.sequence([delay, actionMove, actionRemove]))
        
        //Life PickUp Physics for collision
        lifePickUp.physicsBody = SKPhysicsBody(circleOfRadius: lifePickUp.size.width / 2)
        lifePickUp.physicsBody?.isDynamic = true
        
        //Set category for object and what its can collide with
        lifePickUp.physicsBody?.categoryBitMask = lifePickupCategory
        lifePickUp.physicsBody?.contactTestBitMask = playerCategory
        
        //avoid any unwanted collisions
        lifePickUp.physicsBody?.collisionBitMask = 0
    }
    
    func addAstroid() {
        // Randonly select astroid image from the array using GameplayKit randomization services
        astroidArray = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: astroidArray) as! [String]
        
        //Create the astroid object from the array
        let astroid = SKSpriteNode(imageNamed: astroidArray[0])
        
        //Randomly spawn astroid in differnet positions
        let randomAstroidPosition = GKRandomDistribution(lowestValue: -350, highestValue: 350)
        let position = CGFloat(randomAstroidPosition.nextInt())
        astroid.position = CGPoint(x: position, y: self.frame.size.height + astroid.size.height)
        
        astroid.zPosition = 1
        
        //Astroid Physics for collision
        astroid.physicsBody = SKPhysicsBody(circleOfRadius: astroid.size.width / 2)
        astroid.physicsBody?.isDynamic = true
        
        //Set category for object and what its can collide with
        astroid.physicsBody?.categoryBitMask = astroidCategory
        astroid.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        
        //avoid any unwanted collisions
        astroid.physicsBody?.collisionBitMask = 0
        
        addChild(astroid)
        
        //Astroid speed or how fast it moves down the screen
        let animationDuration:TimeInterval = 6
        
        //Create SKAction commands to move the astroid and then remove if final destiantion has been reached
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -700), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        astroid.run(SKAction.sequence(actionArray))
    }
    
    func addEnemy1() {
        
        //Enemy1 Image
        enemy1 = .init(imageNamed: "Enemy4.png")
        
        // Spawn enemy 1 off screen randomly and add to the scene
        enemy1.position = CGPoint(
            x:CGFloat.random(
                min: frame.minX + enemy1.size.width/2,
                max: frame.maxX - enemy1.size.width/2),
            y:size.height + enemy1.size.height/2)
        
        addChild(enemy1)
        enemy1.zPosition = 1
        
        //Create SKAction commands to dealy object entering screen, its postions to move to and then remove if final destiantion has been reached
        let delay = SKAction.wait(forDuration: 10)
        let actionMove = SKAction.moveTo(y: -600, duration: 5.0)
        let actionRemove = SKAction.removeFromParent()
        enemy1.run(SKAction.sequence([delay, actionMove, actionRemove]))
        
        //Enemy Physics for collision
        enemy1.physicsBody = SKPhysicsBody(circleOfRadius: enemy1.size.width / 2)
        enemy1.physicsBody?.isDynamic = true
        
        //Set category for object and what its can collide with
        enemy1.physicsBody?.categoryBitMask = enemyCategory
        enemy1.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        
        //avoid any unwanted collisions
        enemy1.physicsBody?.collisionBitMask = 0
    }
    
    func addEnemy2() {
        //Enemy2 Image
        enemy2 = .init(imageNamed: "Enemy5.png")
        
        // Spawn enemy 1 off screen randomly and add to the scene
        enemy2.position = CGPoint(
            x:CGFloat.random(
                min: frame.minX + enemy2.size.width/2,
                max: frame.maxX - enemy2.size.width/2),
            y:size.height + enemy2.size.height/2)
        
        addChild(enemy2)
        enemy2.zPosition = 1
        
        //Create SKAction commands to dealy object entering screen, its postions to move to and then remove if final destiantion has been reached
        let endPoint = CGPoint(x: player.position.x, y: -600)
        let delay = SKAction.wait(forDuration: 25)
        let actionMoveOne = SKAction.move(to: CGPoint(x: frame.size.width / 2, y: 200), duration: 1.5)
        let actionMoveTwo = SKAction.move(to: endPoint, duration: 1.5)
        let actionRemove = SKAction.removeFromParent()
        enemy2.run(SKAction.sequence([delay, actionMoveOne, actionMoveTwo, actionRemove]))
        
        //Enemy Physics for collision
        enemy2.physicsBody = SKPhysicsBody(circleOfRadius: enemy2.size.width / 2)
        enemy2.physicsBody?.isDynamic = true
        
        //Set category for object and what its can collide with
        enemy2.physicsBody?.categoryBitMask = enemyCategory
        enemy2.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        
        //avoid any unwanted collisions
        enemy2.physicsBody?.collisionBitMask = 0
    }
    
    func addEnemy3() {
        
        //Enemy3 Image
        enemy3 = .init(imageNamed: "Enemy6.png")

        //GameplayKit randomization services to spawn different enemy3
        let randomEnemy3Position = GKRandomDistribution(lowestValue: -350, highestValue: 350)
        //Randomly spawn enemy3 in differnet positions
        var position = CGFloat(randomEnemy3Position.nextInt())
        enemy3.position = CGPoint(x: position, y: self.frame.size.height - enemy3.size.height)
        
        addChild(enemy3)
        enemy3.zPosition = 1
        
        //Enemy Physics for collision
        enemy3.physicsBody = SKPhysicsBody(circleOfRadius: enemy3.size.width / 2)
        enemy3.physicsBody?.isDynamic = true
        
        //Set category for object and what its can collide with
        enemy3.physicsBody?.categoryBitMask = enemyCategory
        enemy3.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        
        //avoid any unwanted collisions
        enemy3.physicsBody?.collisionBitMask = 0
        
        //Delay enemies
        let delay = SKAction.wait(forDuration: 40)

        //Move enemies to next postions randomly on the x axis while moving down the y axis
        let actionMoveOne = SKAction.move(to: CGPoint(x: position, y: 500), duration: 1.0)
        position = CGFloat(randomEnemy3Position.nextInt())
        let actionMoveTwo = SKAction.move(to: CGPoint(x: position, y: position), duration: 1.0)
        position = CGFloat(randomEnemy3Position.nextInt())
        let actionMoveThree = SKAction.move(to: CGPoint(x: position, y: 0), duration: 1.0)
        position = CGFloat(randomEnemy3Position.nextInt())
        let actionMoveFour = SKAction.move(to: CGPoint(x: position, y: position), duration: 1.0)
        position = CGFloat(randomEnemy3Position.nextInt())
        let actionMoveFive = SKAction.move(to: CGPoint(x: position, y: -600), duration: 1.0)

        let wait = SKAction.wait(forDuration: 0.1)

        // Remove enemies when finished
        let actionRemove = SKAction.removeFromParent()

        enemy3.run(SKAction.sequence([delay, actionMoveOne, wait, actionMoveTwo, wait, actionMoveThree, wait, actionMoveFour, wait, actionMoveFive, actionRemove]))
    }

    func addBoss() {
        
        //Is suppose to stop spawning enemies when the boss is spawned but doesnt work correctly
        removeAction(forKey: "enemy1")
        removeAction(forKey: "enemy2")
        removeAction(forKey: "enemy3")
        
        //Boss Image
        boss = .init(imageNamed: "BossB.png")
        
        //Position and add to the scene
        boss.position.y = self.frame.size.height
        boss.zPosition = 1
        addChild(boss)
    
        //BossPhysics for collision
        boss.physicsBody = SKPhysicsBody(rectangleOf: boss.size)
        boss.physicsBody?.isDynamic = true
        
        //Set category for object and what its can collide with
        boss.physicsBody?.categoryBitMask = bossCategory
        boss.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        
        //avoid any unwanted collisions
        boss.physicsBody?.collisionBitMask = 0
        
        //Created position for the boss to move to while on the screen
        let move1 = SKAction.moveTo(y: size.height / 3.5, duration: 3)
        let move2 = SKAction.moveTo(x: size.width / 3, duration: 3)
        let move3 = SKAction.moveTo(x: 0 - boss.size.width, duration: 3)
        let move4 = SKAction.moveTo(x: 0, duration: 1.5)
        let move5 = SKAction.fadeOut(withDuration: 0.2)
        let move6 = SKAction.fadeIn(withDuration: 0.2)
        let move7 = SKAction.moveTo(y: 0 - boss.size.height * 3, duration: 3)
        let move8 = SKAction.moveTo(y: size.height / 3.5, duration: 3)

        let action = SKAction.repeat(SKAction.sequence([move5, move6]), count: 6)
        let repeatForever = SKAction.repeatForever(SKAction.sequence([move2, move3, move4, action, move7, move8]))
        let sequence = SKAction.sequence([move1, repeatForever])

        boss.run(sequence)
        
        //Timer for the boss to shoot back
        bossFiringTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(addBossLaser), userInfo: nil, repeats: true)
    }
    
@objc func addBossLaser() {
        
        //Create and position weapon for boss
        bossLaser = .init(imageNamed: "EnemyLaser")
        bossLaser.position = boss.position
        bossLaser.position.y -= 40
        bossLaser.zPosition = 1
    
        addChild(bossLaser)
    
        //Boss Laser Physics
        bossLaser.physicsBody = SKPhysicsBody(circleOfRadius: bossLaser.size.width / 2)
        bossLaser.physicsBody?.isDynamic = true
        
        //Set category for object and what its can collide with
        bossLaser.physicsBody?.categoryBitMask = enemyLaserCategory
        bossLaser.physicsBody?.contactTestBitMask = playerCategory
    
        //avoid any unwanted collisions
        bossLaser.physicsBody?.collisionBitMask = 0
        bossLaser.physicsBody?.usesPreciseCollisionDetection = true
        
        //SKActions to move the laser down the screen and remove when out of bounds
        let move1 = SKAction.moveTo(y: -700, duration: 1)
        let removeAction = SKAction.removeFromParent()
        
        let sequence = SKAction.sequence([move1, removeAction])
        bossLaser.run(sequence)
    }
    
    func fireLaser() {
        
        //Sound effect
        self.run(SKAction.playSoundFileNamed("laser.wav", waitForCompletion: false))
        
        //Create and position laser1
        let playerLaser = SKSpriteNode(imageNamed: "laser")
        playerLaser.position = player.position
        playerLaser.position.y += 65
        
        //Create and position laser2
        let playerLaser2A = SKSpriteNode(imageNamed: "laser2")
        playerLaser2A.position = player.position
        playerLaser2A.position.y += 65
        
        let playerLaser2B = SKSpriteNode(imageNamed: "laser2")
        playerLaser2B.position = player.position
        playerLaser2B.position.x += 30
        
        let playerLaser2C = SKSpriteNode(imageNamed: "laser2")
        playerLaser2C.position = player.position
        playerLaser2C.position.x -= 30
        
        //Laser1 Physics
        playerLaser.physicsBody = SKPhysicsBody(circleOfRadius: playerLaser.size.width / 2)
        playerLaser.physicsBody?.isDynamic = true
        
        playerLaser.physicsBody?.categoryBitMask = playerLaserCategory
        playerLaser.physicsBody?.contactTestBitMask = astroidCategory | enemyCategory
        //avoid any unwanted collisions
        playerLaser.physicsBody?.collisionBitMask = 0
        playerLaser.physicsBody?.usesPreciseCollisionDetection = true
        
        //Laser2A Physics
        playerLaser2A.physicsBody = SKPhysicsBody(circleOfRadius: playerLaser.size.width / 2)
        playerLaser2A.physicsBody?.isDynamic = true
        
        playerLaser2A.physicsBody?.categoryBitMask = playerLaserCategory
        playerLaser2A.physicsBody?.contactTestBitMask = astroidCategory | enemyCategory
        //avoid any unwanted collisions
        playerLaser2A.physicsBody?.collisionBitMask = 0
        playerLaser2A.physicsBody?.usesPreciseCollisionDetection = true
        
        //Laser2B Physics
        playerLaser2B.physicsBody = SKPhysicsBody(circleOfRadius: playerLaser.size.width / 2)
        playerLaser2B.physicsBody?.isDynamic = true
        
        playerLaser2B.physicsBody?.categoryBitMask = playerLaserCategory
        playerLaser2B.physicsBody?.contactTestBitMask = astroidCategory | enemyCategory
        //avoid any unwanted collisions
        playerLaser2B.physicsBody?.collisionBitMask = 0
        playerLaser2B.physicsBody?.usesPreciseCollisionDetection = true
        
        //Laser2C Physics
        playerLaser2C.physicsBody = SKPhysicsBody(circleOfRadius: playerLaser.size.width / 2)
        playerLaser2C.physicsBody?.isDynamic = true
        
        playerLaser2C.physicsBody?.categoryBitMask = playerLaserCategory
        playerLaser2C.physicsBody?.contactTestBitMask = astroidCategory | enemyCategory
        //avoid any unwanted collisions
        playerLaser2C.physicsBody?.collisionBitMask = 0
        playerLaser2C.physicsBody?.usesPreciseCollisionDetection = true
        
        if (laser2 == true && laser1 == false) {
            addChild(playerLaser2A)
            addChild(playerLaser2B)
            addChild(playerLaser2C)
        }
        else {
            addChild(playerLaser)
        }
        
        //Animation for laser1 firing
        let animationDuration:TimeInterval = 0.4
        
        //Clean up, removes laser blast from game
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: 600/*self.frame.size.height*/), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        playerLaser.run(SKAction.sequence(actionArray))
        
        //Animation for laser2 firing
        let animationDuration1:TimeInterval = 0.7
        
        //Clean up, removes laser blast from game
        var actionArray1 = [SKAction]()
        actionArray1.append(SKAction.move(to: CGPoint(x: player.position.x, y: 600/*self.frame.size.height*/), duration: animationDuration1))
        actionArray1.append(SKAction.removeFromParent())
        
        playerLaser2A.run(SKAction.sequence(actionArray1))
        
        //Clean up, removes laser blast from game
        var actionArray2 = [SKAction]()
        actionArray2.append(SKAction.move(to: CGPoint(x: player.position.x + 30, y: 600/*self.frame.size.height*/), duration: animationDuration1))
        actionArray2.append(SKAction.removeFromParent())
        
        playerLaser2B.run(SKAction.sequence(actionArray2))
        
        //Clean up, removes laser blast from game
        var actionArray3 = [SKAction]()
        actionArray3.append(SKAction.move(to: CGPoint(x: player.position.x - 30, y: 600/*self.frame.size.height*/), duration: animationDuration1))
        actionArray3.append(SKAction.removeFromParent())
        
        playerLaser2C.run(SKAction.sequence(actionArray3))
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
            playerLaserHitAstroid(laserNode: A.node as! SKSpriteNode, astroidNode: B.node as! SKSpriteNode)
        }
        //PlayerLaser is A and Enemy is B
        else if (A.categoryBitMask & playerLaserCategory) != 0 && (B.categoryBitMask & enemyCategory) != 0 {
            playerLaserHitEnemy(laserNode: A.node as! SKSpriteNode, enemyNode: B.node as! SKSpriteNode)
        }
        //PlayerLaser is A and Boss is B
        else if (A.categoryBitMask & playerLaserCategory) != 0 && (B.categoryBitMask & bossCategory) != 0 {
            playerLaserHitBoss(laserNode: A.node as! SKSpriteNode, bossNode: B.node as! SKSpriteNode)
        }
        //Player is A and Shield Pickup is B
        else if (A.categoryBitMask & playerCategory) != 0 && (B.categoryBitMask & shieldPickupCategory) != 0 {
            playerHitShieldPickup(playerNode: A.node as! SKSpriteNode, shieldPickupNode: B.node as! SKSpriteNode)
        }
        //Player is A and Life Pickup is B
        else if (A.categoryBitMask & playerCategory) != 0 && (B.categoryBitMask & lifePickupCategory) != 0 {
            playerHitLifePickup(playerNode: A.node as! SKSpriteNode, lifePickupNode: B.node as! SKSpriteNode)
        }
        //Player is A and weapon Pickup is B
        else if (A.categoryBitMask & playerCategory) != 0 && (B.categoryBitMask & weaponPickupCategory) != 0 {
            playerHitWeaponPickup(playerNode: A.node as! SKSpriteNode, weaponPickupNode: B.node as! SKSpriteNode)
        }
        //Player is A and Astroid is B
        else if (A.categoryBitMask & playerCategory) != 0 && (B.categoryBitMask & astroidCategory) != 0 {
            playerHitAstroid(playerNode: A.node as! SKSpriteNode, astroidNode: B.node as! SKSpriteNode)
        }
        //Player is A and Enemy is B
        else if (A.categoryBitMask & playerCategory) != 0 && (B.categoryBitMask & enemyCategory) != 0 {
            playerHitEnemy(playerNode: A.node as! SKSpriteNode, enemyNode: B.node as! SKSpriteNode)
        }
        //Player is A and Boss is B
        else if (A.categoryBitMask & playerCategory) != 0 && (B.categoryBitMask & bossCategory) != 0 {
            playerHitBoss(playerNode: A.node as! SKSpriteNode, bossNode: B.node as! SKSpriteNode)
        }
        //Player is A and Enemy Laser is B
        else if (A.categoryBitMask & playerCategory) != 0 && (B.categoryBitMask & enemyLaserCategory) != 0 {
            playerHitEnemyLaser(playerNode: A.node as! SKSpriteNode, enemyLaserNode: B.node as! SKSpriteNode)
        }
    }
    
    //Function for playerLaser to destroy Astroid
    func playerLaserHitAstroid (laserNode:SKSpriteNode, astroidNode:SKSpriteNode) {
        
        //Create explosion effect and position it
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = astroidNode.position
        addChild(explosion)
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        trash.append(laserNode)
        trash.append(astroidNode)
        
        //Runs explosion and waits for 2 seconds, then add the explosion to the trash array so it can be removed from scene in next update
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosion)
         }
        
        //For debug purposes
        print("laser hit astroid")
        
        //Add score
        GameSceneOne.score += 5
    }
    
    //Function for playerLaser to destroy Enemy
    func playerLaserHitEnemy (laserNode:SKSpriteNode, enemyNode:SKSpriteNode) {
        
        //Create explosion effect and position it
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = enemyNode.position
        addChild(explosion)
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        trash.append(laserNode)
        trash.append(enemyNode)
    
        //Runs explosion and waits for 2 seconds, then add the explosion to the trash array so it can be removed from scene in next update
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosion)
         }
        
        //For debug purposes
        print("laser hit enemy")
        
        //Add score
        GameSceneOne.score += 10
    }
    
    //Function for playerLaser to destroy Boss
    func playerLaserHitBoss (laserNode:SKSpriteNode, bossNode:SKSpriteNode) {
        
        //Create explosion effect and position it
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = bossNode.position
        addChild(explosion)
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //Remove sprites
        trash.append(laserNode)
        
        if bossHealth > 1 {
            //Remove Boss Health
            bossHealth = bossHealth - 1
        }
        else {
            //Remove Sprite
            trash.append(bossNode)
            
            //Add score
            GameSceneOne.score += 20
            
            //Condition for achievement
            GameSceneOne.bossIsDead = true
            
            //Needed a delay so the Game Center achievemnt would show on screen and this run block helped me do this
            //Before I just had the tranistion code and the achievement banner would not show on the next screen
            //This run block seems to delay the tranisition enough for the banner to show up
            let endGameTransistion = SKAction.run() {
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                let complateLevel = LevelTwoComplete(fileNamed: "LevelTwoComplete")!
                complateLevel.score = GameSceneOne.score
                complateLevel.scaleMode = .aspectFill
                self.view?.presentScene(complateLevel, transition: transition)
            }

            boss.run(SKAction.sequence([endGameTransistion]))
        }
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
            guard let `self` = self else {return}
            self.trash.append(explosion)
        }
        
        //Debug purposes
        print("laser hit boss")
        print(bossHealth)
    }
    
    //Function for when player and Shield Pickup collide
    func playerHitShieldPickup (playerNode:SKSpriteNode, shieldPickupNode:SKSpriteNode) {
        
        //Play Shield Pickup sound effect
        self.run(SKAction.playSoundFileNamed("shield.wav", waitForCompletion: false))
        
        //Early tests of invincibilty caused problems where if the player had invincibilty and hit the pickup again
        //They would lose the perk, this if statement solved this for me and works fine now.
        //This is just the code to make player blink, the logic for not losing a life is done else where
        if invincible == false {
            invincible = true
            let blinkTimes = 30.0
            let duration = 10.0
            let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let slice = duration / blinkTimes
                let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
                  node.isHidden = remainder > slice / 2
                }
                let setHidden = SKAction.run() { [weak self] in
                  self?.player.isHidden = false
                  self?.invincible = false
                }
                player.run(SKAction.sequence([blinkAction, setHidden]))
        }
        else {
            invincible = true
        }
        
        //remove sprites
        trash.append(shieldPickupNode)
        
        //Debug
        print("Shield Pickup")
    }
    
    //Function for when player and Life Pickup collide
    func playerHitLifePickup (playerNode:SKSpriteNode, lifePickupNode:SKSpriteNode) {
        
        //Play life pickup sound effect
        self.run(SKAction.playSoundFileNamed("lifepickup.wav", waitForCompletion: false))
       
        //Add 1 to the lives variable
        GameSceneOne.numLives += 1
        
        //remove sprites
        trash.append(lifePickupNode)
        
        //Debug
        print("Life Pickup")
        print(GameSceneOne.numLives)
    }
    
    //Function for when player and Life Pickup collide
    func playerHitWeaponPickup (playerNode:SKSpriteNode, weaponPickupNode:SKSpriteNode) {
        
        //Play Weapon pickup sound effect
        self.run(SKAction.playSoundFileNamed("powerUp.wav", waitForCompletion: false))
        
        //Disable laser 1 and activate laser 2
        laser1 = false
        laser2 = true
        
        //remove sprites
        trash.append(weaponPickupNode)
        
        //Debug
        print("Weapon Pickup")
    }
    
    //Function for when player and astroid collide
    func playerHitAstroid(playerNode:SKSpriteNode, astroidNode:SKSpriteNode) {
        
        //Create explosion effect and position it
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = astroidNode.position
        explosion.zPosition = 3
        addChild(explosion)
        
        //Debug
        print("Player hit astroid")
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        trash.append(astroidNode)
        
        //If the player has the weapon power and is also invincible, they wont lose the power up
        if invincible == true && laser2 == true {
            laser1 = false
            laser2 = true
        }
        //If the player has the weapon power and is not invincible, they will lose the power up and revert back to first laser
        else if invincible == false && laser2 == true {
            laser1 = true
            laser2 = false
        }
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosion)
         }
        
        //Removes a life when hit if not invincible
        if GameSceneOne.numLives > 0 && invincible == false {
           
            GameSceneOne.numLives -= 1
            
            //Debug
            print(GameSceneOne.numLives)

            //After losing a life the player becomes invincible for a brief time
            invincible = true
            let blinkTimes = 5.0
            let duration = 1.0
            let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let slice = duration / blinkTimes
                let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
                  node.isHidden = remainder > slice / 2
                }
                let setHidden = SKAction.run() { [weak self] in
                  self?.player.isHidden = false
                  self?.invincible = false
                }
                player.run(SKAction.sequence([blinkAction, setHidden]))
        }
        
        //Remove player when all lives are gone and transition to game over scene
        if GameSceneOne.numLives == 0 {
            trash.append(playerNode)
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOver = GameOverScene(fileNamed: "GameOverScene")!
            gameOver.score = GameScene.score
            gameOver.scaleMode = scaleMode
            self.view?.presentScene(gameOver, transition: transition)
        }
    }
    
    //Function for when player and enemy collide
    func playerHitEnemy(playerNode:SKSpriteNode, enemyNode:SKSpriteNode) {
        
        //Create explosion effect and position it
        let explosionA = SKEmitterNode(fileNamed: "Explosion")!
        explosionA.position = enemyNode.position
        explosionA.zPosition = 3
        addChild(explosionA)
        
        //Debug
        print("Player hit enemy")
    
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        trash.append(enemyNode)
        
        //If the player has the weapon power and is also invincible, they wont lose the power up
        if invincible == true && laser2 == true {
            laser1 = false
            laser2 = true
        }
        //If the player has the weapon power and is not invincible, they will lose the power up and revert back to first laser
        else if invincible == false && laser2 == true {
            laser1 = true
            laser2 = false
        }
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosionA)
         }
        
        //Removes a life when hit if not invincible
        if GameSceneOne.numLives > 0 && invincible == false {

            GameSceneOne.numLives -= 1
            
            //Debug
            print(GameSceneOne.numLives)

            //After losing a life the player becomes invincible for a brief time
            invincible = true
            let blinkTimes = 5.0
            let duration = 1.0
            let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let slice = duration / blinkTimes
                let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
                  node.isHidden = remainder > slice / 2
                }
                let setHidden = SKAction.run() { [weak self] in
                  self?.player.isHidden = false
                  self?.invincible = false
                }
                player.run(SKAction.sequence([blinkAction, setHidden]))
        }
        
        //Remove player when all lives are gone and transition to game over scene
        if GameSceneOne.numLives == 0 {
            trash.append(playerNode)
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOver = GameOverScene(fileNamed: "GameOverScene")!
            gameOver.score = GameScene.score
            gameOver.scaleMode = scaleMode
            self.view?.presentScene(gameOver, transition: transition)
        }
    }
    
    //Function for when player and boss collide
    func playerHitBoss(playerNode:SKSpriteNode, bossNode:SKSpriteNode) {
        
        //Create explosion effect and position it
        let explosionA = SKEmitterNode(fileNamed: "Explosion")!
        explosionA.position = bossNode.position
        explosionA.zPosition = 3
        addChild(explosionA)
        
        //Debug
        print("Player hit boss")
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //If the player has the weapon power and is also invincible, they wont lose the power up
        if invincible == true && laser2 == true {
            laser1 = false
            laser2 = true
        }
        //If the player has the weapon power and is not invincible, they will lose the power up and revert back to first laser
        else if invincible == false && laser2 == true {
            laser1 = true
            laser2 = false
        }
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosionA)
         }
        
        //Removes a life when hit
        if GameSceneOne.numLives > 0 && invincible == false {

            GameSceneOne.numLives -= 1
            
            //Debug
            print(GameSceneOne.numLives)

            //After losing a life the player becomes invincible for a brief time
            invincible = true
            let blinkTimes = 5.0
            let duration = 1.0
            let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let slice = duration / blinkTimes
                let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
                  node.isHidden = remainder > slice / 2
                }
                let setHidden = SKAction.run() { [weak self] in
                  self?.player.isHidden = false
                  self?.invincible = false
                }
                player.run(SKAction.sequence([blinkAction, setHidden]))
        }
        
        //Remove player when all lives are gone and transition to game over scene
        if GameSceneOne.numLives == 0 {
            trash.append(playerNode)
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOver = GameOverScene(fileNamed: "GameOverScene")!
            gameOver.score = GameScene.score
            gameOver.scaleMode = scaleMode
            self.view?.presentScene(gameOver, transition: transition)
        }
    }
    
    func playerHitEnemyLaser(playerNode:SKSpriteNode, enemyLaserNode:SKSpriteNode) {
        
        //Create explosion effect and position it
        let explosionA = SKEmitterNode(fileNamed: "Explosion")!
        explosionA.position = playerNode.position
        explosionA.zPosition = 3
        addChild(explosionA)
        
        //Debug
        print("Player hit enemy laser")
    
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        trash.append(enemyLaserNode)
        
        //If the player has the weapon power and is also invincible, they wont lose the power up
        if invincible == true && laser2 == true {
            laser1 = false
            laser2 = true
        }
        //If the player has the weapon power and is not invincible, they will lose the power up and revert back to first laser
        else if invincible == false && laser2 == true {
            laser1 = true
            laser2 = false
        }
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosionA)
         }
        
        //Removes a life when hit
        if GameSceneOne.numLives > 0 && invincible == false {

            GameSceneOne.numLives -= 1
            
            //Debug
            print(GameSceneOne.numLives)

            //After losing a life the player becomes invincible for a brief time
            invincible = true
            let blinkTimes = 5.0
            let duration = 1.0
            let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let slice = duration / blinkTimes
                let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
                  node.isHidden = remainder > slice / 2
                }
                let setHidden = SKAction.run() { [weak self] in
                  self?.player.isHidden = false
                  self?.invincible = false
                }
                player.run(SKAction.sequence([blinkAction, setHidden]))
        }
        
        //Remove player when all lives are gone and transition to game over scene
        if GameSceneOne.numLives == 0 {
            trash.append(playerNode)
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOver = GameOverScene(fileNamed: "GameOverScene")!
            gameOver.score = GameScene.score
            gameOver.scaleMode = scaleMode
            self.view?.presentScene(gameOver, transition: transition)
        }
    }
    
    override func didSimulatePhysics() {
        //Movement using the Accelometer
        player.position.x += xAcceleration * 50
        
        //if player reaches end of screen, player will come back thee other side of the screen
        if player.position.x < -400 {
            player.position = CGPoint(x: 400, y: player.position.y)
        } else if player.position.x > 400 {
            player.position = CGPoint(x: -400, y: player.position.y)
        }
        
        //first go through every node and remove it from parent
        trash.map { node in
            node.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.02), SKAction.removeFromParent()]))
        }
        trash.removeAll() // then empty thrash array before next frame
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Call function to fire laser on touch
        fireLaser()
    }
    
    override func update(_ currentTime: TimeInterval) {
        //Reports if achievements have been unlocked and the score to the Game Center
        if (GameSceneOne.bossIsDead == true) {
            //reportAllAchievementsForGameState(bossIsDead: true)
            reportScoreToGameCenter(score: Int64(GameSceneOne.score))
        }
        else if (GameSceneOne.bossIsDead == false) {
            //reportAllAchievementsForGameState(bossIsDead: false)
        }
    }
    
    func reportScoreToGameCenter(score: Int64) {
        GameKitHelper.sharedInstance.reportScore(score: score,forLeaderboardID:leaderboardID)
    }
}

