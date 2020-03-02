//
//  UserRepository.swift
//  Project
//
//  Created by Марина on 23.01.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import Foundation

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

class UserRepository {
    
    static func save(_ user: User, from server: String) throws {
        
        guard let tokenData = try? JSONEncoder().encode(user.authInfo)
            else {
                // TODO: Handle the error of encoding
                print("Error of encoding")
                return
        }
        
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: user.name,
                                     kSecAttrServer as String: server,
                                     kSecValueData as String: tokenData]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        let defaults = UserDefaults.standard
        defaults.set(user.isLoggedIn, forKey: "condition")
        print("saved")
    }
    
    @discardableResult static func get(from server: String) throws -> User {
        
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let existingItem = item as? [String : Any],
            let tokenData = existingItem[kSecValueData as String] as? Data,
            let token = try? JSONDecoder().decode(AuthInfo.self, from: tokenData),
            let account = existingItem[kSecAttrAccount as String] as? String
        else {
            throw KeychainError.unexpectedPasswordData
        }
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: "condition")
        return User(name: account, authInfo: token, isLoggedIn: isLoggedIn)
    }
    
    static func update(user: User, from server: String) throws {
        
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server]
        
        let account = user.name
        let token = try! JSONEncoder().encode(user.authInfo)
        let attributes: [String: Any] = [kSecAttrAccount as String: account,
                                         kSecValueData as String: token]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    static func delete(from server: String) throws {
        
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
            
        }
    }
}

