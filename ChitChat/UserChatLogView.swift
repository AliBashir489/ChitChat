import SwiftUI
import Firebase



struct Message: Identifiable {
    
    var id : String {documentId}
    
    let documentId: String
    let fromUserId, toUserId, message: String
    
    init(data : [String : Any], documentId: String) {
        self.fromUserId = data["fromUserId"] as? String ?? ""
        self.toUserId = data["toUserId"] as? String ?? ""
        self.message = data["messageText"] as? String ?? ""
        self.documentId = documentId
    }
}

class UserChatLogViewManager: ObservableObject {
    
    @Published var cText = ""
    @Published var errorMessage = ""
    @Published var allChatMessages = [Message]()
    
    
    let toUser: User?
    
    init(toUser: User?){
        self.toUser = toUser
        fetchAllMessages()
    }
    
    private func fetchAllMessages() {
        guard let fromUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toUserId = toUser?.uid else { return }

        DispatchQueue.global(qos: .background).async {
            FirebaseManager.shared.fireStore.collection("userMessages").document(fromUserId).collection(toUserId).order(by: "time")
                .addSnapshotListener { QuerySnapshot, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                        }
                        return
                    }

                    QuerySnapshot?.documentChanges.forEach({ DocumentChange in
                        if DocumentChange.type == .added {
                            let data = DocumentChange.document.data()
                            let uniqueDocumentId = DocumentChange.document.documentID
                            let messageInstance = Message(data: data, documentId: uniqueDocumentId)

                            DispatchQueue.main.async {
                                self.allChatMessages.append(messageInstance)
                            }
                        }
                    })

                    DispatchQueue.main.async {
                        self.count += 1
                    }
                }
        }
    }

    
    @Published var count = 0
    
    func handleSend() {
        print(cText)
        guard let fromUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toUserId = toUser?.uid else { return }

        if cText.isEmpty {
            DispatchQueue.main.async {
                self.errorMessage = "No Message Entered"
            }
            return
        }

        DispatchQueue.global(qos: .background).async {
            let fromUserDocument = FirebaseManager.shared.fireStore.collection("userMessages")
                .document(fromUserId).collection(toUserId).document()

            let data = ["fromUserId": fromUserId, "toUserId": toUserId, "messageText": self.cText, "time": Timestamp()] as [String: Any]

            fromUserDocument.setData(data) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }
            }

            let toUserDocument = FirebaseManager.shared.fireStore.collection("userMessages")
                .document(toUserId).collection(fromUserId).document()

            toUserDocument.setData(data) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }
                
              
                self.saveRecentMessage()

                DispatchQueue.main.async {
                    self.cText = ""
                }
            }
        }
    }

    
    func saveRecentMessage() {
        guard let toUserId = toUser?.uid else {
            print("Failed to get toUserId")
            return
        }
        guard let fromUserId = FirebaseManager.shared.auth.currentUser?.uid else {
            print("Failed to get fromUserId")
            return
        }

        // Log the data being passed for debugging
        print("Saving recent message...")
        print("Message text: \(cText)")
        print("To user email: \(toUser?.email ?? "No email")")
        print("To user profile image URL: \(toUser?.profileImageURL ?? "")")

        let recentMessageDocumentForFromUser = FirebaseManager.shared.fireStore
            .collection("recentMessages")
            .document(fromUserId)
            .collection("recents")
            .document(toUserId)

        let recentMessageDocumentForToUser = FirebaseManager.shared.fireStore
            .collection("recentMessages")
            .document(toUserId)
            .collection("recents")
            .document(fromUserId)

        let fromUserRecentsData = [
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "messageText": cText,  // Check if this is correct
            "time": Timestamp(),
            "userEmail": toUser?.email ?? "",  // Verify this is not nil
            "profileImageUrl": toUser?.profileImageURL ?? "",  // Ensure this is set
            "userUid": toUser?.uid ?? ""
        ] as [String: Any]

        recentMessageDocumentForFromUser.setData(fromUserRecentsData) { error in
            if let error = error {
                print("Error saving recent message for from user: \(error.localizedDescription)")
                return
            }
            print("Recent message saved for fromUserId: \(fromUserId)")
        }

        let toUserRecentsData = [
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "messageText": self.cText,  // Check this
            "time": Timestamp(),
            "userEmail": FirebaseManager.shared.currentUserEmail,  // Ensure this is set
            "profileImageUrl": FirebaseManager.shared.currentUserProfileImageUrl,  // Ensure this is set
            "userUid": FirebaseManager.shared.auth.currentUser?.uid ?? ""
        ] as [String: Any]

        recentMessageDocumentForToUser.setData(toUserRecentsData) { error in
            if let error = error {
                print("Error saving recent message for to user: \(error.localizedDescription)")
                return
            }
            print("Recent message saved for toUserId: \(toUserId)")
        }
    }


    
}





