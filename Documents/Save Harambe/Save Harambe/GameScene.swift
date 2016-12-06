//
//  GameScene.swift
//  Save Harambe
//
//  Created by Dominik Figueroa on 9/27/16.
//  Copyright © 2016 Dominik Figueroa. All rights reserved.
//

import SpriteKit
import GameplayKit

let PlayerCategoryName = "player"
let BabyCategoryName = "baby"
let GameMessageName = "gameMessage"
let ScopeCategoryName = "scope"
let ChaseBabyCategoryName = "ChaseBaby"

let BabyCategory: UInt32 = 0x1 << 0
let PlayerCategory: UInt32 = 0x1 << 1
let PlayerPassThrough: UInt32 = 0x1 << 5
let BabyPassThrough: UInt32 = 0x1 << 2
let CirclePassThrough: UInt32 = 0x1 << 3
let CircleCategory: UInt32 = 0x1 << 4
let CoinCategory: UInt32 = 0x1 << 7

let MapCategory: UInt32 = 0x1 << 6




class BabyNode : SKSpriteNode {
    var age: Int = 0
    var radius: CGFloat = 0
    var babyName: String = ""
    var postion = CGPoint(x: 0, y:0)
    var circle = SKShapeNode(circleOfRadius: 0)
}


class HealthBar : SKSpriteNode {
    var healthValue: Int = 100
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var babyStartMoving = false
    
    var coinWasEatenPreviousState:Bool = false
    var coinWasEaten:Bool = false
    var eatenTime = CACurrentMediaTime()

    
    var coinTextureAtlas = SKTextureAtlas()
    var coinTextureArray = [SKTexture()]
    
    
    var coinSprite = SKSpriteNode()
    
    
    var wallTileMapNode:SKTileMapNode!
    var grassTileMapNode:SKTileMapNode!
    
    var physicsBodyArray = [SKPhysicsBody]()
    
    
    let scoreLabel = SKLabelNode(fontNamed: "Arial")
    
