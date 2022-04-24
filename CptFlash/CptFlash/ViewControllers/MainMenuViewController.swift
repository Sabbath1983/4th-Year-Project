//
//  MainMenuViewController.swift
//  CptFlash
//
//  Created by James Murphy on 21/04/2022.
//

import UIKit

class MainMenuViewController: UIViewController {

    
    @IBAction func StartButton(_ sender: UIButton) {
        
        if let GameViewController = storyboard?.instantiateViewController(withIdentifier: "GameViewController") as? GameViewController {
          navigationController?.pushViewController(GameViewController, animated: true)
        }
        
    }
    
    @IBAction func GameCenter(_ sender: UIButton) {
        GameKitHelper.sharedInstance.showGKGameCenterViewController(viewController: self)
    }
}
