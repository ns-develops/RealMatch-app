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
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Likes")
                }
            
         
            
            ProfileView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}
