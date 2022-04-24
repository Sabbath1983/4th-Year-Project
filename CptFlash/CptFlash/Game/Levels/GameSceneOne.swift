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
    let music = SKAudioNode(fileNamed: "Retro.mp3")
    
    override func didMove(to view: SKView) {
        
        //Call Lives method
        addLives()
        
        //Weapon pickup method
        addWeaponPickup()

        //Call Invincabilty method
        addInvincablityPickup()

//        //Call Enemy1 method
//        addEnemy1()
//
//        //Call Enemy2 method
//        addEnemy2()
//
//        //Call Enemy3 method
//        addEnemy3()
        
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
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: -300, y: 525)
        scoreLabel.fontName = "Symbol"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = UIColor.white
        score = GameScene.score
        addChild(scoreLabel)
        
        //Timer to spawn astroids
        astroidTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(addAstroid), userInfo: nil, repeats: true)
        

        //Timer to spawn Boss
        bossTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(addBoss), userInfo: nil, repeats: false)
        
        //Spawn Invinabilty pickup
        run(SKAction.repeatForever(
          SKAction.sequence([SKAction.run() { [weak self] in
                              self?.addInvincablityPickup()
                            },
          SKAction.wait(forDuration: 25.0)])))

        //Spawn Weapon pickup
        run(SKAction.repeatForever(
          SKAction.sequence([SKAction.run() { [weak self] in
                              self?.addWeaponPickup()
                            },
          SKAction.wait(forDuration: 15.0)])))

