import AVFoundation


class Wave {
    private let sampleRate: Double = 44100
    private var phase: Double = 0
    private var frequency: Double = 440
    private var freq : Double = 440
    private var stopping : Bool = false
    public var stopped : Bool = false
    public var level: Double = 1

    public func nextSin() -> Float {
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

    public func setFreq(f:Double) {
        frequency = f
    }
    public func stop() {
        stopping = true
    }
}

class AudioEngineX {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!

    private let sampleRate: Double = 44100

    private var waves: Dictionary<Int, Wave> = [:]
    private var stopped: Set<Int> = []
        
    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let bufferPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            var ww:Array<Wave> = []
            for (_, w) in self.waves {
                if (!w.stopped) {
                    ww.append(w)
                }
            }
            
            for frame in 0..<Int(frameCount) {
                var value:Float = 0
                for w in ww {
                    value += w.nextSin()
                }
                
                bufferPointer[0].mData?.assumingMemoryBound(to: Float.self)[frame] = value
                bufferPointer[1].mData?.assumingMemoryBound(to: Float.self)[frame] = value
            }
    
            for (t, w) in self.waves {
                if (w.stopped) {
                    self.waves[t] = nil
                }
            }
            
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
    }
    
    func setFreq(id:Int, f:Double) {
        if (waves[id]==nil) {
            waves[id] = Wave()
        }
        waves[id]?.setFreq(f:f)
    }
    func stopFreq(id:Int) {
        waves[id]?.stop()
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
    
    var audioRecorder: AVAudioRecorder?
    var isRecording = false
    
    var audioPlayer: AVAudioPlayer?
    
    var audioFilename: URL?

    
    
    func startRecording() {
        guard let recorder = audioRecorder else { return }
        recorder.record()
        isRecording = true
        print("Recording started")
    }

    func stopRecording() {
        guard let recorder = audioRecorder else { return }
        recorder.stop()
        isRecording = false
        print("Recording stopped")
    }
    
    func playRecording() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename!)
            guard let player = audioPlayer else { return }
            player.play()
            print("Playing")
        } catch {
                
        }
    }

    func setupRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }

        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFilename = documentDirectory.appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename!, settings: settings)
            audioRecorder?.prepareToRecord()
        } catch {
            print("Failed to set up audio recorder: \(error)")
        }
        
    }

    
}
