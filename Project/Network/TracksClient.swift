//
//  TracksClient.swift
//  Project
//
//  Created by Марина on 03.02.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import Foundation
import Alamofire
import Parse

class TracksClient {
    
    let query: URLRequest
    
    private let clientId = Parse.applicationId
    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }
    
    init(track: Track) {
        
        var urlComponents = URLComponents(string: "https://api.soundcloud.com/tracks/\(track.id)")
        urlComponents!.queryItems = [URLQueryItem(name: "client_id", value: clientId)]

        let url = urlComponents!.url
        query = URLRequest(url: url!)
        
    }
    
    func loadTrackInformation(completionHandler: @escaping (TrackExtendedInformation) -> Void) {
        
        Alamofire.request(query).response { (response) in
            
            guard response.error == nil else {
                print("Error of track request: \(response.error!.localizedDescription)")
                return
            }
            
            if let httpResponse = response.response,
                httpResponse.statusCode != 200 {
                print("Error of track information request \(httpResponse.statusCode)")
                return
            }
            
            // TODO: Check errors of request and throw it
            
            if let data = response.data,
                var trackExtendedInformation = try? JSONDecoder().decode(TrackExtendedInformation.self, from: data) {
                let queryItems = [URLQueryItem(name: "client_id", value: self.clientId)]
                trackExtendedInformation.streamUrl = trackExtendedInformation.streamUrl?.appendParameteres(queryItems)
                completionHandler(trackExtendedInformation)
            }
        }
        
    }
    
    // without caching
    func loadImage(from artworkUrl: URL, completionHandler: @escaping (Data) -> Void) {

        session.dataTask(with: artworkUrl) { (data, response, error) in
            
            guard error == nil else {
                print("Error of track request: \(error!.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Error of track information request \(httpResponse.statusCode)")
                return
            }
            
            if let data = data {
                completionHandler(data)
            }
            
        }.resume()
    }
    
}

extension URL {
    
    func appendParameteres(_ queryItems: [URLQueryItem]) -> URL {
        
        guard var urlComponents = URLComponents(string: self.absoluteString) else {
            return self
        }
        
        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }
}