//
//        //Spawn Enemy1
//        run(SKAction.repeatForever(
//          SKAction.sequence([SKAction.run() { [weak self] in
//                              self?.addEnemy1()
//                            },
//                            SKAction.wait(forDuration: 5.0)])), withKey:"enemy1")
//
//        //Spawn Enemy2
//        run(SKAction.repeatForever(
//          SKAction.sequence([SKAction.run() { [weak self] in
//                              self?.addEnemy2()
//                            },
//                            SKAction.wait(forDuration: 6.0)])), withKey:"enemy2")
//
//        //Spawn Enemy3
//        run(SKAction.repeatForever(
//          SKAction.sequence([SKAction.run() { [weak self] in
//                              self?.addEnemy3()
//                            },
//                            SKAction.wait(forDuration: 7.0)])), withKey:"enemy3")

        //Using Accelometer for movement
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
                //self.yAcceleration = CGFloat(acceleration.y) * 0.2 + self.yAcceleration * 0.2
            }
        }
        
        //Adding music
        addChild(music)
    }
    
    func addLives() {
        GameScene.livesArray = [SKSpriteNode]()
        
        for life in 1...3 {
            let lifeNode = SKSpriteNode(imageNamed: "Life")
            lifeNode.position = CGPoint(x: 350 - CGFloat(4 - life) * lifeNode.size.width, y: 525)
            addChild(lifeNode)
            GameScene.livesArray.append(lifeNode)
        }
    }
    
    func addWeaponPickup() {
        //Weapon Pickup Image
        let weaponPickUp = SKSpriteNode(imageNamed: "WeaponsPickup.png")
        // Spawn weapon pickup off screen randomly
        weaponPickUp.position = CGPoint(
            x:CGFloat.random(
                min: frame.minX + weaponPickUp.size.width/2,
                max: frame.maxX - weaponPickUp.size.width/2),
            y:size.height + weaponPickUp.size.height/2)
          addChild(weaponPickUp)

        let delay = SKAction.wait(forDuration: 15)
        let actionMove = SKAction.moveTo(y: -600, duration: 5.0)
        let actionRemove = SKAction.removeFromParent()
        weaponPickUp.run(SKAction.sequence([delay, actionMove, actionRemove]))

        weaponPickUp.zPosition = 1

        //Weapon Pickup Physics for collision
        weaponPickUp.physicsBody = SKPhysicsBody(circleOfRadius: weaponPickUp.size.width / 2)
        weaponPickUp.physicsBody?.isDynamic = true

        weaponPickUp.physicsBody?.categoryBitMask = weaponPickupCategory
        weaponPickUp.physicsBody?.contactTestBitMask = playerCategory
        //avoid any unwanted collisions
        weaponPickUp.physicsBody?.collisionBitMask = 0
    }

    func addInvincablityPickup() {
        //Shield Pickup Image
        let shieldPickUp = SKSpriteNode(imageNamed: "ShieldPickup.png")
        // Spawn shield pickup off screen randomly
        shieldPickUp.position = CGPoint(
            x:CGFloat.random(
                min: frame.minX + shieldPickUp.size.width/2,
                max: frame.maxX - shieldPickUp.size.width/2),
            y:size.height + shieldPickUp.size.height/2)
          addChild(shieldPickUp)

        let delay = SKAction.wait(forDuration: 30)
        let actionMove = SKAction.moveTo(y: -600, duration: 5.0)
        let actionRemove = SKAction.removeFromParent()
        shieldPickUp.run(SKAction.sequence([delay, actionMove, actionRemove]))

        shieldPickUp.zPosition = 1

        //Shield PickUp Physics for collision
        shieldPickUp.physicsBody = SKPhysicsBody(circleOfRadius: shieldPickUp.size.width / 2)
        shieldPickUp.physicsBody?.isDynamic = true

        shieldPickUp.physicsBody?.categoryBitMask = shieldPickupCategory
        shieldPickUp.physicsBody?.contactTestBitMask = playerCategory
        //avoid any unwanted collisions
        shieldPickUp.physicsBody?.collisionBitMask = 0
    }
    
    func addAstroid() {
        // Randonly select astroid from the array
        astroidArray = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: astroidArray) as! [String]
        
        let astroid = SKSpriteNode(imageNamed: astroidArray[0])
        
        //GameplayKit randomization services to spawn different astroids
        //Randomly spawn astroid in differnet positions
        let randomAstroidPosition = GKRandomDistribution(lowestValue: -350, highestValue: 350)
        let position = CGFloat(randomAstroidPosition.nextInt())
        astroid.position = CGPoint(x: position, y: self.frame.size.height + astroid.size.height)
        
        astroid.zPosition = 1
        
        //Astroid Physics for collision
        astroid.physicsBody = SKPhysicsBody(circleOfRadius: astroid.size.width / 2)
        //astroid.physicsBody = SKPhysicsBody(texture: astroid.texture!, size: astroid.size)
        astroid.physicsBody?.isDynamic = true
        
        astroid.physicsBody?.categoryBitMask = astroidCategory
        astroid.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        //avoid any unwanted collisions
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
    
    func addEnemy1() {

        //Enemy1 Image
        enemy1 = .init(imageNamed: "Enemy4.png")
        // Spawn enemy 1 off screen randomly
        enemy1.position = CGPoint(
            x:CGFloat.random(
                min: frame.minX + enemy1.size.width/2,
                max: frame.maxX - enemy1.size.width/2),
            y:size.height + enemy1.size.height/2)
          addChild(enemy1)

        let delay = SKAction.wait(forDuration: 10)
        let actionMove = SKAction.moveTo(y: -600, duration: 5.0)
        let actionRemove = SKAction.removeFromParent()
        enemy1.run(SKAction.sequence([delay, actionMove, actionRemove]))

        enemy1.zPosition = 1

        //Enemy Physics for collision
        enemy1.physicsBody = SKPhysicsBody(circleOfRadius: enemy1.size.width / 2)
        enemy1.physicsBody?.isDynamic = true

        enemy1.physicsBody?.categoryBitMask = enemyCategory
        enemy1.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        //avoid any unwanted collisions
        enemy1.physicsBody?.collisionBitMask = 0
    }

    func addEnemy2() {
        //Enemy2 Image
        enemy2 = .init(imageNamed: "Enemy5.png")
        // Spawn enemy 2 off screen randomly
        enemy2.position = CGPoint(
            x:CGFloat.random(
                min: frame.minX + enemy2.size.width/2,
                max: frame.maxX - enemy2.size.width/2),
            y:size.height + enemy2.size.height/2)
          addChild(enemy2)

        let endPoint = CGPoint(x: player.position.x, y: -600)
        let delay = SKAction.wait(forDuration: 25)
        let actionMove = SKAction.move(to: endPoint, duration: 3.0)
        let actionRemove = SKAction.removeFromParent()
        enemy2.run(SKAction.sequence([delay, actionMove, actionRemove]))

        enemy2.zPosition = 1

        //Enemy Physics for collision
        enemy2.physicsBody = SKPhysicsBody(circleOfRadius: enemy2.size.width / 2)
        enemy2.physicsBody?.isDynamic = true

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

        enemy3.physicsBody?.categoryBitMask = enemyCategory
        enemy3.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        //avoid any unwanted collisions
        enemy3.physicsBody?.collisionBitMask = 0

        //Delay enemies
        let delay = SKAction.wait(forDuration: 35)

        //Move enemies to next postions randomly on the x axis while moving down the y axis
        let actionMoveOne = SKAction.move(to: CGPoint(x: position, y: 500), duration: 1.5)
        position = CGFloat(randomEnemy3Position.nextInt())
        let actionMoveTwo = SKAction.move(to: CGPoint(x: position, y: position), duration: 1.5)
        position = CGFloat(randomEnemy3Position.nextInt())
        let actionMoveThree = SKAction.move(to: CGPoint(x: position, y: position), duration: 1.5)
        position = CGFloat(randomEnemy3Position.nextInt())
        let actionMoveFour = SKAction.move(to: CGPoint(x: position, y: position), duration: 1.5)
        position = CGFloat(randomEnemy3Position.nextInt())
        let actionMoveFive = SKAction.move(to: CGPoint(x: position, y: -600), duration: 1.5)

        let wait = SKAction.wait(forDuration: 0.2)

        // Remove enemies when finished
        let actionRemove = SKAction.removeFromParent()

        enemy3.run(SKAction.sequence([delay, actionMoveOne, wait, actionMoveTwo, wait, actionMoveThree, wait, actionMoveFour, wait, actionMoveFive, actionRemove]))
    }

    func addBoss() {

        removeAction(forKey: "enemy1")
        removeAction(forKey: "enemy2")
        removeAction(forKey: "enemy3")

        //Boss Image
        boss = .init(imageNamed: "BossB.png")

        boss.position.y = self.frame.size.height
        //boss.position = CGPoint(x: size.width / 2 , y: size.height + boss.size.height)
        boss.zPosition = 1
        addChild(boss)

        //BossPhysics for collision
        boss.physicsBody = SKPhysicsBody(rectangleOf: boss.size)
        boss.physicsBody?.isDynamic = true

        boss.physicsBody?.categoryBitMask = bossCategory
        boss.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        //avoid any unwanted collisions
        boss.physicsBody?.collisionBitMask = 0

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

        bossFiringTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(addBossLaser), userInfo: nil, repeats: true)
    }

