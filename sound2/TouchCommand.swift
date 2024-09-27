//
//  TouchCommand.swift
//  sound2
//
//  Created by yasunori harada on 2024/09/27.
//

import Foundation
import GameplayKit
import AVFoundation


class Top {
    static var global : Top?
    init() {
        Top.global = self
        self.engine = ToneEngine()
        topMenu()
        
        let _ = RecEngine()
    }
    
    public var engine: ToneEngine?
    public var commandGen : (() -> TouchCommand)?
    func changeCommand(_ fn:@escaping () -> TouchCommand) {
        commandGen = fn
        engine?.allOff()
        engine?.stop()
    }
    func genCommand() -> TouchCommand {
        return commandGen!()
    }
    func topMenu() {
        changeCommand {() in TopMenu()}
    }
    func play(_ f:Double) {
        let t:FreqTone = FreqTone(engine!)
        t.setFreq(f)
        engine!.playTone(t)
    }
    
    static func positionLabel(_ pos:CGPoint)->String {
        let a = abs((pos.x)+Double(pos.y)) < 100
        let b = abs((pos.x)-Double(pos.y)) < 100
        
        let c = pos.x > 0
        let d = pos.y > 0

        //   2       1
        //       0
        //   4       3
        
        if (a && b) {
            return "0"
        } else if (c && d) {
            return "1"
        } else if (!c && d) {
            return "2"
        } else if (c && !d) {
            return "3"
        } else if (!c && !d) {
            return "4"
        }
        return ""
    }
}


class TouchCommand {
    func began(_ id:Int,_ pos:CGPoint) {}
    func moved(_ id:Int,_ pos:CGPoint) {}
    func ended(_ id:Int) {}
    func running()->Bool {return false}
    func allOff() {}
}

class TouchTone: TouchCommand {
    let tone:FreqTone
    init(_ en:ToneEngine) {
        en.start()
        self.tone = FreqTone(en)
    }
    override func ended(_ id:Int) {
        tone.stop()
    }
    override func running()->Bool {
        return !tone.stopped && !tone.stopping
    }
    func posToF(_ pos:CGPoint)->Double { return 0 }

    override func began(_ id:Int,_ pos:CGPoint) {
        tone.setFreq(posToF(pos))
    }
    override func moved(_ id:Int,_ pos:CGPoint) {
        tone.setFreq(posToF(pos))
    }
    override func allOff() {
        Top.global?.engine?.allOff()
    }
}

class FnTone:TouchTone {
    let fn : (CGPoint)->Double

    init(_ en:ToneEngine, _ f:@escaping (CGPoint)->Double) {
        self.fn = f
        super.init(en)
    }
    override func posToF(_ pos:CGPoint)->Double {
        return fn(pos)
    }
}

class LinearTone : TouchTone {
    override func posToF(_ pos:CGPoint)->Double {
        print("pos \(pos.x) \(pos.y)")
        return Double(pos.x) + 500 }
}

class LogTone : TouchTone {
    override func posToF(_ pos:CGPoint)->Double {
        let x = pow(2, (pos.x + 500)/300) * 100
        return x
    }
}



class Tone {
    public let engine:ToneEngine
    init(_ en:ToneEngine) {
        engine = en
        engine.playTone(self)
    }
    public let sampleRate: Double = 44100
    public var starting: Bool = true
    public var stopped : Bool = false
    public var stopping : Bool = false
    public func nextSignal() -> Float {return 0}
    public func stop() {
        stopping = true
    }
}

class FreqTone:Tone {
    private var phase: Double = 0
    private var frequency: Double = 440
    private var freq : Double = 440
    public var level: Double = 0

    override func nextSignal() -> Float {
        if (starting) {
            level = level + 0.002
            if (level >= 1) {
                level = 1
                starting = false
            }
        }
        
        if (stopping) {
            level = level - 0.001
            if (level < 0) {
                stopped = true
                stopping = false
            }
        }
        if (stopped) {
            return 0
        }
        
        let value = Float(sin(2.0 * .pi * self.freq * self.phase / self.sampleRate)*level)
        self.phase += 1
        if (self.phase > (self.sampleRate / self.freq)) {
            self.phase -= self.sampleRate / self.freq
            freq = self.frequency
        }
        return value
    }
    public func setFreq(_ f:Double) {
//        print("setFreq \(f)")
        frequency = f
    }
}

class ToneEngine {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    
    private let sampleRate: Double = 44100
    
    private var tones: Array<Tone> = []
    private var stopped: Array<Tone> = []
    
    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let bufferPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
//            print("buf \(self.tones.count)")

            var ww:Array<Tone> = []
            var changed:Bool = false
            for tone in self.tones {
                if (!tone.stopped) {
                    ww.append(tone)
                } else {
                    changed = true
                }
            }

            for frame in 0..<Int(frameCount) {
                var value:Float = 0
                for w in ww {
                    value += w.nextSignal()
                }
                
                bufferPointer[0].mData?.assumingMemoryBound(to: Float.self)[frame] = value
                bufferPointer[1].mData?.assumingMemoryBound(to: Float.self)[frame] = value
            }

            if (changed) {
                var notstop:Array<Tone> = []
                for tone in self.tones {
                    if (!tone.stopped) {
                        notstop.append(tone)
                    }
                }
                self.tones = notstop
            }
            
            return noErr
        }
        
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
    }
    
    func playTone(_ tone:Tone) {
        tones.append(tone)
    }
    func allOff() {
        for tone in tones {
            tone.stop()
        }
    }
    
    func start() {
        do {
            if (!engine.isRunning) {
                try engine.start()
                print("Audio engine started")
            }
        } catch {
            print("Error starting the audio engine: \(error)")
        }
    }
    
    func stop() {
        if (engine.isRunning) {
            engine.stop()
            print("Audio engine stopped")
        }
    }
}

