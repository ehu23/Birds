//
//  GameScene.swift
//  Birds
//
//  Created by Edward Hu on 9/9/18.
//  Copyright © 2018 Edward Hu. All rights reserved.
//

import SpriteKit

enum RoundState {
    case ready, flying, finished, animating, gameOver
}

class GameScene: SKScene {
    var sceneManagerDelegate: SceneManagerDelegate?

    var mapNode = SKTileMapNode()
    
    let gameCamera = GameCamera()
    
    var panRecognizer = UIPanGestureRecognizer()
    var pinchRecognizer = UIPinchGestureRecognizer()
    var maxScale: CGFloat = 0
    
    var bird = Bird(type: .red)
    var birds = [Bird]()
    var enemies = 0 {
        didSet {
            if enemies < 1 {
                roundState = .gameOver
                presentPopup(victory: true)
            }
        }
    }
    let anchor = SKNode()
    var level: Int?
    
    var roundState = RoundState.ready
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        guard let level = level else {return}
        guard let levelData = LevelData(level: level) else {return}
        
        for birdColor in levelData.birds {
            if let newBirdType = BirdType(rawValue: birdColor) {
                birds.append(Bird(type: newBirdType))
            }
        }
        
        setupLevel()
        setupGestureRecognizers()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch roundState {
        case .ready:
            if let touch = touches.first { //get first touch
                let location = touch.location(in: self)
                if bird.contains(location) {
                    panRecognizer.isEnabled = false //dont move camera anymore
                    bird.grabbed = true
                    bird.position = location
                }
            }
        case .flying:
            break
        case .finished:
            guard let view = view else {return}
            roundState = .animating
            let moveCameraBackAction = SKAction.move(to: CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2), duration: 2.0)
            moveCameraBackAction.timingMode = .easeInEaseOut
            gameCamera.run(moveCameraBackAction) {
                self.panRecognizer.isEnabled = true
                self.addBird()
            }
        case .animating:
            break
        case .gameOver:
            break
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { //if a touch is moving on a screen
        if let touch = touches.first {
            if bird.grabbed {
                let location = touch.location(in: self)
                bird.position = location
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if bird.grabbed {
            gameCamera.setConstraints(with: self, and: mapNode.frame, to: bird)
            bird.grabbed = false
            bird.flying = true
            roundState = .flying
            constraintToAnchor(active: false)
            
            let dx = anchor.position.x - bird.position.x
            let dy = anchor.position.y - bird.position.y
            let impulse = CGVector(dx: dx, dy: dy)
            bird.physicsBody?.applyImpulse(impulse)
            bird.isUserInteractionEnabled = false
        }
    }
    func setupGestureRecognizers() {
        guard let view = view else {return}
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        view.addGestureRecognizer(panRecognizer)
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        view.addGestureRecognizer(pinchRecognizer)
    }
    
    func setupLevel() {
        if let mapNode = childNode(withName: "Tile Map Node") as? SKTileMapNode {
            self.mapNode = mapNode
            maxScale = mapNode.mapSize.width/frame.size.width
        }
        
        addCamera()
        
        for child in mapNode.children {
            if let child = child as? SKSpriteNode {
                guard let name = child.name else {continue}
                switch name {
                case "wood","stone","glass":
                    if let block = createBlock(from: child, name: name) {
                        mapNode.addChild(block)
                        child.removeFromParent()
                    }
                case "orange":
                    if let enemy = createEnemy(from: child, name: name) {
                        mapNode.addChild(enemy)
                        enemies += 1
                        child.removeFromParent()
                    }
                default:
                    break
                }
                
            }
        }
        
        let physicsRect = CGRect(x: 0, y: mapNode.tileSize.height, width: mapNode.frame.size.width, height: mapNode.frame.size.height - mapNode.tileSize.height)
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsRect)
        physicsBody?.categoryBitMask = PhysicsCategories.edge
        physicsBody?.contactTestBitMask = PhysicsCategories.bird | PhysicsCategories.block
        physicsBody?.collisionBitMask = PhysicsCategories.all
        anchor.position = CGPoint(x: mapNode.frame.midX/2, y: mapNode.frame.midY/2)
        addChild(anchor)
        addSlingshot()
        addBird()
    }
    
    func addCamera() {
        guard let view = view else {return}
        addChild(gameCamera)
        gameCamera.position = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
        camera = gameCamera
        gameCamera.setConstraints(with: self, and: mapNode.frame, to: nil)
    }
    
    func addSlingshot() {
        let slingshot = SKSpriteNode(imageNamed: "slingshot")
        let scaleSize = CGSize(width: 0, height: mapNode.frame.midY/2 - mapNode.tileSize.height/2)
        slingshot.aspectScale(to: scaleSize, width: false, multiplier: 1.0)
        slingshot.position = CGPoint(x: anchor.position.x, y: mapNode.tileSize.height + slingshot.size.height/2)
        slingshot.zPosition = ZPosition.obstacles
        mapNode.addChild(slingshot)
    }
    
    func addBird() {
        if birds.isEmpty {
            roundState = .gameOver
            presentPopup(victory: false)
            return
        }
        
        bird = birds.removeFirst()
        bird.physicsBody = SKPhysicsBody(rectangleOf: bird.size)
        bird.physicsBody?.categoryBitMask = PhysicsCategories.bird
        bird.physicsBody?.contactTestBitMask = PhysicsCategories.all
        bird.physicsBody?.collisionBitMask = PhysicsCategories.block | PhysicsCategories.edge
        bird.physicsBody?.isDynamic = false
        bird.position = anchor.position
        bird.zPosition = ZPosition.bird
        addChild(bird)
        bird.aspectScale(to: mapNode.tileSize, width: true, multiplier: 1.0)
        constraintToAnchor(active: true)
        roundState = .ready
        
    }
    
    func createEnemy(from placeholder: SKSpriteNode, name: String) -> Enemy? {
        guard let enemyType = EnemyType(rawValue: name) else {return nil}
        let enemy = Enemy(type: enemyType)
        enemy.size = placeholder.size
        enemy.position = placeholder.position
        enemy.zPosition = ZPosition.obstacles
        enemy.createPhysicsBody()
        return enemy
    }
    
    func createBlock(from placeholder: SKSpriteNode, name: String) -> Block? {
        guard let type = BlockType(rawValue: name) else {return nil}
        let block = Block(type: type)
        block.size = placeholder.size
        block.position = placeholder.position
        block.zPosition = ZPosition.obstacles
        block.zRotation = placeholder.zRotation
        block.createPhysicsBody()
        return block
    }
    func constraintToAnchor(active: Bool) {
        if active {
            let slingRange = SKRange(lowerLimit: 0.0, upperLimit: bird.size.width*3)
            let positionConstraint = SKConstraint.distance(slingRange, to: anchor)
            bird.constraints = [positionConstraint]
        } else {
            bird.constraints?.removeAll()
        }
    }
    
    func presentPopup(victory: Bool) {
        if victory {
            let popup = Popup(type: 0, size: frame.size)
            popup.zPosition = ZPosition.hudBackground
            popup.popupButtonHandlerDelegate = self
            gameCamera.addChild(popup)
        } else {
            let popup = Popup(type: 1, size: frame.size)
            popup.zPosition = ZPosition.hudBackground
            popup.popupButtonHandlerDelegate = self
            gameCamera.addChild(popup)
        }
    }
    
    override func didSimulatePhysics() {
        guard let physicsBody = bird.physicsBody else {return}
        if roundState == .flying && physicsBody.isResting {
            gameCamera.setConstraints(with: self, and: mapNode.frame, to: nil)
            bird.removeFromParent()
            roundState = .finished
        }
    }
    
    
    
}

extension GameScene: PopupButtonHandlerDelegate {
    