    var score : Int = 0 {
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var isFingerOnPlayer = false
    var timeHasBeenInitialized = false
    var initialTime = 0
    
    lazy var gameState : GKStateMachine = GKStateMachine( states: [
        WaitingForTap(scene: self),
        Playing(scene : self),
        GameOver(scene: self)])
    
    
    var babyCounter = 0
    
    var babyArray = [BabyNode]()
    
    
    // creating joystick and hiding it
    var innerJoystick = SKSpriteNode(imageNamed: "joystickinner")
    var outerJoystick = SKSpriteNode(imageNamed: "joystickouter")
    
    var gameMessage = SKSpriteNode(imageNamed: "TapToPlay")
    
    
    // creating health bar
    var healthBar = HealthBar(color: UIColor.green, size: CGSize(width: 100, height: 30))
    
    

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        
        coinTextureAtlas = SKTextureAtlas(named: "cointextures")
        
        // must sort texture atlas before using
        for i in 0...coinTextureAtlas.textureNames.count-1 {
            
            let Name = "coin\(i).png"
            coinTextureArray.append(SKTexture(imageNamed: Name))
        }
        coinSprite = SKSpriteNode(imageNamed: "coin0.png")
        
        coinSprite.zPosition = 5
        
        let coinTextureFirst = SKTexture(imageNamed: "coin0.png")
        
        coinSprite.size = CGSize(width: 30, height: 30)
        coinSprite.position = CGPoint(x: 0, y: -30)
        coinSprite.physicsBody = SKPhysicsBody(texture: coinTextureFirst, size: CGSize(width: coinSprite.size.width, height: coinSprite.size.height))
        coinSprite.physicsBody?.affectedByGravity = false
        coinSprite.physicsBody?.categoryBitMask = CoinCategory
        coinSprite.physicsBody?.collisionBitMask = PlayerCategory
        coinSprite.physicsBody?.contactTestBitMask = PlayerCategory
        coinSprite.physicsBody?.isDynamic = false
        
        
        coinSprite.run(SKAction.repeatForever(SKAction.animate(with: coinTextureArray, timePerFrame: 0.05, resize: false, restore: false )))
        
        self.addChild(coinSprite)

        // initalizing grass tiles
        guard let grassTileMapNode = childNode(withName: "GrassTiles")
            as? SKTileMapNode else {
                fatalError("Grass tiles node not loaded")
        }
        self.grassTileMapNode = grassTileMapNode
        
        // intializing invisible tiles
        guard let wallTileMapNode = childNode(withName: "InvisibleWalls")
            as? SKTileMapNode else {
                fatalError("walls node not loaded")
        }
        self.wallTileMapNode = wallTileMapNode
        
        // setting physics for all invisible tiles
        for col in 0 ..< wallTileMapNode.numberOfColumns {
            
            for row in 0 ..< wallTileMapNode.numberOfRows {
                
                let titleDefinition = wallTileMapNode.tileDefinition(atColumn: col, row: row)

                // for every possible tile in the tile map check if it's a wall
                if let _ = titleDefinition?.userData?.value(forKey: "isWall") {
                
                    // only if it is a wall give it physics
                    let center = wallTileMapNode.centerOfTile(atColumn: col, row: row)
                    let physicsBody = SKPhysicsBody(rectangleOf: wallTileMapNode.tileSize, center: center)
                    
                    physicsBodyArray.append(physicsBody)
                }

            }
        }
        
        // set physics properties to every invisible wall
        wallTileMapNode.physicsBody = SKPhysicsBody(bodies: physicsBodyArray)
        wallTileMapNode.physicsBody?.affectedByGravity = false
        wallTileMapNode.physicsBody?.categoryBitMask = MapCategory
        wallTileMapNode.physicsBody?.collisionBitMask = PlayerCategory
        wallTileMapNode.physicsBody?.contactTestBitMask = PlayerCategory
        wallTileMapNode.physicsBody?.pinned = true
        wallTileMapNode.physicsBody?.allowsRotation = false
        
        

        // set timer/score
        scoreLabel.fontColor = UIColor.black
        scoreLabel.fontSize = 18
        scoreLabel.position = CGPoint(x: 0, y: 180)
        scoreLabel.zPosition = 7
        scoreLabel.text = "Score: \(score)"
        camera?.addChild(scoreLabel)
        
        
        // set joystick properties
        outerJoystick.zPosition = 4
        innerJoystick.zPosition = 4
        outerJoystick.position = CGPoint(x: 0.5, y: 0.5)
        innerJoystick.position = CGPoint(x: 0.5, y: 0.5)
        
        innerJoystick.isHidden = true
        outerJoystick.isHidden = true
        
        camera?.addChild(outerJoystick)
        camera?.addChild(innerJoystick)
        
        
        // set health bar properties
        healthBar.position = CGPoint(x: -355, y: 180)
        healthBar.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        healthBar.zPosition = 4
        camera?.addChild(healthBar)
 
        
        // setting physics in the scene
        physicsWorld.contactDelegate = self
        self.physicsBody!.isDynamic = false
        
        
        // creating player sprite with physics
        let player = childNode(withName: PlayerCategoryName) as! SKSpriteNode
        player.physicsBody!.categoryBitMask = PlayerCategory
        player.physicsBody!.contactTestBitMask = BabyCategory
        player.physicsBody!.collisionBitMask = BabyPassThrough | MapCategory
        player.physicsBody!.mass = 5
        player.physicsBody!.friction = 0.1
        
        
        // creating the chase baby
        let ChaseBaby = childNode(withName: ChaseBabyCategoryName) as! SKSpriteNode
        
        // creating chase baby's physics and physics
        ChaseBaby.physicsBody!.categoryBitMask = BabyCategory
        ChaseBaby.physicsBody!.contactTestBitMask = PlayerCategory | MapCategory
        ChaseBaby.physicsBody!.collisionBitMask = PlayerCategory | MapCategory
        ChaseBaby.physicsBody!.mass = 5
        ChaseBaby.physicsBody!.friction = 0.5
        
        
        // set up waiting for tap screen
        gameMessage.name = GameMessageName
        gameMessage.position = CGPoint(x: frame.midX, y: frame.midY)
        gameMessage.zPosition = 4
        gameMessage.setScale(0.0)        
        //camera?.addChild(gameMessage)
        addChild(gameMessage)
        
        gameState.enter(WaitingForTap.self)

        
        // initial camera adjustment
        updateCamera()
        
    }

