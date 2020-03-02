//
//  SearchClient.swift
//  Project
//
//  Created by Марина on 30.01.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import Foundation
import Alamofire
import Parse

class SearchClient {
    
    private let clientId = Parse.applicationId
    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }

    private var searchRequest: URLRequest?
    
    struct SearchResponse: Codable {
        let collection: [Track]
        let nextRequest: URL?
        
        private enum CodingKeys: String, CodingKey {
            case collection
            case nextRequest = "next_href"
        }
    }
    
    init(query: String) {
        var urlComponents = URLComponents(string: "https://api.soundcloud.com/tracks")
        urlComponents!.queryItems = [URLQueryItem(name: "client_id", value: clientId),
                                    URLQueryItem(name: "q", value: query),
                                    URLQueryItem(name: "limit", value: "25"),
                                    URLQueryItem(name: "linked_partitioning", value: "1")
        ]

        let url = urlComponents!.url
        searchRequest = URLRequest(url: url!)
    }
    
    func search(completionHandler: @escaping ([Track]) -> Void) {

//        print("Search request: \(searchRequest)")
        guard let request = searchRequest else {
            return
        }
        
        Alamofire.request(request).response { (response) in
            
            guard response.error == nil else {
                print("Error of authorizing: \(response.error!.localizedDescription)")
                return
            }
            
            if let httpResponse = response.response,
                httpResponse.statusCode != 200 {
                print("Error of auth request \(httpResponse.statusCode)")
                return
            }
            
            // TODO: Check errors of request and throw it
            
            if let data = response.data,
                let searchResponse = try? JSONDecoder().decode(SearchResponse.self, from: data) {
                self.searchRequest = (searchResponse.nextRequest != nil) ? URLRequest(url: searchResponse.nextRequest!) : nil
//                print("Next request: \(self.searchRequest)")
                completionHandler(searchResponse.collection)
            }
            
        }
        
//        session.dataTask(with: request) { [unowned self] (data, response, error) in
//            
//            guard error == nil else {
//                print("Error of authorizing: \(error!.localizedDescription)")
//                return
//            }
//            
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
//                print("Error of auth request \(httpResponse.statusCode)")
//                return
//            }
//            
//            // TODO: Check errors of request and throw it
//            
//            if let data = data,
//                let searchResponse = try? JSONDecoder().decode(SearchResponse.self, from: data) {
//                self.searchRequest = (searchResponse.nextRequest != nil) ? URLRequest(url: searchResponse.nextRequest!) : nil
////                print("Next request: \(self.searchRequest)")
//                completionHandler(searchResponse.collection)
//            }
//
//        }.resume()
    }
}
