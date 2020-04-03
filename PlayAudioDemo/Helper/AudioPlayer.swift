//
//  AudioPlayer.swift
//  PlayAudioDemo
//
//  Created by Apple on 3/29/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import AVFoundation
import UIKit

protocol AudioPlayerDelegate: class {
    func audioPlayer(_ audioPlayer: AudioPlayer, willBeginGetAudioFrom url: URL?)
    func audioPlayer(_ audioPlayer: AudioPlayer, didGetAudioSuccessFrom url: URL?)
    func audioPlayer(_ audioPlayer: AudioPlayer, didGetAudioFailureFrom url: URL?)
    func audioPlayerDidEndInterrupt(_ audioPlayer: AudioPlayer)
    func audioPlayerWillBeginInterrupt(_ audioPlayer: AudioPlayer)
}

class AudioPlayer: NSObject {
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidEndInterrupt(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemWillBeginInterrupt(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public properties

    weak var delegate: AudioPlayerDelegate?
    var isPlayingDidChange: ((Bool) -> Void)?
    var canForwardDidChange: ((Bool) -> Void)?
    var canRewireDidChange: ((Bool) -> Void)?
    var currentTimeDidChange: ((TimeInterval) -> Void)?

    private(set) var duration: TimeInterval = 0

    private(set) var isPlaying: Bool = false {
        didSet {
            isPlayingDidChange?(isPlaying)
        }
    }

    private(set) var canForward: Bool = false {
        didSet {
            canForwardDidChange?(canForward)
        }
    }

    private(set) var canRewire: Bool = false {
        didSet {
            canRewireDidChange?(canRewire)
        }
    }

    // MARK: - Private properties

    private var currentAudioURL: URL?
    private var categories: [URL] = []
    private var player: AVPlayer!
    private var playerItem: CachingPlayerItem?
    private var allowRepeatAudio = false
    private var autoSwitchAudio = true
    private var timer: Timer?

    private var currentIndex = -1 {
        didSet {
            canForward = currentIndex < categories.count - 1 && currentIndex >= 0
            canRewire = currentIndex > 0
        }
    }

    // MARK: - Public method

    func loadAudio(at index: Int) {
        guard categories.indices.contains(index) else { return }
        let url = categories[index]
        loadAudio(withURL: url)
        currentIndex = index
    }

    func loadAudio(withURL url: String?) {
        guard let url = url, let audioURL = URL(string: url) else { return }
        loadAudio(withURL: audioURL)
    }

    func loadAudio(withURL url: URL?) {
        guard let audioURL = url else { return }
        resetPlayer()
        currentAudioURL = audioURL
        if let data = kAudioCache[audioURL.path] {
            playerItem = CachingPlayerItem(data: data, mimeType: "audio/mpeg", fileExtension: audioURL.pathExtension)
        } else {
            playerItem = CachingPlayerItem(url: audioURL)
        }
        delegate?.audioPlayer(self, willBeginGetAudioFrom: audioURL)
        playerItem?.delegate = self
        player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false
    }

    func loadAudios(withCategoriesURL urls: [String]?, startAt index: Int) {
        guard let categories = urls else { return }
        self.categories = categories.compactMap { URL(string: $0) }
        loadAudio(at: index)
    }

    func loadAudios(withCategoriesURL urls: [URL]?, startAt index: Int) {
        guard let categories = urls else { return }
        self.categories = categories
        loadAudio(at: index)
    }

    func startObserverCurrentTime() {
        timer = Timer(timeInterval: 0.5, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            let currentTime = CMTimeGetSeconds(self.player.currentTime())
            self.currentTimeDidChange?(currentTime)
        })
        RunLoop.main.add(timer!, forMode: .default)
    }

    func stopObserverCurrentTime() {
        timer?.invalidate()
        timer = nil
    }

    func readyToPlay() {
        startObserverCurrentTime()
        play()
    }

    func play() {
        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func toggle() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func set(repeatAudio: Bool) {
        allowRepeatAudio = repeatAudio
    }

    func set(autoSwitchAudio: Bool) {
        self.autoSwitchAudio = autoSwitchAudio
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: time)
    }

    func set(volumn: Float) {
        player.volume = volumn
    }

    func forward() {
        guard canForward else { return }
        loadAudio(at: currentIndex + 1)
    }

    func rewire() {
        guard canRewire else { return }
        loadAudio(at: currentIndex - 1)
    }

    // MARK: - Private method

    private func resetPlayer() {
        player?.pause()
    }

    @objc private func playerItemDidReachEnd() {
        if allowRepeatAudio {
            player.seek(to: .zero)
        } else if autoSwitchAudio && canForward {
            forward()
        } else {
            stopObserverCurrentTime()
            isPlaying = false
        }
    }

    @objc private func playerItemWillBeginInterrupt(notification: Notification) {
        delegate?.audioPlayerWillBeginInterrupt(self)
    }

    @objc private func playerItemDidEndInterrupt(notification: Notification) {
        delegate?.audioPlayerDidEndInterrupt(self)
    }
}

extension AudioPlayer: CachingPlayerItemDelegate {
    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        if let audioDuration = playerItem.tracks.first?.assetTrack?.asset?.duration {
            duration = CMTimeGetSeconds(audioDuration)
        }
        delegate?.audioPlayer(self, didGetAudioSuccessFrom: currentAudioURL)
    }

    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        delegate?.audioPlayer(self, didGetAudioFailureFrom: currentAudioURL)
    }

    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        guard let fileName = currentAudioURL?.path else { return }
        kAudioCache[fileName] = data
    }
}
