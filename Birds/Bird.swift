//
//  Bird.swift
//  Birds
//
//  Created by Edward Hu on 9/9/18.
//  Copyright © 2018 Edward Hu. All rights reserved.
//

import SpriteKit


enum BirdType: String {
    case red, blue, yellow, gray  //raw value is the exact string of the cases
}

class Bird: SKSpriteNode {
    
    let birdType: BirdType
    var grabbed = false
    var flying = false {
        didSet { //didSet is an observer for this property
            if flying {
                physicsBody?.isDynamic = true
            }
        }
    }
    
    init(type: BirdType) {
        birdType = type
        
        let texture = SKTexture(imageNamed: type.rawValue + "1")
        
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