@objc func addBossLaser() {

        bossLaser = .init(imageNamed: "EnemyLaser")
        bossLaser.position = boss.position
        bossLaser.position.y -= 40
        bossLaser.zPosition = 1

        addChild(bossLaser)

        //Boss Laser Physics
        bossLaser.physicsBody = SKPhysicsBody(circleOfRadius: bossLaser.size.width / 2)
        bossLaser.physicsBody?.isDynamic = true

        bossLaser.physicsBody?.categoryBitMask = enemyLaserCategory
        bossLaser.physicsBody?.contactTestBitMask = playerCategory
        //avoid any unwanted collisions
        bossLaser.physicsBody?.collisionBitMask = 0
        bossLaser.physicsBody?.usesPreciseCollisionDetection = true

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
        
        //Create explosion effect
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = astroidNode.position
        addChild(explosion)
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        trash.append(laserNode)
        trash.append(astroidNode)
        
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosion)
         }
        print("laser hit astroid")
        
        //Add score
        score += 5
    }
    
    //Function for playerLaser to destroy Enemy
    func playerLaserHitEnemy (laserNode:SKSpriteNode, enemyNode:SKSpriteNode) {
        
        //Create explosion effect
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = enemyNode.position
        addChild(explosion)
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        trash.append(laserNode)
        trash.append(enemyNode)
        
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosion)
         }
        print("laser hit enemy")
        
        //Add score
        score += 10
    }
    
    //Function for playerLaser to destroy Boss
    func playerLaserHitBoss (laserNode:SKSpriteNode, bossNode:SKSpriteNode) {
        
        //Create explosion effect
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
            score += 15
            GameScene.bossIsDead = true
           
            let endGameTransistion = SKAction.run() {
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                let complateLevel = LevelOneComplete(fileNamed: "LevelOneComplete")!
                complateLevel.score = GameScene.score
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
        
        print("laser hit boss")
        print(bossHealth)
    }
    
    //Function for when player and Shield Pickup collide
    func playerHitShieldPickup (playerNode:SKSpriteNode, shieldPickupNode:SKSpriteNode) {
        
        //Play Shield Pickup sound effect
        self.run(SKAction.playSoundFileNamed("shield.wav", waitForCompletion: false))
        
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
        
        print("Shield Pickup")
    }
    
    //Function for when player and Life Pickup collide
    func playerHitLifePickup (playerNode:SKSpriteNode, lifePickupNode:SKSpriteNode) {
       
        let lifeNode = SKSpriteNode(imageNamed: "Life")
        lifeNode.position = CGPoint(x: 300, y: 425)
        addChild(lifeNode)
        GameScene.livesArray.append(lifeNode)
        
        //remove sprites
        trash.append(lifePickupNode)
        
        print("Life Pickup")
    }
    
    //Function for when player and Life Pickup collide
    func playerHitWeaponPickup (playerNode:SKSpriteNode, weaponPickupNode:SKSpriteNode) {
        
        //Play Weapon pickup sound effect
        self.run(SKAction.playSoundFileNamed("powerUp.wav", waitForCompletion: false))
        
        laser1 = false
        laser2 = true
        
        //remove sprites
        trash.append(weaponPickupNode)
        
        print("Weapon Pickup")
    }
    
    //Function for when player and astroid collide
    func playerHitAstroid(playerNode:SKSpriteNode, astroidNode:SKSpriteNode) {
        
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = astroidNode.position
        explosion.zPosition = 3
        addChild(explosion)
        
        print("Player hit astroid")
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        //astroidNode.removeFromParent()
        trash.append(astroidNode)
        
        if invincible == true && laser2 == true {
            laser1 = false
            laser2 = true
        }
        else if invincible == false && laser2 == true {
            laser1 = true
            laser2 = false
        }

        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosion)
         }
        
        //Removes a life when hit
        if GameScene.livesArray.count > 0 && invincible == false {
            let lifeNode = GameScene.livesArray.first
            lifeNode?.removeFromParent()
            GameScene.livesArray.removeFirst()
            
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
        
        //Remove player when all lives are gone
        if GameScene.livesArray.count == 0 {
            //playerNode.removeFromParent()
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
        
        let explosionA = SKEmitterNode(fileNamed: "Explosion")!
        explosionA.position = enemyNode.position
        explosionA.zPosition = 3
        addChild(explosionA)
        
        print("Player hit enemy")
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        trash.append(enemyNode)
        
        if invincible == true && laser2 == true {
            laser1 = false
            laser2 = true
        }
        else if invincible == false && laser2 == true {
            laser1 = true
            laser2 = false
        }
        
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosionA)
         }
        
        //Removes a life when hit
        if GameScene.livesArray.count > 0 && invincible == false {
            let lifeNode = GameScene.livesArray.first
            lifeNode?.removeFromParent()
            GameScene.livesArray.removeFirst()
            
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
        
        //Remove player when all lives are gone
        if GameScene.livesArray.count == 0 {
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
        
        let explosionA = SKEmitterNode(fileNamed: "Explosion")!
        explosionA.position = bossNode.position
        explosionA.zPosition = 3
        addChild(explosionA)
        
        print("Player hit boss")
    
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        if invincible == true && laser2 == true {
            laser1 = false
            laser2 = true
        }
        else if invincible == false && laser2 == true {
            laser1 = true
            laser2 = false
        }
        
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosionA)
                //self.trash.append(explosionB)
         }
        
        //Removes a life when hit
        if GameScene.livesArray.count > 0 && invincible == false {
            let lifeNode = GameScene.livesArray.first
            lifeNode?.removeFromParent()
            GameScene.livesArray.removeFirst()
            
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
        
        //Remove player when all lives are gone
        if GameScene.livesArray.count == 0 {
            //playerNode.removeFromParent()
            trash.append(playerNode)
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOver = GameOverScene(fileNamed: "GameOverScene")!
            gameOver.score = GameScene.score
            gameOver.scaleMode = scaleMode
            self.view?.presentScene(gameOver, transition: transition)
        }
    }
    
    func playerHitEnemyLaser(playerNode:SKSpriteNode, enemyLaserNode:SKSpriteNode) {
        
        let explosionA = SKEmitterNode(fileNamed: "Explosion")!
        explosionA.position = playerNode.position
        explosionA.zPosition = 3
        addChild(explosionA)
        
        print("Player hit enemy laser")
    
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        //enemyNode.removeFromParent()
        trash.append(enemyLaserNode)
        
        if invincible == true && laser2 == true {
            laser1 = false
            laser2 = true
        }
        else if invincible == false && laser2 == true {
            laser1 = true
            laser2 = false
        }
        
        self.run(SKAction.wait(forDuration: 2)) {[weak self] in
                guard let `self` = self else {return}
                self.trash.append(explosionA)
         }
        
        //Removes a life when hit
        if GameScene.livesArray.count > 0 && invincible == false {
            let lifeNode = GameScene.livesArray.first
            lifeNode?.removeFromParent()
            GameScene.livesArray.removeFirst()
            
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
        
        //Remove player when all lives are gone
        if GameScene.livesArray.count == 0 {
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
        //player.position.y += yAcceleration * 20
        
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
        fireLaser()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (GameScene.bossIsDead == true) {
            reportScoreToGameCenter(score: Int64(GameScene.score))
        }
    }
    
    func reportScoreToGameCenter(score: Int64) {
        GameKitHelper.sharedInstance.reportScore(score: score,forLeaderboardID:leaderboardID)
    }
    
    
    
    
    
    
}

