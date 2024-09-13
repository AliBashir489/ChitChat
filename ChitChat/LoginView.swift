//
//  LoginView.swift
//  ChitChat
//
//  Created by Ali Bashir on 9/4/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore




struct LoginView: View {
    
    let loginProcessComplete: () -> ()
 
    
    @State var isLoginMode = false;
    @State var email = ""
    @State var password = ""
    @State var showImagePicker = false
    
    
    
    var body: some View {
        NavigationView{
            
            

            ScrollView{
                
                VStack(spacing: 16){
                    
                   
                    
                    Picker(selection: $isLoginMode, label: Text("Login Picker")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    
                    
                    
                    if !isLoginMode{
                        Button(action: {showImagePicker.toggle()},
                               label: {
                            
                            if let image = self.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 128, height: 128)
                                    .cornerRadius(64)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(Color.black, lineWidth: 4) // Black border with 4px thickness
                                    )
                                
                                
                                
                            }
                            else{
                                Image(systemName: "person.crop.circle.fill.badge.plus")
                                    .font(.system(size: 100))
                                    .padding(5)
                                    .foregroundColor(.black)
                            }
                            
                        })
                    
                    }
                    
                    
//
                    
                    
                    Group{
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
     
                        SecureField("Password", text: $password)
                        
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                            
                            
                    )
                    
                    
                    
                    Button(action: {handleAction()}, label: {
                        HStack{
                            Spacer()
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                                
                            Spacer()
                        }
                        .background(Color.black)
                        .cornerRadius(10)
                    })
                    
                    if self.loginStatusMessage != "" {
                        Text(self.loginStatusMessage)
                            .foregroundColor(.black)
                        .fontWeight(.semibold)
                    }
                    
                    
                }
                .padding()
                
                
                
                
                
            }
            .navigationTitle(isLoginMode ? "Welcome Back" : "Create Account")
            .background(
                        Image("Chit Chat Login") // Your image name from assets
                            .resizable()
                            .edgesIgnoringSafeArea(.all) // Ignore safe area if needed
                        
                            
                    )
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showImagePicker, onDismiss: nil) {
            ImagePicker(selectedImage: $image)
        }
    }
    
    
    
    
    @State var image: UIImage?
    
    private func handleAction(){
        if isLoginMode{
            loginUser()
        }
        else{
            createNewAccount()
        }
    }
    
    @State var loginStatusMessage = ""
    
    
    private func loginUser(){
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password){
            result, error in
            if let error = error {
                print("Failed to login user: ", error)
                self.loginStatusMessage = "\(error.localizedDescription)"
                return
            }
            
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = ""

            self.loginProcessComplete()
                
        }
    }
    
    private func createNewAccount(){
        
        if self.image == nil {
            self.loginStatusMessage = "You must select a profile picture"
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password){
            result, error in
            if let error = error {
                print("Failed to create user: \(error)")
                self.loginStatusMessage = "\(error.localizedDescription)"
                return
            }
            
            print("Successfully created user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Creating user..."
            
            
                self.saveImageToStorage()

            
                

            
        }
    }
    
    private func saveImageToStorage(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else{return}
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5)
        else {return}
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err{
                loginStatusMessage = "Failed to upload profile image: \(err.localizedDescription)"
                return
            }
            
            ref.downloadURL {url, err in
                if let err = err{
                    loginStatusMessage = "Failed to retrive donwloadURL: \(err.localizedDescription)"
                    return
                }
                self.loginStatusMessage = "Saving profile image..."
                
                guard let url = url else {return}
        
                storeUserInformation(imageProfileUrl: url)
                self.loginProcessComplete()
                
            }
            
            
            
            
            
            
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        let userData = ["email": self.email, "uid": uid, "profileImageURL": imageProfileUrl.absoluteString]
        FirebaseManager.shared.currentUserProfileImageUrl = imageProfileUrl.absoluteString
        FirebaseManager.shared.currentUserEmail = self.email
        FirebaseManager.shared.fireStore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err.localizedDescription)
                    self.loginStatusMessage = "\(err)"
                    return
                    
                }
                self.loginStatusMessage = "Logging in..."
                print("Successful")
            }
        
    }
    
}

#Preview {
    LoginView(loginProcessComplete: {})
}
