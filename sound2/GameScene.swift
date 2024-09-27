//
//  GameScene.swift
//  sound2
//
//  Created by yasunori harada on 2024/09/17.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    var engine: ToneEngine?;
    
    override func didMove(to view: SKView) {
        
//        setupRecorder()

        engine = ToneEngine()
        engine!.start()
    }
    
    var touchMap:Dictionary<Int, TouchCommand> = [:]
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if !isRecording {
//            startRecording()
//        }

        for t in touches {
            var c:TouchCommand = TouchTone(engine!)
            touchMap[t.hash] = c
            c.began(t.hash, t.location(in: self))
        }

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for t in touches {
            touchMap[t.hash]?.moved(t.hash, t.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchMap[t.hash]?.ended(t.hash, t.location(in: self))
        }
    }
}
