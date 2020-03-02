//
//  TrackList.swift
//  Project
//
//  Created by Марина on 22.01.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import Foundation

final class Playlist {
    
    private static var uniqueInstance: Playlist?
    
    private init() {}
    
    static var shared: Playlist {
        if uniqueInstance == nil {
            uniqueInstance = Playlist()
        }
        return uniqueInstance!
    }
    
    var tracks: [Track] = []
    
}
