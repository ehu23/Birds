//
//  MenuScene.swift
//  Birds
//
//  Created by Edward Hu on 9/9/18.
//  Copyright © 2018 Edward Hu. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {

    var sceneManagerDelegate: SceneManagerDelegate?
    
    override func didMove(to view: SKView) {
        setupMenu()
    }
    
    func setupMenu() {
        let background = SKSpriteNode(imageNamed: "menuBackground")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.zPosition = ZPosition.background
        background.aspectScale(to: frame.size, width: true, multiplier: 1.0)
        addChild(background)
        
        let button = SpriteKitButton(defaultButtonImage: "playButton", action: goToLevelScene, index: 0)
        button.position = CGPoint(x: frame.midX, y: frame.midY*0.8)
        button.zPosition = ZPosition.hudLabel
        button.aspectScale(to: frame.size, width: false, multiplier: 0.2)
        addChild(button)
    }
    
    func goToLevelScene(_: Int) {
        sceneManagerDelegate?.presentLevelScene()
    }
}
