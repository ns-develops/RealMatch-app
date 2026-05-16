//
//  MainTabView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
//

import SwiftUI

struct MainTabView: View {
    
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        
        TabView {
            
            SwipeView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Swipe")
                }
            
            LikesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Likes")
                }
            
            ChatListView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chats")
                }
            
            ProfileView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}
