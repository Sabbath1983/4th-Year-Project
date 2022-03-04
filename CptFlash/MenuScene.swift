//
//  MenuScene.swift
//  CptFlash
//
//  Created by James Murphy on 01/02/2022.
//

import SpriteKit

class MenuScene: SKScene {
    
    var mmStarfield:SKEmitterNode!
    
    var newGameButtonNode:SKSpriteNode!
    var optionsButtonNode:SKSpriteNode!
    var highScoresButtonNode:SKSpriteNode!
    
    override func didMove(to view: SKView) {
        
        mmStarfield = self.childNode(withName: "Starfield") as! SKEmitterNode
        mmStarfield.advanceSimulationTime(10)
        
        newGameButtonNode = self.childNode(withName: "newGameButton") as! SKSpriteNode
    
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first
        
        if let location = touch?.location(in: self) {
            let nodesArray = self.nodes(at: location)
            
            if nodesArray.first?.name == "newGameButton" {
                //let gameScene = GameScene(size: self.size)
                let gameScene = GameScene(fileNamed: "GameScene")!
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                gameScene.scaleMode = scaleMode
                self.view?.presentScene(gameScene, transition: transition)
            }
        }
    }

}
