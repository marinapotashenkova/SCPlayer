//
//  Track.swift
//  Project
//
//  Created by Марина on 22.01.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import Foundation

class Track: Codable {
    
    let id: Int
    let title: String
    let owner: Owner
    let artworkUrl: URL?
    var extendedInformation: TrackExtendedInformation?
    
    struct Owner: Codable {
        let name: String
        
        private enum CodingKeys: String, CodingKey {
            case name = "username"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case owner = "user"
        case artworkUrl = "artwork_url"
    }
    
    init(id: Int, title: String, owner: String, artworkUrl: URL?) {
        self.id = id
        self.title = title
        self.owner = Owner(name: owner)
        self.artworkUrl = artworkUrl
    }
    
}

struct TrackExtendedInformation: Codable {
    
    let description: String?
//    let artworkUrl: URL?
    var streamUrl: URL?
    
    private enum CodingKeys: String, CodingKey {
        case description
//        case artworkUrl = "artwork_url"
        case streamUrl = "stream_url"
    }
    
}
