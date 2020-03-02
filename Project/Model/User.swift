//
//  User.swift
//  Project
//
//  Created by Марина on 22.01.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import Foundation

struct User {
    
    let name: String
    let authInfo: AuthInfo
    var isLoggedIn: Bool

    // Some other user information if needed
    
    init(name: String, authInfo: AuthInfo, isLoggedIn: Bool) {
        self.name = name
        self.authInfo = authInfo
        self.isLoggedIn = isLoggedIn
    }
    
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.name == rhs.name && lhs.authInfo.accessToken == rhs.authInfo.accessToken
    }
    
    static func !=(lhs: User, rhs: User) -> Bool {
        return !(lhs == rhs)
    }
}