    func destroyBaby(node: BabyNode) {
        node.circle.removeFromParent()
        node.removeFromParent()
    }
    
    
    func stopGeneratingBabies() {
        if(self.action(forKey: "spawning") != nil)
        {
            removeAction(forKey: "spawning")
        }
    }
    
    
    func generateBabies() {
        if(self.action(forKey: "spawning") != nil)
        {
            return
        }
        
        

        
        
        let timer = SKAction.wait(forDuration: 1, withRange: 0.2)
        
        let spawnNode = SKAction.run {
            
            // creating babyNode
            self.babyArray.append(BabyNode(imageNamed: "baby2"))
            self.babyArray[self.babyCounter].name = "enemy"
            
            let babyTexture = SKTexture(imageNamed: "baby2")
            
            
            // getting random X and Y positions
            let randomX = self.randomBetweenNumbers(firstNum: -self.wallTileMapNode.mapSize.width/2, secondNum: self.wallTileMapNode.mapSize.width/2)
            let randomY = self.randomBetweenNumbers(firstNum: -self.wallTileMapNode.mapSize.height/2, secondNum: self.wallTileMapNode.mapSize.height/2)
            
            
            
            // assigning random X and Y postions to babyNode
            self.babyArray[self.babyCounter].position = CGPoint(x: randomX, y: randomY)
            self.babyArray[self.babyCounter].zPosition = 2
            
            print(self.babyArray[self.babyCounter].position)
            
            
            // getting damage radius for baby - Alpha Channel texture mask physics body
            self.babyArray[self.babyCounter].radius = self.randomBetweenNumbers(firstNum: 40, secondNum: 130)
            self.babyArray[self.babyCounter].physicsBody = SKPhysicsBody(texture: babyTexture, size: CGSize(width: babyTexture.size().width, height: babyTexture.size().height))
            
            
            // making circle to be able to see damage radius attached to each baby
            self.babyArray[self.babyCounter].circle = SKShapeNode(circleOfRadius: self.babyArray[self.babyCounter].radius)
            self.babyArray[self.babyCounter].circle.position = self.babyArray[self.babyCounter].position
            self.babyArray[self.babyCounter].circle.zPosition = 2
            self.babyArray[self.babyCounter].circle.strokeColor = SKColor.black
            self.babyArray[self.babyCounter].circle.lineWidth = 5
            
            // flash/fade in circle before baby and cirlce physics are activated
            self.addChild(self.babyArray[self.babyCounter].circle)
            
            let myOrigColor:UIColor = UIColor.white.withAlphaComponent(0.5)
            let myFinalColor:UIColor = UIColor.red.withAlphaComponent(0.4)
            
            let colorFlashEffect = self.colorTransitionAction(fromColor: myOrigColor, toColor: myFinalColor, duration: 1.5)
            let colorFlashLoop = SKAction.repeatForever(colorFlashEffect)
            self.babyArray[self.babyCounter].circle.run(colorFlashLoop)
            
            let wait = SKAction.wait(forDuration: 10)
            self.run(wait)
            
            
            // giving circle physics properties
            self.babyArray[self.babyCounter].circle.physicsBody = SKPhysicsBody(circleOfRadius: self.babyArray[self.babyCounter].radius)
            self.babyArray[self.babyCounter].circle.physicsBody?.affectedByGravity = false
            self.babyArray[self.babyCounter].circle.physicsBody?.categoryBitMask = CircleCategory
            self.babyArray[self.babyCounter].circle.physicsBody?.collisionBitMask = PlayerPassThrough
            self.babyArray[self.babyCounter].circle.physicsBody?.contactTestBitMask = PlayerCategory
            
            
            // setting physics and collison for babies
            self.babyArray[self.babyCounter].physicsBody?.affectedByGravity = false
            self.babyArray[self.babyCounter].physicsBody?.pinned = true
            self.babyArray[self.babyCounter].physicsBody?.categoryBitMask = BabyCategory
            self.babyArray[self.babyCounter].physicsBody?.collisionBitMask = PlayerCategory
            self.babyArray[self.babyCounter].physicsBody?.contactTestBitMask = PlayerCategory
            
            
            self.addChild(self.babyArray[self.babyCounter])
            
            
            
            // increment baby counter for each baby made
            self.babyCounter += 1
            
            
            // iterate through the babies and make them older
            var i = 0
            while i < self.babyCounter {
                let randomAgeBoost = Int(self.randomBetweenNumbers(firstNum: 0, secondNum: 3))
                self.babyArray[i].age += randomAgeBoost
                
                
                // if any baby is over 10 kill him
                if self.babyArray[i].age > 18 {
                    self.destroyBaby(node: self.babyArray[i])
                    self.babyArray.remove(at: i)
                    i -= 1
                    self.babyCounter -= 1
                }
                
                i += 1
            }
        }
        

        
        for _ in 0..<9 {
            self.run(spawnNode)
        }
        
        
        let sequence = SKAction.sequence([timer, spawnNode])

        
        self.run(SKAction.repeatForever(sequence), withKey: "spawning")
        
    }
    
