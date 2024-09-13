//
//  NewMessageView.swift
//  ChitChat
//
//  Created by Ali Bashir on 9/6/24.
//

import SwiftUI
import SDWebImageSwiftUI





struct NewMessageView: View {
    
    
    
    private func getAllUsers(){
        FirebaseManager.shared.fireStore.collection("users").getDocuments { documentsSnapshot, error in
            if let error = error {
                print("Could not fetch users \(error)")
                return
            }
             
            documentsSnapshot?.documents.forEach({snapshot in
                let data = snapshot.data()
                if FirebaseManager.shared.auth.currentUser?.uid != data["uid"] as? String ?? "" {
                    users.append(.init(data: data))
                }
            })
        }
    }
    
    
    @Environment(\.presentationMode) var presentationMode
    let didSelectNewUser: (User) -> ()
    @State var users = [User]()
    @State var searchText = ""
    @State var showUsers = false
    @State var searchingUser = ""
   
    
    var body: some View {
        NavigationView {
            
            ScrollView{
                HStack {
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.yellow, lineWidth: 3)
                        )
                        .padding(12)

                    Button(action: {
                        if searchText == ""{
                            return
                        }
                        showUsers = true
                        searchingUser = searchText
                        searchText = ""
                        
                    }) {
                        Image(systemName: "magnifyingglass")
                            .padding(10)
                            .background(Color.yellow)
                            .foregroundColor(.white)
                            .cornerRadius(100)
                    }
                }
                .padding()

               Spacer()
                
                
                if showUsers {
                    ForEach(users){user in
                        
                        if user.email.uppercased() == searchingUser.uppercased(){
                            Button{
                                didSelectNewUser(user)
                                
                                presentationMode.wrappedValue.dismiss()

                            
                                
                            } label: {
                                HStack{
                                    WebImage(url: URL(string: user.profileImageURL))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipped()
                                        .cornerRadius(50)
                                        .overlay(RoundedRectangle(cornerRadius: 44)
                                            .stroke(Color(.yellow), lineWidth: 2)
                                        )
                                        .shadow(radius: 5)
                                   
                                    Text(user.email)
                                        .foregroundColor(.black)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }.padding(.horizontal)
                        }
                        }
                    }
                    
                }
                
                    
                }.navigationTitle("New ChitChat")
                
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading){
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                        }
                        
                    }
                }
        }
        .onAppear{
            getAllUsers()
        }
        
        
        
    }
}

#Preview {
    MainMessageView()
}
