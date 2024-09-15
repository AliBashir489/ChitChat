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


//------------------------------------------------------------------------------------------------------------------------------------------------------------

class UserChatLogViewManager: ObservableObject {
    
    @Published var cText = ""
    @Published var errorMessage = ""
    @Published var allChatMessages = [Message]()
    @Published var toUrl = ""
    @Published var count = 0
    
    var listenerRegistration: ListenerRegistration?
    var toUser: User?
    
    
    init(toUser: User?){
        self.toUser = toUser
        fetchAllMessages()
        print(toUser?.profileImageURL)
        print("look for this. abocve should ne the link")
    }
    
   //------------------------------------------------------------------------------------------------------------------------------------------------
    
    
    func fetchAllMessages() {
        guard let fromUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toUserId = toUser?.uid else { return }
        listenerRegistration?.remove()
        allChatMessages.removeAll()
        
        DispatchQueue.global(qos: .background).async {
            self.listenerRegistration = FirebaseManager.shared.fireStore.collection("userMessages").document(fromUserId).collection(toUserId).order(by: "time")
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
    
    
    //------------------------------------------------------------------------------------------------------------------------------------
    
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
    
    
    //------------------------------------------------------------------------------------------------------------------------
    
    
    func saveRecentMessage() {
        
        guard let toUserId = toUser?.uid else {
            print("Failed to get toUserId")
            return
        }
        guard let fromUserId = FirebaseManager.shared.auth.currentUser?.uid else {
            print("Failed to get fromUserId")
            return
        }
        
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
            "messageText": cText,
            "time": Timestamp(),
            "userEmail": toUser?.email ?? "",
            "profileImageUrl": toUrl,  // Ensure this is set this line check
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
            "messageText": self.cText,
            "time": Timestamp(),
            "userEmail": FirebaseManager.shared.currentUserEmail,
            "profileImageUrl": FirebaseManager.shared.currentUserProfileImageUrl,
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

//------------------------------------------------------------------------------------------------------------------------------------

struct UserChatLogView: View {
    
    @ObservedObject var logViewManager: UserChatLogViewManager
    
 
    func fetchUserProfileImageUrl() {
        guard let toUserUid = logViewManager.toUser?.uid else {
            return
        }
        
        print(logViewManager.toUser?.email)
        DispatchQueue.global(qos: .background).async {
            FirebaseManager.shared.fireStore.collection("users").document(toUserUid).getDocument { snapshot, error in
                // Handle errors or missing document
                if let error = error {
                    print("Error retrieving document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot, document.exists else {
                    print("Document does not exist")
                    return
                }
                
                let data = document.data()
                let profileImageUrl = data?["profileImageURL"] as? String ?? ""
                
                
                DispatchQueue.main.async {
                    self.logViewManager.toUrl = profileImageUrl
                    print("Profile Image URL: \(self.logViewManager.toUrl)")
                }
            }
        }
    }
    
    //------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    var body: some View {
        
        NavigationView {
            VStack {
                let username = logViewManager.toUser?.email.components(separatedBy: "@").first ?? ""
                let formattedUsername = username.prefix(1).uppercased() + username.dropFirst()
                messagesView
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle(formattedUsername)
                    .onDisappear{
                        logViewManager.listenerRegistration?.remove()
                    }
                
                bottomChatBar
                    .background(Color.white)
                
            }
            .background(Color(.init(white: 0.95, alpha: 1)))
            .onAppear(perform: {
                fetchUserProfileImageUrl()
                
                print("ghello")
            })
        }
    }
    
    
    
    //------------------------------------------------------------------------------------------------------------------------
    
    
    
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
                        .background(FirebaseManager.shared.auth.currentUser?.uid ?? "" == messageDocument.fromUserId ? Color.yellow : Color(white: 0.85))
                        .cornerRadius(20)
                        
                        if FirebaseManager.shared.auth.currentUser?.uid ?? "" != messageDocument.fromUserId {
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                }
                HStack { Spacer() }
                    .id("scrollLocation")
                    .onChange(of: logViewManager.allChatMessages.count) { _ in
                        ScrollViewLocation.scrollTo("scrollLocation", anchor: .bottom)
                    }    
                    .onAppear {
                        
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 1)) {
                                ScrollViewLocation.scrollTo("scrollLocation", anchor: .bottom)
                            }
                        }
                    }
            }
        }
    }
    
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
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