    // needed for the color transisiton fucntion
    var frgba = [CGFloat(0.92), CGFloat(0.87), CGFloat(0.38), CGFloat(0.5)]
    var trgba = [CGFloat(0.29), CGFloat(0.89), CGFloat(0.31), CGFloat(0.5)]
    
    func lerp(a : CGFloat, b : CGFloat, fraction : CGFloat) -> CGFloat
    {
        return (b-a) * fraction + a
    }
    
    func colorTransitionAction(fromColor : UIColor, toColor : UIColor, duration : Double = 1.0) -> SKAction
    {
        fromColor.getRed(&frgba[0], green: &frgba[1], blue: &frgba[2], alpha: &frgba[3])
        toColor.getRed(&trgba[0], green: &trgba[1], blue: &trgba[2], alpha: &trgba[3])
        
        return SKAction.customAction(withDuration: duration, actionBlock: { (node : SKNode!, elapsedTime : CGFloat) -> Void in
            let fraction = CGFloat(elapsedTime / CGFloat(duration))
            let transColor = UIColor(red: self.lerp(a: self.frgba[0], b: self.trgba[0], fraction: fraction),
                                     green: self.lerp(a: self.frgba[1], b: self.trgba[1], fraction: fraction),
                                     blue: self.lerp(a: self.frgba[2], b: self.trgba[2], fraction: fraction),
                                     alpha: self.lerp(a: self.frgba[3], b: self.trgba[3], fraction: fraction))
            (node as! SKShapeNode).strokeColor = transColor
            }
        )
    }
    
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameState.currentState is Playing {
            
            // Collision detection and health calculation
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            } else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            
            