    func menuTapped() {
        sceneManagerDelegate?.presentMenuScene()
    }
    
    func nextTapped() {
        if let level = level {
            sceneManagerDelegate?.presentGameSceneFor(level: level + 1)
        }
    }
    
    func retryTapped() {
        if let level = level {
            sceneManagerDelegate?.presentGameSceneFor(level: level)
        }
    }
    
    
}
extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch mask {
        case PhysicsCategories.bird | PhysicsCategories.block, PhysicsCategories.block | PhysicsCategories.edge:
            if let block = contact.bodyB.node as?  Block {
                block.impact(with: Int(contact.collisionImpulse))
            } else if let block = contact.bodyA.node as? Block {
                block.impact(with: Int(contact.collisionImpulse))
            }
            if let bird = contact.bodyA.node as? Bird {
                bird.flying = false
            } else if let bird = contact.bodyB.node as? Bird {
                bird.flying = false
            }
            
        case PhysicsCategories.block | PhysicsCategories.block:
            if let block = contact.bodyA.node as? Block {
                block.impact(with: Int(contact.collisionImpulse))
            }
            if let block = contact.bodyB.node as? Block {
                block.impact(with: Int(contact.collisionImpulse))
            }
    
        case PhysicsCategories.bird | PhysicsCategories.edge:
            bird.flying = false
            
        case PhysicsCategories.bird | PhysicsCategories.enemy:
            if let enemy = contact.bodyA.node as? Enemy {
                if enemy.impact(with: Int(contact.collisionImpulse)) {
                    enemies -= 1
                }
            } else if let enemy = contact.bodyB.node as? Enemy {
                if enemy.impact(with: Int(contact.collisionImpulse)) {
                    enemies -= 1
                }
            }
        default:
            break
        }
    }
}

extension GameScene {
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        guard let view = view else {return}
        let translation = sender.translation(in: view) * gameCamera.yScale //can use xscale too
        gameCamera.position = CGPoint(x: gameCamera.position.x - translation.x, y: gameCamera.position.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: view)
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        guard let view = view else {return}
        if sender.numberOfTouches == 2 {
            let locationInView = sender.location(in: view)
            let location = convertPoint(fromView: locationInView)
            if sender.state == .changed {
                let convertedScale = 1/sender.scale
                let newScale = gameCamera.yScale * convertedScale //y or x scale doesnt matter
                if newScale < maxScale && newScale > 0.5 {
                    gameCamera.setScale(newScale)                 //because this <- sets x and y
                }
                let locationAfterScale = convertPoint(fromView: locationInView)
                let locationDelta = location - locationAfterScale
                let newPosition = gameCamera.position + locationDelta
                gameCamera.position = newPosition
                sender.scale = 1.0
                
                gameCamera.setConstraints(with: self, and: mapNode.frame, to: nil)
                
            }
        }
    }
}
