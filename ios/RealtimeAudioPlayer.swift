import Foundation
import AudioToolbox

struct CircularBuffer {
    var buffer: [UInt8]
    var head: Int = 0
    var tail: Int = 0
    var capacity: Int
    var count: Int {
        return (head - tail + capacity) % capacity
    }

    init(capacity: Int) {
        self.capacity = capacity
        buffer = [UInt8](repeating: 0, count: capacity)
    }

    mutating func write(data: Data) -> Bool {
        guard data.count <= (capacity - count) else {
            return false // Not enough space
        }

        for byte in data {
            buffer[head] = byte
            head = (head + 1) % capacity
        }
        return true
    }

    mutating func read(size: Int) -> Data? {
        guard size <= count else {
            return nil // Not enough data
        }

        var data = Data()
        for _ in 0..<size {
            data.append(buffer[tail])
            tail = (tail + 1) % capacity
        }
        return data
    }
}

@objc(AudioPlayer)
class AudioPlayer: NSObject {
    private var audioQueue: AudioQueueRef?
    private var buffer: CircularBuffer
    private var bufferByteSize: UInt32
    private var initialized: Bool
  
    static func moduleName() -> String! {
        return "AudioPlayer"
    }
    
    override init() {
        self.initialized = false
        self.bufferByteSize = 8192 // Default buffer size
        self.buffer = CircularBuffer(capacity: Int(self.bufferByteSize * 1000))
        super.init()
    }
  
    @objc(initialize:sampleRate:channels:)
    func initialize(bufferByteSize: UInt32, sampleRate: Double, channels: UInt32) {
        self.initialized = true
        self.bufferByteSize = bufferByteSize
        self.buffer = CircularBuffer(capacity: Int(bufferByteSize * 1000))
        setupAudioQueue(sampleRate: sampleRate, channels: channels)
    }

    private func setupAudioQueue(sampleRate: Double, channels: UInt32) {
        var streamFormat = AudioStreamBasicDescription()
        streamFormat.mSampleRate = sampleRate
        streamFormat.mFormatID = kAudioFormatLinearPCM
        streamFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        streamFormat.mFramesPerPacket = 1
        streamFormat.mChannelsPerFrame = channels
        streamFormat.mBitsPerChannel = 16
        streamFormat.mBytesPerFrame = (streamFormat.mBitsPerChannel / 8) * streamFormat.mChannelsPerFrame
        streamFormat.mBytesPerPacket = streamFormat.mBytesPerFrame

        AudioQueueNewOutput(&streamFormat, audioQueueCallback, Unmanaged.passUnretained(self).toOpaque(), nil, nil, 0, &audioQueue)

        // Enqueue initial silent buffers to start playback
        var buffers = [AudioQueueBufferRef?](repeating: nil, count: 2)
        for index in 0..<2 {
            AudioQueueAllocateBuffer(audioQueue!, bufferByteSize, &buffers[index])
            if let buffer = buffers[index] {
                memset(buffer.pointee.mAudioData, 0, Int(bufferByteSize))
                buffer.pointee.mAudioDataByteSize = bufferByteSize
                AudioQueueEnqueueBuffer(audioQueue!, buffer, 0, nil)
            }
        }

        AudioQueueStart(audioQueue!, nil)
    }

    private let audioQueueCallback: AudioQueueOutputCallback = { (userData, queue, bufferRef) in
        guard let userData = userData else { return }
        let player: AudioPlayer = Unmanaged<AudioPlayer>.fromOpaque(userData).takeUnretainedValue()
        if player.audioQueue == nil {
            return // Audio queue has been stopped, do nothing
        }
        if let data = player.buffer.read(size: Int(bufferRef.pointee.mAudioDataByteSize)) {
            memcpy(bufferRef.pointee.mAudioData, (data as NSData).bytes, data.count)
            bufferRef.pointee.mAudioDataByteSize = UInt32(data.count)
        } else {
            memset(bufferRef.pointee.mAudioData, 0, Int(bufferRef.pointee.mAudioDataByteSize)) // Play silence if no data
        }
        AudioQueueEnqueueBuffer(queue, bufferRef, 0, nil)
    }

    func enqueueAudioData(data: Data) {
        guard audioQueue != nil else {
            print("Audio queue is not active")
            return
        }
        if !buffer.write(data: data) {
            print("Buffer overflow, dropping data")
        }
    }
  
    @objc(playAudioData:withResolver:withRejecter:)
    func playAudioData(base64String: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        if !self.initialized {
            reject("error", "PlayAudio class not initialised", nil)
            return
        }
        guard let data = Data(base64Encoded: base64String) else {
            reject("error", "Invalid base64 string", nil)
            return
        }
        enqueueAudioData(data: data)
        resolve(true)
    }
    
    @objc(deinitialize)
    func deinitialize() {
        if let queue = audioQueue {
            AudioQueueStop(queue, true)
            AudioQueueDispose(queue, true)
            audioQueue = nil
        }
        initialized = false
    }
    
    deinit {
        deinitialize()
    }
}
