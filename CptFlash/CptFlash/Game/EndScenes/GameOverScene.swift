//
//  GameOverScene.swift
//  CptFlash
//
//  Created by James Murphy on 08/02/2022.
//

import SpriteKit
import UIKit

class GameOverScene: SKScene {
    
    static var viewController: UIViewController?
    
    var score:Int = 0
    
    var scoreLabel:SKLabelNode!
    var newGameButtonNode:SKSpriteNode!
    var mainMenuButtonNode:SKSpriteNode!
    
    override func didMove(to view: SKView) {
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        scoreLabel.text = "\(score)"
        
        newGameButtonNode = self.childNode(withName: "newGameButton") as! SKSpriteNode
        mainMenuButtonNode = self.childNode(withName: "menuButton") as! SKSpriteNode
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
            
            if nodesArray.first?.name == "menuButton" {
//                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                let vc = storyboard.instantiateViewController(withIdentifier :"MainMenuViewController")
//                self.view?.window?.rootViewController?.present(vc, animated: true, completion: nil)
//                self.view?.presentScene(nil)
                
                //self.view!.window!.rootViewController!.performSegue(withIdentifier: "goMainMenu", sender: self)
                GameOverScene.viewController?.performSegue(withIdentifier: "goMainMenu", sender: self)
                
//                var vc: UIViewController = UIViewController()
//                vc = self.view!.window!.rootViewController!
//                viewController?.performSegue(withIdentifier: "goMainMenu", sender: vc)
            }
        }
    }

}
