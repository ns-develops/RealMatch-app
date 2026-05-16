//
//  SwipeView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct UserModel: Identifiable {
    
    let id: String
    let images: [String]
}

struct SwipeView: View {
    
    @State private var users: [UserModel] = []
    
    @State private var currentUserIndex = 0
    @State private var currentImageIndex = 0
    
    @State private var liked = false
    
    var body: some View {
        
        VStack {
            
            Spacer()
            
            // MARK: - Empty State
            if users.isEmpty {
                
                Text("Inga användare")
                    .font(.title2)
                    .foregroundColor(.gray)
                
            } else {
                
                let user = users[currentUserIndex]
                let images = user.images
                
                ZStack {
                    
                    // MARK: - Image Carousel
                    TabView(selection: $currentImageIndex) {
                        
                        ForEach(images.indices, id: \.self) { index in
                            
                            AsyncImage(url: URL(string: images[index])) { image in
                                
                                image
                                    .resizable()
                                    .scaledToFill()
                                
                            } placeholder: {
                                
                                Color.gray.opacity(0.2)
                            }
                            .tag(index)
                            .frame(width: 350, height: 500)
                            .clipped()
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(width: 350, height: 500)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    
                    // MARK: - Like Button
                    VStack {
                        
                        Spacer()
                        
                        HStack {
                            
                            Spacer()
                            
                            Button {
                                toggleLike()
                            } label: {
                                
                                Image(systemName: liked ? "heart.fill" : "heart")
                                    .font(.system(size: 28))
                                    .foregroundColor(liked ? .red : .gray)
                                    .padding(16)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding(.trailing, 25)
                            .padding(.bottom, 20)
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - Next User Button
                Button {
                    nextUser()
                } label: {
                    
                    Text("Nästa")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            fetchUsers()
        }
    }
    
    // MARK: - Fetch Users From Realtime Database
    func fetchUsers() {
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        
        ref.child("users")
            .observeSingleEvent(of: .value) { snapshot in
                
                var loadedUsers: [UserModel] = []
                
                for child in snapshot.children {
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any] else {
                        continue
                    }
                    
                    let userId = snap.key
                    
                    // MARK: - Exclude Yourself
                    if userId == currentUserId {
                        continue
                    }
                    
                    // MARK: - Get Images
                    if let images = data["images"] as? [String],
                       !images.isEmpty {
                        
                        let user = UserModel(
                            id: userId,
                            images: images
                        )
                        
                        loadedUsers.append(user)
                    }
                }
                
                DispatchQueue.main.async {
                    self.users = loadedUsers
                }
            }
    }
    
    // MARK: - Toggle Like
    func toggleLike() {
        
        liked.toggle()
        
        if liked {
            likeUser()
        }
    }
    
    // MARK: - Save Like
    func likeUser() {
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let likedUserId = users[currentUserIndex].id
        
        let ref = Database.database().reference()
        
        ref.child("likes")
            .child(currentUserId)
            .child(likedUserId)
            .setValue(true)
    }
    
    // MARK: - Next User
    func nextUser() {
        
        guard !users.isEmpty else {
            return
        }
        
        liked = false
        currentImageIndex = 0
        
        if currentUserIndex < users.count - 1 {
            currentUserIndex += 1
        } else {
            currentUserIndex = 0
        }
    }
}
