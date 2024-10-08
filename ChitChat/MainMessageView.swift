//
//  MainMessageView.swift
//  ChitChat
//
//  Created by Ali Bashir on 9/4/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase



struct recentMessagesLog: Identifiable {
    var id: String {documentId}
    
    let documentId: String
    let fromUserId, toUserId, messageText, userEmail, userUid, profileImageUrl: String
    let time: Timestamp
    
    init(documentId: String, data: [String : Any]){
        self.documentId = documentId
        self.fromUserId = data["fromUserId"] as? String ?? ""
        self.toUserId = data["toUserId"] as? String ?? ""
        self.userEmail = data["userEmail"] as? String ?? "acnnot show"
        self.messageText = data["messageText"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.time = data["time"] as? Timestamp ?? Timestamp(date: Date())
        self.userUid = data["userUid"] as? String ?? ""
    }
}


class MainMessagesViewModel : ObservableObject {
    
    @Published var userRecentMessages = [recentMessagesLog]()
    @Published var errorMessage = ""
    @Published var currentUser: User?
    @Published var isUserCurrentlyLoggedOut = true
    private var listenerRegistration: ListenerRegistration?
    
    //----------------------------------------------------------------------------------------------------------------------
    
    init(){
        
        self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        
        fetchCurrentUser()
        fetchRecentMessages()
    }
    
    
    //--------------------------------------------------------------------------------------------------------------
    
    func fetchRecentMessages() {
        guard let currentUserUid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        
        listenerRegistration?.remove()
        self.userRecentMessages.removeAll()
        
        listenerRegistration = FirebaseManager.shared.fireStore.collection("recentMessages").document(currentUserUid).collection("recents").order(by: "time").addSnapshotListener { QuerySnapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            
            QuerySnapshot?.documentChanges.forEach { DocumentChange in
                if let index = self.userRecentMessages.firstIndex(where: { recentMessage in
                    return recentMessage.documentId == DocumentChange.document.documentID
                }) {
                    self.userRecentMessages.remove(at: index)
                }
                self.userRecentMessages.insert(.init(documentId: DocumentChange.document.documentID, data: DocumentChange.document.data()), at: 0)
                
            }
        }
        
    }
    
    
    
    //---------------------------------------------------------------------------------------------------------------
    
    
    
    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            DispatchQueue.main.async {
                self.errorMessage = "Could not fetch user uid"
            }
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            FirebaseManager.shared.fireStore.collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to fetch the current user \(error)"
                    }
                    return
                }
                guard let userData = snapshot?.data() else {
                    DispatchQueue.main.async {
                        self.errorMessage = "No data"
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.currentUser = .init(data: userData)
                    FirebaseManager.shared.currentUserEmail = self.currentUser?.email ?? ""
                    FirebaseManager.shared.currentUserProfileImageUrl = self.currentUser?.profileImageURL ?? ""
                }
            }
        }
    }
    
    
    
    //---------------------------------------------------------------------------------------------------------------
    
    
    
    func handleSignOut(){
        self.userRecentMessages.removeAll()
        isUserCurrentlyLoggedOut.toggle()
        FirebaseManager.shared.currentUserEmail = nil
        FirebaseManager.shared.currentUserProfileImageUrl = nil
        try? FirebaseManager.shared.auth.signOut()
    }
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------




struct MainMessageView: View {
    
    @State var showLogoutOption = false
    @ObservedObject private var userManager = MainMessagesViewModel()
    @State var showUserChatLogView = false
    private var userChatLogViewManager = UserChatLogViewManager(toUser: nil)
    
