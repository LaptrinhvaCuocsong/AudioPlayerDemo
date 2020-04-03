//
//  ViewController.swift
//  PlayAudioDemo
//
//  Created by Apple on 3/28/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import SVProgressHUD
import UIKit

class ViewController: UIViewController {
    @IBOutlet var playButton: UIButton!
    @IBOutlet var rewireButton: UIButton!
    @IBOutlet var fowardButton: UIButton!
    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var sliderView: SliderView!

    private var audios: [URL] = []
    private let audioPlayer = AudioPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        audioPlayer.delegate = self
        getAudios()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        audioPlayer.loadAudios(withCategoriesURL: audios, startAt: 0)
    }

    private func getAudios() {
        for i in 0 ... 6 {
            guard let path = Bundle.main.path(forResource: "\(i)", ofType: "mp3") else { return }
            let url = URL(fileURLWithPath: path)
            audios.append(url)
        }
    }

    private func setupUI() {
        audioPlayer.isPlayingDidChange = { [weak self] isPlaying in
            guard let self = self else { return }
            if isPlaying {
                self.playButton.setTitle("Pause", for: .normal)
            } else {
                self.playButton.setTitle("Play", for: .normal)
            }
        }
        audioPlayer.canRewireDidChange = { [weak self] canRewire in
            guard let self = self else { return }
            self.rewireButton.alpha = canRewire ? 1.0 : 0.5
            self.rewireButton.isEnabled = canRewire ? true : false
        }
        audioPlayer.canForwardDidChange = { [weak self] canForward in
            guard let self = self else { return }
            self.fowardButton.alpha = canForward ? 1.0 : 0.5
            self.fowardButton.isEnabled = canForward ? true : false
        }
        audioPlayer.currentTimeDidChange = { [weak self] currentTime in
            guard let self = self else { return }
            self.sliderView.updateSlider(value: CGFloat(currentTime))
            let time = currentTime.time
            self.currentTimeLabel.text = String(format: "%02d:%02d", time.minute, time.seconds)
        }
        sliderView.thumbImage = UIImage(named: "virus")
        sliderView.sliderBackground = .cyan
        sliderView.minimumValue = 0
        sliderView.beginValueChange = { [weak self] _ in
            guard let self = self else { return }
            self.audioPlayer.stopObserverCurrentTime()
        }
        sliderView.endValueChange = { [weak self] value in
            guard let self = self else { return }
            self.audioPlayer.seek(to: Double(value))
            self.audioPlayer.startObserverCurrentTime()
        }
    }

    @IBAction func play(_ sender: Any) {
        audioPlayer.toggle()
    }

    @IBAction func rewire(_ sender: Any) {
        audioPlayer.rewire()
    }

    @IBAction func foward(_ sender: Any) {
        audioPlayer.forward()
    }
}

extension ViewController: AudioPlayerDelegate {
    func audioPlayer(_ audioPlayer: AudioPlayer, willBeginGetAudioFrom url: URL?) {
        SVProgressHUD.show()
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, didGetAudioSuccessFrom url: URL?) {
        SVProgressHUD.dismiss()
        audioPlayer.readyToPlay()
        sliderView.maximumValue = CGFloat(audioPlayer.duration)
        let time = audioPlayer.duration.time
        durationLabel.text = String(format: "%02d:%02d", time.minute, time.seconds)
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, didGetAudioFailureFrom url: URL?) {
        print("Load fail 😭")
        SVProgressHUD.dismiss()
    }

    func audioPlayerDidEndInterrupt(_ audioPlayer: AudioPlayer) {
    }

    func audioPlayerWillBeginInterrupt(_ audioPlayer: AudioPlayer) {
    }
}
