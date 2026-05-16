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
    
    // 👇 MATCH TEXT STATE
    @State private var showMatchText = false
    
    var body: some View {
        VStack {
            
            Spacer()
            
            if users.isEmpty {
                
                Text("Inga användare")
                    .font(.title2)
                    .foregroundColor(.gray)
                
            } else {
                
                let user = users[currentUserIndex]
                let images = user.images
                
                ZStack {
                    
                    // MARK: - Images
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
                
                // MARK: - Next Button
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
        // MARK: - MATCH OVERLAY
        .overlay(
            Group {
                if showMatchText {
                    ZStack {
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        
                        Text("Matching Friend")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(15)
                    }
                    .transition(.opacity)
                }
            }
        )
        .animation(.easeInOut, value: showMatchText)
    }
    
    // MARK: - FETCH USERS
    func fetchUsers() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference()
        
        ref.child("users").observeSingleEvent(of: .value) { snapshot in
            
            var loadedUsers: [UserModel] = []
            
            for child in snapshot.children {
                
                guard let snap = child as? DataSnapshot,
                      let data = snap.value as? [String: Any] else { continue }
                
                let userId = snap.key
                
                if userId == currentUserId { continue }
                
                if let images = data["images"] as? [String],
                   !images.isEmpty {
                    
                    loadedUsers.append(UserModel(id: userId, images: images))
                }
            }
            
            DispatchQueue.main.async {
                self.users = loadedUsers
            }
        }
    }
    
    // MARK: - LIKE
    func toggleLike() {
        liked.toggle()
        
        if liked {
            likeUser()
        }
    }
    
    // MARK: - SAVE LIKE + CHECK MATCH
    func likeUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard !users.isEmpty else { return }
        
        let likedUserId = users[currentUserIndex].id
        
        let ref = Database.database().reference()
        
        // Save like
        ref.child("likes")
            .child(currentUserId)
            .child(likedUserId)
            .setValue(true)
        
        // Check match
        checkMatch(likedUserId: likedUserId)
    }
    
    // MARK: - CHECK MATCH
    func checkMatch(likedUserId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference()
        
        ref.child("likes")
            .child(likedUserId)
            .child(currentUserId)
            .observeSingleEvent(of: .value) { snapshot in
            
                if snapshot.exists() {
                    createMatch(with: likedUserId)
                }
            }
    }
    
    // MARK: - CREATE MATCH
    func createMatch(with userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference()
        
        let matchId = ref.child("matches").childByAutoId().key ?? UUID().uuidString
        
        let matchData: [String: Any] = [
            "users": [currentUserId, userId],
            "timestamp": Date().timeIntervalSince1970
        ]
        
        ref.child("matches")
            .child(matchId)
            .setValue(matchData)
        
        // 👇 VISA TEXT
        DispatchQueue.main.async {
            showMatchText = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showMatchText = false
            }
        }
    }
    
    // MARK: - NEXT USER
    func nextUser() {
        guard !users.isEmpty else { return }
        
        liked = false
        currentImageIndex = 0
        
        if currentUserIndex < users.count - 1 {
            currentUserIndex += 1
        } else {
            currentUserIndex = 0
        }
    }
}
