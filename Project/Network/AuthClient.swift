//
//  AuthClient.swift
//  Project
//
//  Created by Марина on 28.01.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import Foundation
import Alamofire
import Parse

struct AuthInfo: Codable {
    let refreshToken: String
    let accessToken: String
    let scope: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
        case accessToken = "access_token"
        case scope
        case expiresIn = "expires_in"
    }
}

class AuthClient {
    
    private let clientId = Parse.applicationId
    private let clientSecret = Parse.clientKey!
    private var loginInfo: (username: String?, password: String?)
    private var authInfo: AuthInfo?
    
    private let server = "www.soundcloud.com"
    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }
    
    // MARK: - Initializers
    
    init(username: String, password: String) {
        loginInfo.username = username
        loginInfo.password = password
    }
    
    init(authInfo: AuthInfo) {
        self.authInfo = authInfo
    }
    
    // MARK: - Requests
    
    private var meRequest: URLRequest {
        var urlComponents = URLComponents(string: "https://api.soundcloud.com/me")
        urlComponents!.queryItems = [URLQueryItem(name: "oauth_token", value: authInfo?.accessToken)]

        let url = urlComponents!.url
        return URLRequest(url: url!)
    }
    
    private var authRequest: URLRequest {
        
        var urlComponents = URLComponents(string: "https://api.soundcloud.com/oauth2/token")
        urlComponents!.queryItems = [URLQueryItem(name: "client_id", value: clientId),
                                    URLQueryItem(name: "client_secret", value: clientSecret),
                                    URLQueryItem(name: "username", value: loginInfo.username),
                                    URLQueryItem(name: "password", value: loginInfo.password),
                                    URLQueryItem(name: "scope", value: "*"),
                                    URLQueryItem(name: "grant_type", value: "password")
        ]

        let url = urlComponents!.url
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        return urlRequest
    }
    
    private var refreshTokenRequest: URLRequest {
        
        var urlComponents = URLComponents(string: "https://api.soundcloud.com/oauth2/token")
        urlComponents!.queryItems = [URLQueryItem(name: "client_id", value: clientId),
                                    URLQueryItem(name: "client_secret", value: clientSecret),
                                    URLQueryItem(name: "grant_type", value: "refresh_token"),
                                    URLQueryItem(name: "refresh_token", value: authInfo?.refreshToken)
        ]

        let url = urlComponents!.url
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        return urlRequest
    }
    
    // MARK: Authorization
    
    func authorize(completionHandler: @escaping (User) -> Void) {
        
        Alamofire.request(authRequest).response { (response) in
            
            guard response.error == nil else {
                print("Error of authorizing: \(response.error!.localizedDescription)")
                return
            }
                
                // TODO: Handle case if user's input data were wrong
                
            if let httpResponse = response.response, httpResponse.statusCode != 200 {
                print("Error of auth request \(httpResponse.statusCode)")
                return
            }
                
            // TODO: Check errors of request and throw it
                
            if let data = response.data,
                let authInfo = try? JSONDecoder().decode(AuthInfo.self, from: data) {
                self.authInfo = authInfo
                print("Token: \(self.authInfo!.accessToken)")
                self.getMe(completionHandler: completionHandler)
            }
        }

    }
    
    func getMe(completionHandler: @escaping (User) -> Void) {
        
        Alamofire.request(meRequest).response { (response) in
            guard response.error == nil else {
                print("Error of getting \\me request: \(response.error!.localizedDescription)")
                return
            }
            
            if let httpResponse = response.response,
                httpResponse.statusCode == 401 {
                self.refreshToken(completionHandler: completionHandler)
            }
            
            if let data = response.data {
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    print("Couldn't parse data")
                    return
                }
                let user = User(name: json["username"] as! String, authInfo: self.authInfo!, isLoggedIn: true)
                completionHandler(user)
            }
        }
        
    }
    
    private func refreshToken(completionHandler: @escaping (User) -> Void) {
        
        Alamofire.request(refreshTokenRequest).response { (response) in
            
            guard response.error == nil else {
                print("Error of refreshing request: \(response.error!.localizedDescription)")
                return
            }
            
            // TODO: Handle case if user's input data were wrong
            
            if let httpResponse = response.response,
                httpResponse.statusCode != 200 {
                print("Error of refreshing request: \(httpResponse.statusCode)")
                return
            }
            
            // TODO: Check errors of request and throw it
            
            if let data = response.data,
                let authInfo = try? JSONDecoder().decode(AuthInfo.self, from: data) {
                self.authInfo = authInfo
                print("New token: \(self.authInfo!.accessToken)")
                self.getMe(completionHandler: completionHandler)
            }
        }
        
    }

}
