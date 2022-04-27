//
//  LevelOneComplete.swift
//  CptFlash
//
//  Created by James Murphy on 23/04/2022.
//

import SpriteKit

class LevelOneComplete: SKScene {
    
    var score:Int = 0
    
    var scoreLabel:SKLabelNode!
    var continueButtonNode1:SKSpriteNode!
    
    override func didMove(to view: SKView) {
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        scoreLabel.text = "\(score)"
        
        continueButtonNode1 = self.childNode(withName: "continueButton1") as! SKSpriteNode
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first
        
        if let location = touch?.location(in: self) {
            let nodesArray = self.nodes(at: location)
            
            if nodesArray.first?.name == "continueButton1" {
                
                let nextScene = IntroScene1(fileNamed: "IntroScene1")!
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                nextScene.scaleMode = scaleMode
                self.view?.presentScene(nextScene, transition: transition)
            }
        }
    }
    
}
