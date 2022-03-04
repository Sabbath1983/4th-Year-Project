//
//  GameScene.swift
//  CptFlash
//
//  Created by James Murphy on 17/11/2021.
//  Music Title: A bit of hope By: David Fesliyan Website: https://www.fesliyanstudios.com/royalty-free-music
// Exposion sound effect: Explosion, 8-bit, 01.wav By: InspectorJ Website: https://freesound.org/people/InspectorJ/sounds/448226/
// Laser Sound effect: Title: Laser00.wav, By: sharesynth, Website: https://freesound.org/people/sharesynth/sounds/341236/

import SpriteKit
import GameplayKit
import CoreMotion


@objcMembers
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Player Image
    let player = SKSpriteNode(imageNamed: "Player.png")
    
    
    var bossHealth = 5
    
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
    
    //Array for differnet enemy ships
    var enemyArray = ["Enemy1"]
    
    //Array for Powerups
    var powerUpArray = ["shieldPickUp"]
    
    //For collision
    let playerCategory:UInt32 = 0x1 << 1
    let playerLaserCategory:UInt32 = 0x1 << 2
    let shieldPickupCategory:UInt32 = 0x1 << 3
    let astroidCategory:UInt32 = 0x1 << 4
    let enemyCategory:UInt32 = 0x1 << 5
    let bossCategory:UInt32 = 0x1 << 6
  
    //Moving player with Accelometer
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    //lives
    var livesArray:[SKSpriteNode]!
    
    //Create Music
    let music = SKAudioNode(fileNamed: "hope.mp3")
    
    override func didMove(to view: SKView) {
        
        //Call Lives method
        addLives()
        
        //Call AddBoss method
        //addBoss()
        
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
        
        //Player Physics for collision
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        //player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.isDynamic = true
        
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = astroidCategory | enemyCategory | bossCategory | shieldPickupCategory
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
        score = 0
        addChild(scoreLabel)
        
        //Timer to spawn astroids
        gameTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(addAstroid), userInfo: nil, repeats: true)
        
        //Timer to spawn enemy
        gameTimer = Timer.scheduledTimer(timeInterval: 0.85, target: self, selector: #selector(addEnemy), userInfo: nil, repeats: true)
        
        //Timer to spawn powerups
        gameTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(addPowerUps), userInfo: nil, repeats: true)
        
        //Timer to spawn Boss
        gameTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(addBoss), userInfo: nil, repeats: false)
        
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
    
    func addLives() {
        livesArray = [SKSpriteNode]()
        
        for life in 1...3 {
            let lifeNode = SKSpriteNode(imageNamed: "Life")
            lifeNode.position = CGPoint(x: 350 - CGFloat(4 - life) * lifeNode.size.width, y: 525)
            addChild(lifeNode)
            livesArray.append(lifeNode)
        }
    }
    
    func addPowerUps() {
        
        //powerUpArray = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: powerUpArray) as! [String]
        
        let shieldPickUp = SKSpriteNode(imageNamed: "Shield.png")
        
        //GameplayKit randomization services to spawn different astroids
        let randomPowerUpPosition = GKRandomDistribution(lowestValue: -350, highestValue: 350)
        //Randomly spawn astroid in differnet positions
        let position = CGFloat(randomPowerUpPosition.nextInt())
        shieldPickUp.position = CGPoint(x: position, y: self.frame.size.height + shieldPickUp.size.height)
        
        shieldPickUp.zPosition = 1
        
        //addChild(shieldPickUp)
        
        //Astroid Physics for collision
        shieldPickUp.physicsBody = SKPhysicsBody(circleOfRadius: shieldPickUp.size.width / 2)
        shieldPickUp.physicsBody?.isDynamic = true
        
        shieldPickUp.physicsBody?.categoryBitMask = shieldPickupCategory
        shieldPickUp.physicsBody?.contactTestBitMask = playerCategory
        //avoid any unwanted collisions
        shieldPickUp.physicsBody?.collisionBitMask = 0
        
        //Shield Pickup speed
        let animationDuration:TimeInterval = 6
        
        //Clean up, remove astroids once reached a certain distince
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -700), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        shieldPickUp.run(SKAction.sequence(actionArray))
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
    
    func addEnemy() {
        
        enemyArray = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: enemyArray) as! [String]
        
        //Select enemy from array
        let enemy = SKSpriteNode(imageNamed: enemyArray[0])
        
        //GameplayKit randomization services to spawn different enemies
        let randomEnemyPosition = GKRandomDistribution(lowestValue: -350, highestValue: 350)
        //Randomly spawn enemy in differnet positions
        let position = CGFloat(randomEnemyPosition.nextInt())
        enemy.position = CGPoint(x: position, y: self.frame.size.height + enemy.size.height)
        
        enemy.zPosition = 1
        
        //Enemy Physics for collision
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width / 2)
        enemy.physicsBody?.isDynamic = true
        
        enemy.physicsBody?.categoryBitMask = enemyCategory
        enemy.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        //avoid any unwanted collisions
        enemy.physicsBody?.collisionBitMask = 0
       
        
        if score >= 20 {
         addChild(enemy)
        }
        
        //Enemy speed
        let animationDuration:TimeInterval = 6
        
        //Clean up, remove enemy once reached a certain distince
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -700), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        enemy.run(SKAction.sequence(actionArray))
    }
    
    func addBoss() {
        
        //Boss Image
        let boss = SKSpriteNode(imageNamed: "BossA.png")
        
        boss.position.y = 600
        boss.zPosition = 1
        addChild(boss)
    
        //BossPhysics for collision
        boss.physicsBody = SKPhysicsBody(circleOfRadius: boss.size.width / 2)
        boss.physicsBody?.isDynamic = true
        
        boss.physicsBody?.categoryBitMask = bossCategory
        boss.physicsBody?.contactTestBitMask = playerLaserCategory | playerCategory
        //avoid any unwanted collisions
        boss.physicsBody?.collisionBitMask = 0
        
        //boss speed
        let animationDuration:TimeInterval = 10
        
        //Clean up, remove boss once reached a certain distince
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: 0, y: -700), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        boss.run(SKAction.sequence(actionArray))
    }
    
    func fireLaser() {
        
        //Sound effect
        self.run(SKAction.playSoundFileNamed("laser.wav", waitForCompletion: false))
        
        //Create and position laser
        let playerLaser = SKSpriteNode(imageNamed: "laser")
        playerLaser.position = player.position
        playerLaser.position.y += 65
        
        //Laser Physics
        playerLaser.physicsBody = SKPhysicsBody(circleOfRadius: playerLaser.size.width / 2)
        playerLaser.physicsBody?.isDynamic = true
        
        playerLaser.physicsBody?.categoryBitMask = playerLaserCategory
        playerLaser.physicsBody?.contactTestBitMask = astroidCategory | enemyCategory
        //avoid any unwanted collisions
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
        laserNode.removeFromParent()
        astroidNode.removeFromParent()
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
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
        laserNode.removeFromParent()
        enemyNode.removeFromParent()
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
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
        laserNode.removeFromParent()
        //bossNode.removeFromParent()
        
        if bossHealth > 1 {
            //Remove Boss Health
            bossHealth = bossHealth - 1
        }
        else {
            //Remove Sprite
            bossNode.removeFromParent()
            //Add score
            score += 15
            
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            let winGame = WinScene(fileNamed: "WinScene")!
            winGame.score = self.score
            winGame.scaleMode = scaleMode
            self.view?.presentScene(winGame, transition: transition)
        }
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        print("laser hit boss")
        print(bossHealth)
        
        
    }
    
    //Function for when player and Shield Pickup collide
    func playerHitShieldPickup (playerNode:SKSpriteNode, shieldPickupNode:SKSpriteNode) {
        
        let shield = SKSpriteNode(imageNamed: "ShieldActive")
        shield.position = playerNode.position
        shield.zPosition = 2
        //addChild(shield)
        shieldPickupNode.removeFromParent()
    }
    
    //Function for when player and astroid collide
    func playerHitAstroid(playerNode:SKSpriteNode, astroidNode:SKSpriteNode) {
        
        let explosionA = SKEmitterNode(fileNamed: "Explosion")!
        explosionA.position = astroidNode.position
        explosionA.zPosition = 3
        addChild(explosionA)
        
        print("Player hit astroid")
        
//        let explosionB = SKEmitterNode(fileNamed: "Explosion")!
//        explosionB.position = playerNode.position
//        explosionB.zPosition = 3
//        addChild(explosionB)
        
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        //playerNode.removeFromParent()
        astroidNode.removeFromParent()
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {
            explosionA.removeFromParent()
            //explosionB.removeFromParent()
        }
        
        //Removes a life when hit
        if livesArray.count > 0 {
            let lifeNode = livesArray.first
            lifeNode?.removeFromParent()
            livesArray.removeFirst()
        }
        
        //Remove player when all lives are gone
        if livesArray.count == 0 {
            playerNode.removeFromParent()
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOver = GameOverScene(fileNamed: "GameOverScene")!
            gameOver.score = self.score
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
        
//        let explosionB = SKEmitterNode(fileNamed: "Explosion")!
//        explosionB.position = playerNode.position
//        explosionB.zPosition = 3
//        addChild(explosionB)
    
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        //playerNode.removeFromParent()
        enemyNode.removeFromParent()
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {
            explosionA.removeFromParent()
            //explosionB.removeFromParent()
        }
        
        //Removes a life when hit
        if livesArray.count > 0 {
            let lifeNode = livesArray.first
            lifeNode?.removeFromParent()
            livesArray.removeFirst()
        }
        
        //Remove player when all lives are gone
        if livesArray.count == 0 {
            playerNode.removeFromParent()
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOver = GameOverScene(fileNamed: "GameOverScene")!
            gameOver.score = self.score
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
        
        let explosionB = SKEmitterNode(fileNamed: "Explosion")!
        explosionB.position = playerNode.position
        explosionB.zPosition = 3
        addChild(explosionB)
    
        //Play explosion sound effect
        self.run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        //remove sprites
        playerNode.removeFromParent()
        bossNode.removeFromParent()
        
        //Remove explosion effect after a delay
        self.run(SKAction.wait(forDuration: 2)) {
            explosionA.removeFromParent()
            explosionB.removeFromParent()
        }
        
        let transition = SKTransition.flipHorizontal(withDuration: 0.5)
        let gameOver = GameOverScene(fileNamed: "GameOverScene")!
        gameOver.score = self.score
        gameOver.scaleMode = scaleMode
        self.view?.presentScene(gameOver, transition: transition)
    }
    
    //Movement using the Accelometer
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 50
        
        //if player reaches end of screen, player will come back thee other side of the screen
        if player.position.x < -400 {
            player.position = CGPoint(x: 400, y: player.position.y)
        } else if player.position.x > 400 {
            player.position = CGPoint(x: -400, y: player.position.y)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
       
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireLaser()
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
}
