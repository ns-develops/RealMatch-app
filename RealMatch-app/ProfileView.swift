//
//  ProfileView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
//
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        
        VStack {
            
            Text("Profile")
            
            Button("Logga ut") {
                try? Auth.auth().signOut()
                isLoggedIn = false
            }
        }
    }
}
