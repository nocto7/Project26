//
//  GameScene.swift
//  Project26
//
//  Created by kirsty darbyshire on 02/05/2019.
//  Copyright © 2019 nocto. All rights reserved.
//

import CoreMotion
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    var playerStartPosition: CGPoint?
    
    var motionManager: CMMotionManager?
    var isGameOver = false
    var level = 1
    var isGameFinished = false
    
    var scoreLabel: SKLabelNode!
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    enum CollisionTypes: UInt32 {
        case player = 1
        case wall = 2
        case star = 4
        case vortex = 8
        case finish = 16
        case teleport = 32
    }
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        scoreLabel =  SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
        
        loadLevel()
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
    }
    

    
    func loadLevel() {
        guard let levelURL = Bundle.main.url(forResource: "level\(level)", withExtension: "txt") else {
            gameFinished()
            return
        }
        guard let levelString = try? String(contentsOf: levelURL) else { fatalError("could not load level\(level).txt from the app bundle") }
        
        clearUp()
        
        let lines = levelString.components(separatedBy: "\n")
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: 64 * column + 32, y: 64 * row + 32)
                
                if      letter == "x" { addWall(at: position) }
                else if letter == "v" { addVortex(at: position) }
                else if letter == "s" { addStar(at: position) }
                else if letter == "t" { addTeleport(at: position) }
                else if letter == "f" { addFinish(at: position) }
                else if letter == "p" { createPlayer(at: position) }
                else if letter == " " { } // empty space, do nothing
                else { fatalError("Unknown level letter: \(letter)") }
            }
        }
    }
    
    func gameFinished() {
        let node = SKLabelNode()
        node.numberOfLines = 0
        node.text = "Game Over!\nScore: \(score).\nTouch the screen to play again"
        node.name = "gameover"
        node.fontColor = .purple
        node.fontName = "Chalkduster"
        node.fontSize = 48
        node.zPosition = 2
        node.position = CGPoint(x: 512, y: 386)
        node.horizontalAlignmentMode = .center
        node.verticalAlignmentMode = .center
        addChild(node)
        isGameFinished = true
    }
        
    func startGame() {
        score = 0
        level = 1
        loadLevel()
    }

    
    func clearUp() {
        let namesToRemove = ["wall", "vortex", "star", "finish", "player", "teleport", "gameover"]
        for node in children {
            guard let nodeName = node.name else { continue }
            if namesToRemove.contains(nodeName) {
                node.removeFromParent()
            }
        }
    }
    
    func addWall(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "block")
        node.name = "wall"
        node.position = position
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        node.physicsBody?.isDynamic = false
        addChild(node)
    }
    
    func addVortex(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "vortex")
        node.name = "vortex"
        node.position = position
        
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi, duration: 1)))
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.isDynamic = false
        addChild(node)
    }
    
    func addTeleport(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "teleport")
        node.name = "teleport"
        node.position = position
        
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi, duration: 1)))
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.categoryBitMask = CollisionTypes.teleport.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.isDynamic = false
        addChild(node)
    }
    
    func deactivateTeleport(_ teleport: SKNode) {
        if teleport.name != "teleport" { return }
        let hide = SKAction.hide()
        let wait = SKAction.wait(forDuration: 5)
        let show = SKAction.unhide()
        let sequence = SKAction.sequence([hide, wait, show])
        teleport.run(sequence)
    }
    
    func addStar(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "star")
        node.position = position
        node.name = "star"
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func addFinish(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "finish")
        node.position = position
        node.name = "finish"
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func createPlayer() {
        guard let startPosition = playerStartPosition else { return }
        createPlayer(at: startPosition)
    }
    
    func createPlayer(at position: CGPoint) {
        player = SKSpriteNode(imageNamed: "player")
        player.name = "player"
        player.position = position
        playerStartPosition = position
        player.zPosition = 1
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue | CollisionTypes.teleport.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        addChild(player)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
        
        if isGameFinished {
            startGame()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameOver == false else { return }
        
        #if targetEnvironment(simulator)
        if let lastTouchPosition = lastTouchPosition {
            let diff = CGPoint(x: lastTouchPosition.x - player.position.x, y: lastTouchPosition.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
        #else
        if let accelerometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
        #endif
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        if nodeA == player {
            playerCollided(with: nodeB)
        }
        if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    func playerCollided(with node: SKNode) {
        if node.name == "vortex" {
            score -= 1
            vanishIntoVortex(at: node.position)
        } else if node.name == "star" {
            node.removeFromParent()
            score += 1
        } else if node.name == "finish" {
            score += 10
            level += 1
            loadLevel()
        } else if node.name == "teleport" {
            if node.isHidden { return }
            deactivateTeleport(node)
            guard let newNode = findTeleport(for: node) else { return }
            teleport(from: node, to: newNode)
        }
    }
    
    func vanishIntoVortex(at position: CGPoint) {
        player.physicsBody?.isDynamic = false
        isGameOver = true

        let move = SKAction.move(to: position, duration: 0.25)
        let scale = SKAction.scale(to: 0.0001, duration: 0.25)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([move, scale, remove])
        player.run(sequence) { [weak self] in
            self?.createPlayer()
            self?.isGameOver = false
        }
    }
    
    func findTeleport(for node: SKNode) -> SKNode? {
        var teleports = findAllTeleports()
        teleports.removeAll { teleport -> Bool in
            teleport == node
        }
        guard let teleport = teleports.randomElement() else { return nil }
        return teleport
    }
    
    func findAllTeleports() -> [SKSpriteNode] {
        var teleports = [SKSpriteNode]()
        enumerateChildNodes(withName: "teleport") {
            childNode, _ in
            guard childNode is SKSpriteNode else { return }
            teleports.append(childNode as! SKSpriteNode)
        }
        return teleports
    }
    
    func teleport(from oldTeleport: SKNode, to newTeleport: SKNode) {
        player.physicsBody?.isDynamic = false
        isGameOver = true
        deactivateTeleport(newTeleport)
        let move = SKAction.move(to: oldTeleport.position, duration: 0.25)
        let scale = SKAction.scale(to: 0.0001, duration: 0.25)
        let hide = SKAction.hide()
        let teleportMove = SKAction.move(to: newTeleport.position, duration: 0.25)
        let show = SKAction.unhide()
        let scaleUp = SKAction.scale(to: 1, duration: 0.25)
        let sequence = SKAction.sequence([move, scale, hide, teleportMove, show, scaleUp])
        player.run(sequence) { [weak self] in
            self?.isGameOver = false
            self?.player.physicsBody?.isDynamic = true
        }
    }
    

}
