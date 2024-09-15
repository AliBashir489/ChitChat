//
//  FirebaseManager.swift
//  ChitChat
//
//  Created by Ali Bashir on 9/5/24.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class FirebaseManager: NSObject{
    let auth: Auth
    let storage : Storage
    let fireStore : Firestore
    var currentUserEmail: String? = nil
    var currentUserProfileImageUrl: String? = nil
    var toUserProfileImageUrl: String? = nil
    static let shared = FirebaseManager()
    @Published var errorMessage = ""

    
    override init(){
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.fireStore = Firestore.firestore()
        super.init()
 
        
        
    }
}
