//
//  PlayerService.swift
//  Project
//
//  Created by Марина on 20.02.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import Foundation
import AVFoundation

protocol ObservablePlayer {
    
    func addClient(_ observer: PlayerObserver)
    func removeClient(_ observer: PlayerObserver)
    
    func choose(trackNumber: Int)
    func playOrPause()
    func nextTrack()
    func prevTrack()
    func stopPlaying()
}

protocol PlayerObserver: class {
    
    func player(didStart track: Track)
    func player(paused track: Track)
    func player(continued track: Track)
    func player(changedTo track: Track)
    func player(isLoading track: Track)
}

class PlayerService: NSObject, ObservablePlayer {
    
    // MARK: - Singleton
    
    private static var uniqueInstance: PlayerService?
    
    private override init() {
        super.init()
        
    }
    
    static var shared: PlayerService {
        if uniqueInstance == nil {
            uniqueInstance = PlayerService()
        }
        
        return uniqueInstance!
    }
    
    var currentTrack: Track?
    var tracksClient: TracksClient!
    
    let player: AVPlayer = AVPlayer()
    var trackProgress: Float {
        return player.progress
    }
    var isPlaying: Bool {
        return player.isPlaying
    }
    
    private var currentItemContext = 0
    
    private var playingTrackNumber: Int?
    
    private var currentState = State.notDefined {
        didSet {
            stateDidChange(from: oldValue)
        }
    }
    
    private func stateDidChange(from oldState: State) {
        
        for (_, observation) in clients {
            
            guard let observer = observation.observer else {
                assertionFailure("Player's observer wasn't found")
                return
            }
            
            switch (oldState, currentState) {
            case (.notDefined, .playing(let trackNumber)):
                observer.player(didStart: Playlist.shared.tracks[trackNumber])
            case (.playing(let trackNumber), .paused):
                observer.player(paused: Playlist.shared.tracks[trackNumber])
            case (.paused(let trackNumber), .playing):
                observer.player(continued: Playlist.shared.tracks[trackNumber])
            case (.playing, .playing(let newTrackNumber)), (.paused, .paused(let newTrackNumber)):
                observer.player(changedTo: Playlist.shared.tracks[newTrackNumber])
            case (_, .notDefined):
                break
            case _ :
                assertionFailure("Undefined state changing")
            }
        }
    }
    
    // MARK: - ObservablePlayer
    
    private var clients = [ObjectIdentifier: Observation]()
    
    func addClient(_ observer: PlayerObserver) {
        let id = ObjectIdentifier(observer)
        clients[id] = Observation(observer: observer)
    }
    
    func removeClient(_ observer: PlayerObserver) {
        let id = ObjectIdentifier(observer)
        clients.removeValue(forKey: id)
    }
    
    func choose(trackNumber: Int) {
        guard trackNumber < Playlist.shared.tracks.count else {
            return
        }
        playingTrackNumber = trackNumber
        initializeTrack()
    }
    
    func playOrPause() {
        
        if case .notDefined = currentState {
            choose(trackNumber: 0)
            return
        }
        
        if player.isPlaying {
            player.pause()
            currentState = .paused(trackNumber: playingTrackNumber!)
        } else {
            player.play()
            currentState = .playing(trackNumber: playingTrackNumber!)
        }
    }
    
    func nextTrack() {
        guard playingTrackNumber != nil else {
            assertionFailure("Track wasn't defined but Player was asked for the next")
            return
        }
        playingTrackNumber! += 1
        initializeTrack()
    }
    
    func prevTrack() {
        guard playingTrackNumber != nil else {
            assertionFailure("Track wasn't chosen but Player was asked for the previous")
            return
        }
        if playingTrackNumber != 0 {
            playingTrackNumber! -= 1
        }
        initializeTrack()
    }
    
    func stopPlaying() {
        currentTrack = nil
        playingTrackNumber = nil
        player.pause()
        player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        player.replaceCurrentItem(with: nil)
        currentState = .notDefined
    }
    
    private func initializeTrack() {
        
        player.pause()
        player.seek(to: CMTime.zero)
        
        guard let playingTrackNumber = playingTrackNumber else {
            assertionFailure("playingTrackNumber wasn't initialized")
            return
        }
        
        currentTrack = Playlist.shared.tracks[playingTrackNumber]
        
        guard let track = currentTrack else {
            assertionFailure("Track wasn't chosen")
            return
        }
        
        for (_, observation) in clients {
            guard let observer = observation.observer else {
                assertionFailure("Player's observer wasn't found")
                return
            }
            
            observer.player(isLoading: track)
        }
        
        tracksClient = TracksClient(track: track)
        tracksClient.loadTrackInformation { [unowned self] (trackExtendedInformation) in
            Playlist.shared.tracks[playingTrackNumber].extendedInformation = trackExtendedInformation
            self.currentTrack?.extendedInformation = trackExtendedInformation
            if self.player.currentItem != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem!)
                self.player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            }
            let item = AVPlayerItem(url: trackExtendedInformation.streamUrl!)
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
            self.player.replaceCurrentItem(with: item)
            self.player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &self.currentItemContext)
        }
        
    }
    
    private func changeState() {
        
        guard let playingTrackNumber = playingTrackNumber else {
            assertionFailure("playingTrackNumber wasn't initialized")
            return
        }
        
        switch currentState {
        case .playing, .notDefined:
            player.play()
            currentState = .playing(trackNumber: playingTrackNumber)
        case .paused:
            player.pause()
            currentState = .paused(trackNumber: playingTrackNumber)
        }
    }
    
    @objc func playerDidFinishPlaying() {
        
        guard let playingTrackNumber = playingTrackNumber else {
            assertionFailure("Track wasn't chosen")
            return
        }
        
        if playingTrackNumber != Playlist.shared.tracks.count - 1 {
            nextTrack()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &currentItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            switch status {
            case .readyToPlay:
                changeState()
            case .failed:
                print("Item failed")
                // TODO: Handle Error
            case .unknown:
                print("unknown")
            @unknown default:
                assertionFailure("AVPlayerItem's status is unknown")
            }
        }
    }
    
    deinit {
        if player.currentItem != nil {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem!)
        }
    }
    
}

private extension PlayerService {
    
    enum State {
        case notDefined
        case playing(trackNumber: Int)
        case paused(trackNumber: Int)
    }
    
    struct Observation {
        weak var observer: PlayerObserver?
    }
}

extension AVPlayer {
    
    var isPlaying: Bool {
        return self.rate != 0 ? true : false
    }
    
    var progress: Float {
        guard self.currentItem != nil else {
            return 0
        }
        
        let duration = CMTimeGetSeconds(self.currentItem!.duration)
        if duration.isFinite && duration > 0 {
            return Float(CMTimeGetSeconds(self.currentItem!.currentTime())) / Float(duration)
        }
        
        return 0
    }
}
