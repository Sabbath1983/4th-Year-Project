//
//  AchievementsHelper.swift
//  CptFlash
//
//  Created by James Murphy on 21/04/2022.
//

import Foundation
import GameKit

class AchievementsHelper {
    
    static let LikeABossAchievementId = "com.fyp.flash.likeABoss"
    
    
    class func achievenemtForBoss(/*boss: SKSpriteNode*/) -> GKAchievement {
        
        let bossAchievement = GKAchievement(identifier: AchievementsHelper.LikeABossAchievementId)

        bossAchievement.percentComplete = 100
        bossAchievement.showsCompletionBanner = true
        
        return bossAchievement
    }
}