    var body: some View {
        
        NavigationView {
            VStack {
                customNavigationBar
                messagesList
                
                NavigationLink("", isActive: $showUserChatLogView){
                    UserChatLogView(logViewManager: userChatLogViewManager)
                    
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    //----------------------------------------------------------------------------------------------------------------------------------------------------------

    
    private var customNavigationBar: some View {
        HStack(spacing: 16) {
            
            var username = userManager.currentUser?.email.components(separatedBy: "@").first ?? ""
            var formattedUsername = username.prefix(1).uppercased() + username.dropFirst()
            
            WebImage(url: URL(string: userManager.currentUser?.profileImageURL ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 45, height: 45)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 44)
                    .stroke(Color(.yellow), lineWidth: 4)
                )
                .shadow(radius: 5)
            

            
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedUsername)
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.green)
                    
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }
            
            Spacer()
            
        }
        .padding()
        .actionSheet(isPresented: $showLogoutOption, content: {
            ActionSheet(
                title: Text("Settings"),
                message: Text("What do you want to do?"),
                buttons: [
                    .destructive(Text("Log Out"), action: {
                        print("Sign out")
                        userManager.handleSignOut()
                    }),
                    .cancel()
                ]
            )
        })
        .fullScreenCover(isPresented: $userManager.isUserCurrentlyLoggedOut, onDismiss: nil){
            LoginView(loginProcessComplete: {
                userManager.fetchCurrentUser()
                userManager.fetchRecentMessages()
                self.userManager.isUserCurrentlyLoggedOut = false
            })
        }
    }
    
    
    //----------------------------------------------------------------------------------------------------------------------------------------------------------

    
    func calcTime(recentMessageTime: Timestamp) -> String {
        let messageDate = recentMessageTime.dateValue()
        let now = Date()
        let calendar = Calendar.current
        
        let isSameDay = calendar.isDate(messageDate, inSameDayAs: now)
        
        let dateFormatter = DateFormatter()
        
        if isSameDay {
            // If it's today, show the time
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.string(from: messageDate)
        } else {
            // Check if the message was sent yesterday
            let oneDayAgo = calendar.date(byAdding: .day, value: -1, to: now)!
            if calendar.isDate(messageDate, inSameDayAs: oneDayAgo) {
                return "Yesterday"
            }
            
            // If it's within the last week, show the day of the week
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            if messageDate > weekAgo {
                dateFormatter.dateFormat = "EEEE"
                return dateFormatter.string(from: messageDate)
            }
            
            // Otherwise, show the full date (MM/dd/yyyy)
            dateFormatter.dateFormat = "MM/dd/yyyy"
            return dateFormatter.string(from: messageDate)
        }
    }
    
    
    //----------------------------------------------------------------------------------------------------------------------------------------------------------
    
    
    
    private var messagesList: some View {
        
        ScrollView {
            
            Spacer()
            ForEach($userManager.userRecentMessages) { $recentMessageUser in
                
                VStack {
                    NavigationLink {
                        let data = ["uid" : recentMessageUser.userUid, "email": recentMessageUser.userEmail, "profileImageURL": recentMessageUser.profileImageUrl]
                        let toUser = User(data: data)
                        
                        UserChatLogView(logViewManager: .init(toUser: toUser))
                    } label: {
                        
                        HStack(spacing: 16) {
                            
                            WebImage(url: URL(string: recentMessageUser.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 44)
                                    .stroke(Color(.yellow), lineWidth: 2)
                                )
                                .shadow(radius: 2)
                            
                            VStack(alignment: .leading) {
                                let username = recentMessageUser.userEmail.components(separatedBy: "@").first ?? ""
                                let formattedUsername = username.prefix(1).uppercased() + username.dropFirst()
                                Text(formattedUsername)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(.label))
                                
                                Text(recentMessageUser.messageText)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                            }
                            
                            Spacer()
                              
                            Text(calcTime(recentMessageTime: recentMessageUser.time))
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    Divider()
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }
        }
        .overlay(
            
            HStack {
                Button {
                    
                    shouldShowNewMessageView.toggle()
                } label: {
                    HStack {
                        Spacer()
                        Text("+ New Message")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical)
                    .background(Color.yellow)
                    .cornerRadius(32)
                    .padding(.horizontal)
                    .shadow(radius: 15)
                    .frame(width: 250)
                }.fullScreenCover(isPresented: $shouldShowNewMessageView) {
                    NewMessageView(didSelectNewUser: {user in
                        self.user = user
                        self.userChatLogViewManager.toUser = user
                        self.userChatLogViewManager.fetchAllMessages()
                        showUserChatLogView.toggle()
                    })
                }
                
                Button {
                    showLogoutOption.toggle()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "gear")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical)
                    .background(Color.red)
                    .cornerRadius(32)
                    .padding(.horizontal)
                    .shadow(radius: 15)
                    .frame(width: 100)
                }.fullScreenCover(isPresented: $shouldShowNewMessageView) {
                    NewMessageView(didSelectNewUser: {user in
                        self.user = user
                        showUserChatLogView.toggle()
                    })
                }
                
            },alignment: .bottom
        )
    }
    
    @State var user: User?
    
    @State var shouldShowNewMessageView = false
    
}

#Preview {
    MainMessageView()
}


