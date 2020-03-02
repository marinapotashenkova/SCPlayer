//
//  ExtendedPlayerViewController.swift
//  Project
//
//  Created by Марина on 17.02.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import UIKit
import AlamofireImage
import AVFoundation
import MediaPlayer

class ExtendedPlayerViewController: UIViewController, PlayerObserver {
    
    func player(didStart track: Track) {
        setupOutlets()
        playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
    }
    
    func player(paused track: Track) {
        playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    func player(continued track: Track) {
        playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
    }
    
    func player(changedTo track: Track) {
        setupOutlets()
        PlayerService.shared.isPlaying ? playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal) : playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    func player(isLoading track: Track) {
        updateUIForLoading()
    }
    

    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var trackProgressView: UIProgressView!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var volumeView: UIView!
    
    var player: AVPlayer!
    
    private var updater: CADisplayLink!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updater = CADisplayLink(target: self, selector: #selector(trackProgress))
        updater.preferredFramesPerSecond = 1
        updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
        
        setupOutlets()
        addVolumeSlider()
        PlayerService.shared.isPlaying ? playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal) : playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        
        PlayerService.shared.addClient(self)
    }
    
    private func setupOutlets() {
        
        if let track = PlayerService.shared.currentTrack {

            if let artworkUrl = track.artworkUrl {
                artworkImageView.af_setImage(withURL: artworkUrl, placeholderImage: UIImage(systemName: "music.note"), filter: RoundedCornersFilter(radius: 3.0)) { [unowned self] (response) in
                    
                    SearchCollectionViewController.imageCache.add(self.artworkImageView.image!, for: URLRequest(url: artworkUrl), withIdentifier: String(track.id))
                }
            }
            
            titleLabel.text = track.title
            ownerLabel.isHidden = false
            ownerLabel.text = track.owner.name
            descriptionTextView.isHidden = track.extendedInformation?.description?.isEmpty == false ? false : true
            descriptionTextView.text = track.extendedInformation?.description
            
            forwardButton.isEnabled = true
            backwardButton.isEnabled = true
            
            updater.isPaused = false
        } else {
            
            artworkImageView.image = UIImage(systemName: "music.note")
            titleLabel.text = "Not Playing"
            ownerLabel.isHidden = true
            descriptionTextView.isHidden = true
            forwardButton.isEnabled = false
            backwardButton.isEnabled = false
        }
    }
    
    private func addVolumeSlider() {
        let volumeSlider = MPVolumeView(frame: volumeView.bounds)
        volumeView.addSubview(volumeSlider)
        
    }

    @objc func trackProgress() {
        trackProgressView.progress = PlayerService.shared.trackProgress
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        updater.invalidate()
        PlayerService.shared.removeClient(self)
    }
        
    @IBAction func playButtonTapped(_ sender: UIButton) {
        PlayerService.shared.playOrPause()
    }
    
    
    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        PlayerService.shared.nextTrack()
    }
    
    @IBAction func backwardButtonTapped(_ sender: UIButton) {
        PlayerService.shared.prevTrack()
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    private func updateUIForLoading() {
        updater.isPaused = true
        trackProgressView.progress = 0
        artworkImageView.image = UIImage(systemName: "music.note")
        titleLabel.text = "Loading..."
        ownerLabel.isHidden = true
        descriptionTextView.isHidden = true
        backwardButton.isEnabled = false
        forwardButton.isEnabled = false
    }
    
}

