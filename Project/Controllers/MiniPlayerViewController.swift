//
//  PlayerViewController.swift
//  Project
//
//  Created by Марина on 11.02.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import UIKit
import AVFoundation
import AlamofireImage

class MiniPlayerViewController: UIViewController, SearchCollectionViewControllerDelegate, PlayerObserver {
    
    func player(didStart track: Track) {
        updateUI(for: track)
        playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
    }
    
    func player(paused track: Track) {
        playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    func player(continued track: Track) {
        playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
    }
    
    func player(changedTo track: Track) {
        updateUI(for: track)
    }
    
    func player(isLoading track: Track) {
        updateUIForLoading()
    }
                
    let playButton: UIButton = UIButton(type: .custom)
    let forwardButton: UIButton = UIButton(type: .custom)
    let trackLabel: UILabel = UILabel()
    let trackImageView: UIImageView = UIImageView()
    let visualEffectView = UIVisualEffectView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVisualEffectView()
        setupButtons()
        setupTrack()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(presentExtendedPlayer))
        view.addGestureRecognizer(gesture)
        
        PlayerService.shared.addClient(self)
    }
    
    @objc func presentExtendedPlayer() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ExtendedPlayerViewController") as? ExtendedPlayerViewController else {
            assertionFailure("Error of downcasting UIViewController to ExtendedPlayerViewController")
            return
        }

        self.present(vc, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let parentViewController = self.parent as? SearchCollectionViewController else {
            assertionFailure("Error of getting parent of MiniPlayerViewController")
            return
        }
        parentViewController.delegate = self
    }
    
    func play(trackNumber: Int) {
        PlayerService.shared.choose(trackNumber: trackNumber)
        
    }
    
    func stop() {
        PlayerService.shared.stopPlaying()
    }
    
    @objc func playButtonTapped(_ sender: UIButton) {
        PlayerService.shared.playOrPause()
    }
    
    @objc func forwardButtonTapped(_ sender: UIButton) {
        PlayerService.shared.nextTrack()
    }
    
    // MARK: - Setting up View
    
    private func setupVisualEffectView() {
        visualEffectView.frame = view.frame
        visualEffectView.effect = UIBlurEffect(style: .prominent)
        
        view.addSubview(visualEffectView)
    }
    
    private func setupButtons() {
        
        playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)
        forwardButton.setBackgroundImage(UIImage(systemName: "forward.fill"), for: .normal)
        forwardButton.isEnabled = false
        forwardButton.addTarget(self, action: #selector(forwardButtonTapped(_:)), for: .touchUpInside)
        
        visualEffectView.contentView.addSubview(playButton)
        visualEffectView.contentView.addSubview(forwardButton)
        
        setupButtonsConstraints()
    }
    
    private func setupButtonsConstraints() {
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        forwardButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        forwardButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        forwardButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.trailingAnchor.constraint(equalTo: forwardButton.leadingAnchor, constant: -20).isActive = true
        playButton.centerYAnchor.constraint(equalTo: forwardButton.centerYAnchor).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    private func setupTrack() {
        
        trackLabel.text = "Not Playing"
        trackLabel.font = trackLabel.font.withSize(20)
        
        trackImageView.image = UIImage(systemName: "music.note")
        trackImageView.layer.borderColor = UIColor.lightGray.cgColor
        trackImageView.layer.cornerRadius = 3.0
        trackImageView.layer.borderWidth = 0.5
        trackImageView.layer.shadowRadius = 3
        
        visualEffectView.contentView.addSubview(trackLabel)
        visualEffectView.contentView.addSubview(trackImageView)
        setupTrackConstraints()
        
    }
    
    private func setupTrackConstraints() {
        
        trackImageView.translatesAutoresizingMaskIntoConstraints = false
        trackImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        trackImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        trackImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        trackImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        trackLabel.translatesAutoresizingMaskIntoConstraints = false
        trackLabel.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -30).isActive = true
        trackLabel.leadingAnchor.constraint(equalTo: trackImageView.trailingAnchor, constant: 20).isActive = true
        trackLabel.centerYAnchor.constraint(equalTo: trackImageView.centerYAnchor).isActive = true
        
    }
    
    private func updateUI(for track: Track) {
        if let artworkUrl = track.artworkUrl {
            
            trackImageView.af_setImage(withURL: artworkUrl, placeholderImage: UIImage(systemName: "music.note"), filter: RoundedCornersFilter(radius: 3.0)) { [unowned self] (response) in
                
                SearchCollectionViewController.imageCache.add(self.trackImageView.image!, for: URLRequest(url: artworkUrl), withIdentifier: String(track.id))
                
            }
        }
        
        trackLabel.text = track.title
        forwardButton.isEnabled = true
    }
    
    private func updateUIForLoading() {
        trackImageView.image = UIImage(systemName: "music.note")
        trackLabel.text = "Loading.."
        forwardButton.isEnabled = false
    }
    
    deinit {
        PlayerService.shared.removeClient(self)
    }
}
