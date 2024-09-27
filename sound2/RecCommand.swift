//
//  RecCommand.swift
//  sound2
//
//  Created by yasunori harada on 2024/09/28.
//

import Foundation
import GameplayKit
import AVFoundation


class RecEngine {
    var audioRecorder: AVAudioRecorder?
    var isRecording = false
    var audioPlayer: AVAudioPlayer?

    static var global:RecEngine?
    
    init() {
        RecEngine.global = self

        let audioSession = AVAudioSession.sharedInstance()
        
        print("init rec \(audioSession)")
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func record(_ name:String) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentDirectory.appendingPathComponent("\(name).m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
        } catch {
            print("Failed to set up audio recorder: \(error)")
        }
        print("Recording \(name)")
        audioRecorder?.record()
    }
    func recStop() {
        audioRecorder?.stop()
    }
    
    func play(_ name:String) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentDirectory.appendingPathComponent("\(name).m4a")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer?.play()
            print("Playing \(name)")
        } catch {
            print("Failed to set up audio player: \(error)")
        }
    }
    func playing()->Bool {
        return audioPlayer?.isPlaying == true
    }
    deinit {
        print("deinit rec engine")
    }
}


class TouchRec: TouchCommand {
    var lavel:String?
    override func began(_ id:Int,_ pos:CGPoint) {
        lavel = Top.positionLabel(pos)
        
        RecEngine.global?.record(lavel!)
    }
    
    override func ended(_ id:Int) {
        RecEngine.global?.recStop()
        if (lavel != nil) {
            RecEngine.global?.play(lavel!)
        }
    }
}

class TouchPlay: TouchCommand {
    
    override func began(_ id:Int,_ pos:CGPoint) {
        let l = Top.positionLabel(pos)
        RecEngine.global?.play(l)
    }
    
    override func running()->Bool {return RecEngine.global?.playing()==true}
    
    deinit {
        print("deinit touch play")
    }
}
/*

    func startRecording() {
        guard let recorder = audioRecorder else { return }
        recorder.record()
        isRecording = true
        print("Recording started")
    }

    func stopRecording() {
        guard let recorder = audioRecorder else { return }
        isRecording = false
        print("Recording stopped")
    }
    
    func playRecording() {
        do {
            TouchRec.audioPlayer = try AVAudioPlayer(contentsOf: audioFilename!)
            guard let player = TouchRec.audioPlayer else { return }
            player.play()
            print("Playing")
        } catch {
                
        }
    }
    
    override func allOff() {
        print("recording all off")
    }

}
*/
