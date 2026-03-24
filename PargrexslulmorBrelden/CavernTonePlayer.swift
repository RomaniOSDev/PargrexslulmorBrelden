//
//  CavernTonePlayer.swift
//  PargrexslulmorBrelden
//

import AVFoundation
import Foundation

final class CavernTonePlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var didConfigure = false

    func configureIfNeeded() {
        guard !didConfigure else { return }
        didConfigure = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) ?? engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    func play(high: Bool) {
        configureIfNeeded()
        let sampleRate = 44_100.0
        let frequency = high ? 780.0 : 410.0
        let duration = 0.2
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else {
            return
        }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData else { return }
        let channel = channelData[0]
        for i in 0 ..< Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = 1.0 - (Double(i) / Double(frameCount))
            channel[i] = Float(0.22 * envelope * sin(2.0 * .pi * frequency * t))
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }
}
