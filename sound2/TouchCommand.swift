//
//  TouchCommand.swift
//  sound2
//
//  Created by yasunori harada on 2024/09/27.
//

import Foundation
import GameplayKit
import AVFoundation


class TouchCommand {
    func began(_ id:Int,_ pos:CGPoint) {}
    func moved(_ id:Int,_ pos:CGPoint) {}
    func ended(_ id:Int,_ pos:CGPoint) {}
}

class TouchTone : TouchCommand {
    let tone:FreqTone
    init(_ en:ToneEngine) {
        self.tone = FreqTone(en)
    }

    override func began(_ id:Int,_ pos:CGPoint) {
        tone.setFreq(pos.x + 500)
    }
    override func moved(_ id:Int,_ pos:CGPoint) {
        tone.setFreq(pos.x + 500)
    }
    override func ended(_ id:Int,_ pos:CGPoint) {
        tone.stop()
    }
}


class Tone {
    public let engine:ToneEngine
    init(_ en:ToneEngine) {
        engine = en
    }
    public let sampleRate: Double = 44100
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
    public var level: Double = 1

    override func nextSignal() -> Float {
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
            
            var ww:Array<Tone> = []
            for tone in self.tones {
                if (!tone.stopped) {
                    ww.append(tone)
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

            var notstop:Array<Tone> = []

            for tone in self.tones {
                if (!tone.stopped) {
                    notstop.append(tone)
                }
            }
            self.tones = notstop
            
            return noErr
        }
        
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
    }
    
    func playTone(tone:Tone) {
        tones.append(tone)
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
        engine.stop()
        print("Audio engine stopped")
    }
}

