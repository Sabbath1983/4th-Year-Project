//
//  FlashNavigationController.swift
//  CptFlash
//
//  Created by James Murphy on 14/04/2022.
//

import UIKit

class FlashNavigationController: UINavigationController {

    override func viewDidLoad() {
      super.viewDidLoad()
      
      NotificationCenter.default.addObserver(self,
        selector: #selector(showAuthenticationViewController),
        name: NSNotification.Name(GameKitHelper.PresentAuthenticationViewController),
        object: nil)
      
      GameKitHelper.sharedInstance.authenticateLocalPlayer()
    }
    
    @objc func showAuthenticationViewController() {
      let gameKitHelper = GameKitHelper.sharedInstance
      
      if let authenticationViewController =
        gameKitHelper.authenticationViewController {
        topViewController?.present(
          authenticationViewController,
          animated: true, completion: nil)
      }
    }
    
    deinit {
      NotificationCenter.default.removeObserver(self)
    }

}
