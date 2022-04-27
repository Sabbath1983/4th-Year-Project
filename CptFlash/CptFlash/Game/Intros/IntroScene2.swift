//
//  IntroScene2.swift
//  CptFlash
//
//  Created by James Murphy on 26/04/2022.
//

import SpriteKit

class IntroScene2: SKScene {
    
    var introStarfield:SKEmitterNode!
    var startButtonNode:SKSpriteNode!
    
    override func didMove(to view: SKView) {
        
        introStarfield = self.childNode(withName: "Starfield") as! SKEmitterNode
        introStarfield.advanceSimulationTime(10)
        startButtonNode = self.childNode(withName: "StartButton") as! SKSpriteNode
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first
        
        if let location = touch?.location(in: self) {
            let nodesArray = self.nodes(at: location)
            
            if nodesArray.first?.name == "StartButton" {
                //let gameScene = GameScene(size: self.size)
                let gameScene = GameSceneTwo(fileNamed: "GameSceneTwo")!
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                gameScene.scaleMode = scaleMode
                self.view?.presentScene(gameScene, transition: transition)
            }
        }
    }
}
