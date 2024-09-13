//
//  ContentView.swift
//  ChitChat
//
//  Created by Ali Bashir on 9/4/24.
//

import SwiftUI
import Firebase

struct LoginView: View {
    
    @State var isLoginMode = false;
    @State var email = ""
    @State var password = ""
    
    init(){
        FirebaseApp.configure()
    }

    
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
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/,
                               label: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 64))
                                .padding()
                        })
                    }
                    
                    
                    Group{
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                        
                    }
                    .padding(12)
                    .background(Color.white)
                    
                    
                    Button(action: {handleAction()}, label: {
                        HStack{
                            Spacer()
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .background(Color.blue)
                    })
                    
                    
                }
                .padding()
                
                

                
            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea())
            
        }
    }
    
    
    private func handleAction(){
        if isLoginMode{
            //login to firebase
        }
        else{
            //create new account
        }
    }
    
}

#Preview {
    LoginView()
}
