//
//  GameScene.swift
//  sound2
//
//  Created by yasunori harada on 2024/09/17.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    override func didMove(to view: SKView) {
        
//        setupRecorder()

        let _ = Top()
    }
    
    var touchMap:Dictionary<Int, TouchCommand> = [:]

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if !isRecording {
//            startRecording()
//        }
//        engine!.start()
        
        for t in touches {
//            let c:TouchCommand = FnTone(engine!, { (pos) in pos.x+500})
/*
            let c:TouchCommand = FnTone(engine!, { (pos) in
                 (pos.y>0) ?
                pow(2, Double(pos.x + 500)/400) * 200:
                pow(2, Double(pos.x + 500)/400) * 100

            })
*/
            
            let c:TouchCommand? = Top.global?.genCommand()
            
            //LogTone(engine!)
            if (c != nil) {
                touchMap[t.hash] = c
                c?.began(t.hash, t.location(in: self))
            }
        }
        
        checkSpecial(event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchMap[t.hash]?.moved(t.hash, t.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchMap[t.hash]?.ended(t.hash)
        }
        if (touches.count == event?.allTouches?.count) {
            let c:TouchCommand? = Top.global?.genCommand()
            if (c is TouchTone) {
                c?.allOff()
                touchMap = [:]
            }
        }
    }
    
    func checkSpecial(_ event:UIEvent?) {
        if (event?.allTouches?.count == 2) {
            var x = 1.0
            var y = 1.0
            for t in event!.allTouches! {
                var p = t.location(in: self)
                x = x * p.x
                y = y * p.y
            }
            if (x < -100000 && y > 60000) {
                Top.global?.topMenu()
            }
        }
    }
}
