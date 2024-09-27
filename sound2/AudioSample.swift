//
//  AudioSample.swift
//  sound2
//
//  Created by yasunori harada on 2024/09/20.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    private let audioEngine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    
    private let sampleRate: Double = 44100
    private var phase: Double = 0
    private var frequency: Double = 440 // 初期値の周波数 (440Hz = A音)
    
    private var isTouching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // AVAudioEngineのセットアップ
        setupAudioEngine()
        
        // タッチの追跡を有効にする
        view.isMultipleTouchEnabled = false
    }

    private var freq : Double = 440

    private func nextSin() -> Float {
        let value = Float(sin(2.0 * .pi * self.freq * self.phase / self.sampleRate))
        self.phase += 1
        if self.phase >= self.sampleRate {
            self.phase -= self.sampleRate
        }
        
        if (self.phase > (self.freq * 100 / self.sampleRate)) {
            self.phase = 0
            freq += 10
//            freq = self.frequency
        }
                
        return value
    }
    // オーディオエンジンのセットアップ
    private func setupAudioEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        // サイン波を生成するノードをセットアップ
        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let bufferPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let buffer = bufferPointer[0].mData!.assumingMemoryBound(to: Float.self)
            
            if self.isTouching {
                for frame in 0..<Int(frameCount) {
                    let value = self.nextSin()
                    buffer[frame] = value
                }
            } else {
                // タッチしていない場合は音を出さない
                for frame in 0..<Int(frameCount) {
                    buffer[frame] = 0.0
                }
            }
            return noErr
        }
        
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: audioEngine.mainMixerNode, format: format)
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine error: \(error)")
        }
    }
    
    // 画面をタッチした際に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        isTouching = true
        updateFrequency(for: touch)
    }
    
    // タッチが動いた際に呼ばれる
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateFrequency(for: touch)
    }
    
    // タッチが終了した際に呼ばれる
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        isTouching = false
    }
    
    // タッチをキャンセルした場合に呼ばれる
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        isTouching = false
    }
    
    // タッチ位置に基づいて周波数を更新
    private func updateFrequency(for touch: UITouch) {
        let touchLocation = touch.location(in: self.view)
        let screenHeight = view.bounds.height
        
        // 画面の高さに基づいて周波数を計算（最低 220Hz から最大 880Hz の範囲）
        let minFrequency: Double = 220
        let maxFrequency: Double = 880
        let positionRatio = Double(screenHeight - touchLocation.y) / Double(screenHeight)
        frequency = minFrequency + (maxFrequency - minFrequency) * positionRatio
    }
}
