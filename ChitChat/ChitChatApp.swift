//
//  ChitChatApp.swift
//  ChitChat
//
//  Created by Ali Bashir on 9/4/24.
//

import SwiftUI
import Firebase

@main
struct ChitChatApp: App {
    init() {
            FirebaseApp.configure()
        }
    
    var body: some Scene {
        WindowGroup {
            MainMessageView()
        }
    }
}