            // check what player hit
            if firstBody.categoryBitMask == BabyCategory && secondBody.categoryBitMask == PlayerCategory {
                
                //decrease health by a lot if player hits baby
                healthBar.healthValue -= 32
                
          
            } else if ((firstBody.categoryBitMask == PlayerCategory && secondBody.categoryBitMask == MapCategory) || (firstBody.categoryBitMask == PlayerCategory && secondBody.categoryBitMask == CircleCategory) ) {
                
                healthBar.healthValue -= 2
               
            } else if ( (firstBody.categoryBitMask == PlayerCategory && secondBody.categoryBitMask == CoinCategory) || (firstBody.categoryBitMask == CoinCategory && secondBody.categoryBitMask == PlayerCategory) ) {
            
                
                // BOOL states so that the collision detection doesnt get multiple contacts
                coinWasEaten = true
                
                if( coinWasEaten == true && coinWasEatenPreviousState == false) {
                    eatenTime = CACurrentMediaTime()
                    score += 1
                    coinWasEatenPreviousState = coinWasEaten
                }
                
                
                // Setting anc checking a debounce time to be able to eat another coin
                let currentTime = CACurrentMediaTime()

                let coinRefreshTime = 0.15
                
                print(currentTime - eatenTime)
                
                if ( (currentTime - eatenTime) > coinRefreshTime ) {
                    coinWasEatenPreviousState = false
                }
                
                var coinHasBeenSet = false
                
                
                // when you eat a coin send it to a random location on the grass
                while(coinHasBeenSet == false) {
                    let randomX = self.randomBetweenNumbers(firstNum: -self.grassTileMapNode.mapSize.width/2, secondNum: self.grassTileMapNode.mapSize.width/2)
                    let randomY = self.randomBetweenNumbers(firstNum: -self.grassTileMapNode.mapSize.height/2, secondNum: self.grassTileMapNode.mapSize.height/2)
                    
                    let possiblePoint = CGPoint(x: randomX, y: randomY)
                    
                    let possibleCol = grassTileMapNode.tileColumnIndex(fromPosition: possiblePoint)
                    let possibleRow = grassTileMapNode.tileRowIndex(fromPosition: possiblePoint)
                    
                    print( grassTileMapNode.tileDefinition(atColumn: possibleCol, row: possibleRow)?.userData?.value(forKey: "isGrass") )
                    
                    if let _ = grassTileMapNode.tileDefinition(atColumn: possibleCol, row: possibleRow)?.userData?.value(forKey: "isGrass") {
                        
                        let moveto = SKAction.move(to: possiblePoint, duration: 0.000000001)
                    
                        coinSprite.run(moveto)
                    
                        coinHasBeenSet = true
                    }
                }
                
            }

            
            if(healthBar.healthValue < 0){
                // GAME OVER
                stopGeneratingBabies()
                isFingerOnPlayer = false
                
                
                let player = childNode(withName: PlayerCategoryName) as! SKSpriteNode
                
                player.physicsBody?.isDynamic = false
                
                let scope = SKSpriteNode(imageNamed: "sniperscope")
                scope.zPosition = 6
                scope.position = CGPoint(x: randomBetweenNumbers(firstNum: -736, secondNum: 736), y: randomBetweenNumbers(firstNum: -414, secondNum: 414))
                self.addChild(scope)
                
                
                let scale = SKAction.scale(to: 1, duration: 0.5)
                let moveto = SKAction.move(to: player.position, duration: 1.1)
                
                
                let action = SKAction.sequence([scale, moveto])
                scope.run(action)
                
                
                
                let date = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM dd, yyyy"
                let result = formatter.string(from: date)
                let message = "R.I.P Harambe, May 27, 1999 - " + result
                
                let label = SKLabelNode(fontNamed: "Helvetica-Bold")
                label.text = message
                label.fontSize = 20
                label.fontColor = SKColor.black
                label.position = CGPoint(x: 0, y: 0)
                label.zPosition = 5
                //self.addChild(label)
                
                self.camera?.addChild(label)
                
                let replayMessage = "Tap to Replay"
                let replayButton = SKLabelNode(fontNamed: "Helvetica-Bold")
                replayButton.text = replayMessage
                replayButton.fontColor = SKColor.black
                replayButton.position = CGPoint(x: 0, y: 50)
                replayButton.zPosition = 5
                replayButton.name = "replay"
                //self.addChild(replayButton)
                
                camera?.addChild(replayButton)
                
                gameState.enter(GameOver.self)
                
            }else{
                
                // update health bar color and size
                if(healthBar.healthValue < 31){
                    healthBar.color = UIColor.red
                }
                else if(healthBar.healthValue < 65){
                    healthBar.color = UIColor.yellow
                }
                else{
                    healthBar.color = UIColor.green
                }
                
                
                healthBar.size = CGSize(width: healthBar.healthValue, height: 30)
                healthBar.position = CGPoint(x: -355, y: 180)
                healthBar.anchorPoint = CGPoint(x: 0.0, y: 0.5)
                
            }
            
        }
        
    }
    
    // function to initialize location and movement when screen is touched
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enter(Playing.self)
            isFingerOnPlayer = true
            
            
        case is Playing:
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            
            // move the base of the joystick to where touches began
            self.outerJoystick.position = touchLocation
            self.innerJoystick.position = touchLocation
            self.outerJoystick.isHidden = true
            self.innerJoystick.isHidden = true
            
            
            
            // MAYBE REOVE THISSSSSSSSSSSSSSSSSSJSJSJJSJSJSJSJSJJSJSJJSJSJSJSJS
            if let body = physicsWorld.body(at: touchLocation) {
                if body.node!.name == PlayerCategoryName {
                    isFingerOnPlayer = true
                }
            }
            
            
        case is GameOver:
            let newScene = GameScene(fileNamed: "GameScene")
            newScene!.scaleMode = .aspectFit
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(newScene!, transition: reveal)
            
            
        default:
            break
        }
        generateBabies()
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isFingerOnPlayer { //and htis
            
            // update position of player depending on touch location
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            let previousLocation = touch!.previousLocation(in: self)
            
            

            let v = CGVector(dx: touchLocation.x - outerJoystick.position.x, dy: touchLocation.y - outerJoystick.position.y)
            let angle = atan2(v.dy, v.dx)
            
            let length = innerJoystick.frame.size.height / 2
            
            let xDist = sin(angle - 1.57079633) * length
            let yDist = cos(angle - 1.57079633) * length
            
            
            
            // so that joystick follows finger
            if(outerJoystick.frame.contains(touchLocation) ){
                
                innerJoystick.position = touchLocation
            } else {
                
                innerJoystick.position = CGPoint(x: outerJoystick.position.x - xDist, y: outerJoystick.position.y + yDist)
            }
      
            
            // get SKSpriteNode for player
            let player = childNode(withName: PlayerCategoryName) as! SKSpriteNode
            
            // MAYBE USE FORCE INSTEAD OR MOVE THIS TO TOUCEHS ENDED
            let impulse = SKAction.applyImpulse(v, duration: 0.1)
            player.run(impulse, withKey: "moving")
            
            
            // set player's new position, move harambe
            //let playerX = player.position.x + (touchLocation.x - previousLocation.x)
            //let playerY = player.position.y + (touchLocation.y - previousLocation.y)
            
            // if player is moving left
            if previousLocation.x > touchLocation.x {
                let flip = SKAction.scaleX(to: -1, duration: 0.0)
                player.setScale(1.0)
                
                let action = SKAction.sequence([flip])
                player.run(action)
            }
            
            if previousLocation.x < touchLocation.x {
                let flip = SKAction.scaleX(to: 1, duration: 0)
                player.setScale(1.0)
                
                let action = SKAction.sequence([flip])
                player.run(action)
            }
            
            
            // OR USE MOVE BY INSTEAD
            // actually move player
            //player.position = CGPoint(x: playerX, y: playerY)
        }
    }
    
    // only used to set bool back to false, gets called when finger is let off screen
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // isFingerOnPlayer = false
        outerJoystick.isHidden = true
        innerJoystick.isHidden = true
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if( self.timeHasBeenInitialized == false) {
            self.initialTime = Int(currentTime)
            timeHasBeenInitialized = true
        }
        
        let player = childNode(withName: PlayerCategoryName) as! SKSpriteNode
        let ChaseBaby = childNode(withName: ChaseBabyCategoryName) as! SKSpriteNode
        
        // TODO: Duration should be = distance/100 or somehow distance based
        
        //let chaseActions = SKAction.move(to: player.position, duration: 2)
        //ChaseBaby.run(chaseActions)
        
        
        if( babyStartMoving == true ) {
            let dx = player.position.x - ChaseBaby.position.x
            let dy = player.position.y - ChaseBaby.position.y
            let angle = atan2(dy, dx)
            
            ChaseBaby.zRotation = -angle
            
            let babySpeed = CGFloat(2.15)
            
            let vx = cos(angle) * babySpeed
            let vy = sin(angle) * babySpeed
            
            ChaseBaby.position.x += vx
            ChaseBaby.position.y += vy
        }
        
        
        updateCamera()

        gameState.update(deltaTime: currentTime)
    }
    
    func updateCamera() {
        let player = childNode(withName: PlayerCategoryName) as? SKSpriteNode
        if let camera = camera {
            camera.position = CGPoint(x: player!.position.x, y: player!.position.y)
        }
    }
    
}

