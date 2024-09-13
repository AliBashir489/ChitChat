//
//  User.swift
//  ChitChat
//
//  Created by Ali Bashir on 9/6/24.
//

import Foundation

struct User: Identifiable {
    
    var id : String {uid}
    let uid, email, profileImageURL, username: String
    
    init(data: [String : Any]) {
        uid = data["uid"] as? String ?? ""
        email = data["email"] as? String ?? ""
        profileImageURL = data["profileImageURL"] as? String ?? ""
        username = self.email.components(separatedBy: "@").first ?? ""
    }
}