struct UserChatLogView: View {
    let toUser: User?
    @ObservedObject var logViewManager = UserChatLogViewManager(toUser: nil)

    init(toUser: User?){
        self.toUser = toUser
        self.logViewManager  = UserChatLogViewManager(toUser: self.toUser)
    }
    

    var body: some View {
        NavigationView {
            VStack {
                Text(logViewManager.errorMessage)
                
                messagesView
                    .navigationTitle(toUser?.email ?? "")
                    .navigationBarTitleDisplayMode(.inline)
                bottomChatBar
                    .background(Color.white)
                
            }
            
            .toolbarBackground(Color.white.opacity(0.5), for: .navigationBar)
            .background(Color(.init(white: 0.95, alpha: 1)))
                
        }
    }

    
    
    
    
    
    
    
    
    
    private var messagesView: some View {
        ScrollView {
            ScrollViewReader { ScrollViewLocation in
                ForEach(logViewManager.allChatMessages) { messageDocument in
                    HStack {
                        if FirebaseManager.shared.auth.currentUser?.uid ?? "" == messageDocument.fromUserId {
                            Spacer()
                        }
                        HStack {
                            Text(messageDocument.message)
                                .foregroundColor(FirebaseManager.shared.auth
                                    .currentUser?.uid ?? "" == messageDocument.fromUserId ? .white : .black)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(FirebaseManager.shared.auth
                            .currentUser?.uid ?? "" == messageDocument.fromUserId ? Color.blue: Color(white: 0.85))
                        .cornerRadius(20)
                        
                        if FirebaseManager.shared.auth.currentUser?.uid ?? "" != messageDocument.fromUserId {
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    
                    
                }
                HStack{Spacer()}
                    .id("scrollLocation")
                    .onReceive(logViewManager.$count) { _ in
                            withAnimation(.easeOut(duration: 1)) {
                                ScrollViewLocation.scrollTo("scrollLocation", anchor: .bottom)
                            }
                    }
                
            }
            
           
            
        }
    }
    
    private var bottomChatBar: some View{
        // Chat bar
        HStack {
            
            
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 20))
            
            
            ZStack{
                
                TextEditor(text: $logViewManager.cText)
                    .opacity(logViewManager.cText.isEmpty ? 0.5 : 1)
                    .frame(width: 300, height: 40, alignment: .leading)
                
                if(logViewManager.cText == ""){
                    Text("ChitChat")
                        .fontWeight(.light)
                        .foregroundColor(.black.opacity(0.25))
                        .padding(8)
                        .offset(CGSize(width: -110.0, height: 0))
                }
                
               
                    
                
            }
            
            Button{
                print(logViewManager.cText)
                logViewManager.handleSend()
                logViewManager.count += 1
            } label: {
                Image(systemName: "arrow.up")
                    .foregroundColor(.white)
                    .bold()
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(Color.yellow)
            .cornerRadius(100)
       
            


        }
        .background(Color.white)
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
    
    
    
    
}

#Preview {
    MainMessageView()
}
