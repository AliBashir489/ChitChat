//
//  ContentView.swift
//  inline
//
//  Created by Ali Bashir on 9/14/24.
//

import SwiftUI


struct ContentView1: View {
    var body: some View {
        NavigationView {
            ScrollView{
                VStack {
                    Text("Home View")
                        .font(.largeTitle)
                        .padding()
                    
                    NavigationLink(destination: DetailView()) {
                        Text("Go to Detail View")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct DetailView: View {
    var body: some View {
        VStack {
            Text("Detail View")
                .font(.largeTitle)
                .padding()

            Text("You are now on the detail view!")
                .padding()
        }
        .navigationTitle("Detail")
    }
}




#Preview {
    ContentView1()
}
