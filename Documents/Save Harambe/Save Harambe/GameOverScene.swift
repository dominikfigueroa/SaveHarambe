//
//  GameOverScene.swift
//  Save Harambe
//
//  Created by Dominik Figueroa on 10/24/16.
//  Copyright © 2016 Dominik Figueroa. All rights reserved.
//

import UIKit
import SpriteKit

class GameOverScene: SKScene {
        
        override init(size: CGSize) {
            super.init(size: size)
            
            //1
            self.backgroundColor = SKColor.white
            
            //2
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM dd, yyyy"
            let result = formatter.string(from: date)
            //let calender = NSCalendar.current
            //calender.dateComponents( .Day, from: date)
            let message = "R.I.P\r\nHarambe, May 27, 1999 - " + result
            
            print(message)
            
            //3
            let label = SKLabelNode(fontNamed: "Chalkduster")
            label.text = message
            label.fontSize = 10
            label.fontColor = SKColor.black
            label.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
            self.addChild(label)
            
            //4
            let replayMessage = "Replay Game"
            let replayButton = SKLabelNode(fontNamed: "Chalkduster")
            replayButton.text = replayMessage
            replayButton.fontColor = SKColor.black
            replayButton.position = CGPoint(x: self.size.width/2, y: 50)
            replayButton.name = "replay"
            self.addChild(replayButton)
        }
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
        for touch: AnyObject in touches {
            // let touchLocation = touch.location(in: self)
            // let node = self.nodes(at: touchLocation)
            if (self.childNode(withName: "replay") != nil) {
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let scene = GameOverScene(size: self.size)
                scene.scaleMode = .aspectFill
                self.view?.presentScene(scene, transition: reveal)
            }
        }
    }
    
    

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    
    
}
