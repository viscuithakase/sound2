//
//  TopMenu.swift
//  sound2
//
//  Created by yasunori harada on 2024/09/27.
//

import Foundation

class TopMenu : TouchCommand {
    override func began(_ id:Int,_ pos:CGPoint) {
        
        var l = Top.positionLabel(pos);
        switch(l) {
        case "0":
            Top.global?.changeCommand {() in FnTone(Top.global!.engine!, {(pos) in pos.x + 500})}
        case "1":
            Top.global?.changeCommand {() in FnTone(Top.global!.engine!, {(pos) in
                (pos.y>0) ?
               pow(2, Double(pos.x + 500)/400) * 200:
               pow(2, Double(pos.x + 500)/400) * 100
            })}
        case "2":
            Top.global?.changeCommand {() in FnTone(Top.global!.engine!, {(pos) in
                var d = sqrt(pos.x*pos.x + pos.y*pos.y)
                return d * 3
            })}
        case "3":
            Top.global?.changeCommand {() in TouchRec()}
        case "4":
            Top.global?.changeCommand {() in TouchPlay()}
        default:
            print("ok")
        }
    }
    override func moved(_ id:Int,_ pos:CGPoint) {}
    override func ended(_ id:Int) {}
    override func running()->Bool {return true}
}
