//
//  LevelTwoCompleted.swift
//  CptFlash
//
//  Created by James Murphy on 23/04/2022.
//

import SpriteKit

class LevelTwoComplete: SKScene {
    
    var score:Int = 0
    
    var scoreLabel:SKLabelNode!
    var continueButtonNode:SKSpriteNode!
    
    override func didMove(to view: SKView) {
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        scoreLabel.text = "\(score)"
        
        continueButtonNode = self.childNode(withName: "continueButton") as! SKSpriteNode
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first
        
        if let location = touch?.location(in: self) {
            let nodesArray = self.nodes(at: location)
            
            if nodesArray.first?.name == "continueButton" {
                //let gameScene = GameScene(size: self.size)
                let nextScene = GameScene(fileNamed: "GameSceneTwo")!
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                nextScene.scaleMode = scaleMode
                self.view?.presentScene(nextScene, transition: transition)
            }
        }
    }
    
}
