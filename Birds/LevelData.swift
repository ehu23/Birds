//
//  LevelData.swift
//  Birds
//
//  Created by Edward Hu on 9/9/18.
//  Copyright © 2018 Edward Hu. All rights reserved.
//

import Foundation

struct LevelData {
    
    let birds: [String]
    
    init?(level: Int) {
        guard let levelDictionary = Levels.levelsDictionary["Level_\(level)"] as? [String:Any] else {return nil}
        
        guard let birds = levelDictionary["Birds"] as? [String] else {return nil}
        
        self.birds = birds
    }
    
}
