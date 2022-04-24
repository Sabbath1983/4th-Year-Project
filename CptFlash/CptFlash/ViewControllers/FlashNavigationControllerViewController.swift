//
//  FlashNavigationControllerViewController.swift
//  CptFlash
//
//  Created by James Murphy on 14/04/2022.
//

import UIKit

class FlashNavigationControllerViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(showAuthenticationViewController),
            name: NSNotification.Name(
              GameKitHelper.PresentAuthenticationViewController),
            object: nil)
          GameKitHelper.sharedInstance.authenticateLocalPlayer()

        // Do any additional setup after loading the view.
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
