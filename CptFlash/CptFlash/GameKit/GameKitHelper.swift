//
//  GameKitHelper.swift
//  CptFlash
//
//  Created by James Murphy on 14/04/2022.
//

import UIKit
import Foundation
import GameKit

class GameKitHelper: NSObject {
    
    static let sharedInstance = GameKitHelper()
    static let PresentAuthenticationViewController = "PresentAuthenticationViewController"
    
    var authenticationViewController: UIViewController?
    var gameCenterEnabled = false
    
    func authenticateLocalPlayer() {
      // 1
        GKLocalPlayer.local.authenticateHandler =
        { (viewController, error) in
          // 2
          self.gameCenterEnabled = false
          if viewController != nil {
            // 3
            self.authenticationViewController = viewController
            NotificationCenter.default.post(name: NSNotification.Name(GameKitHelper.PresentAuthenticationViewController),
                                            object: self)
          } else if GKLocalPlayer.local.isAuthenticated {
            // 4
            self.gameCenterEnabled = true
          }
      }
    }
    
    func reportAchievements(achievements: [GKAchievement], errorHandler: ((Error?)->Void)? = nil) {
        guard gameCenterEnabled else {
            return
        }
        
        GKAchievement.report(achievements, withCompletionHandler: errorHandler)
    }
    
    func reportScore(score: Int64, forLeaderboardID leaderboardID: String, errorHandler: ((Error?)->Void)? = nil) {
        
        guard gameCenterEnabled else {
            return
        }
        
        //1
          let gkScore = GKScore(leaderboardIdentifier: leaderboardID)
          gkScore.value = score
        //2
          GKScore.report([gkScore], withCompletionHandler: errorHandler)
    }
    
    func showGKGameCenterViewController(viewController: UIViewController) {
        guard gameCenterEnabled else {
        return
      }
      
        //1
        let gameCenterViewController = GKGameCenterViewController()
      
        //2
        gameCenterViewController.gameCenterDelegate = self
      
        //3
        viewController.present(gameCenterViewController,
                             animated: true, completion: nil)
    }
  }

  extension GameKitHelper: GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
