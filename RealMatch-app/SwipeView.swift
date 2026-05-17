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
    let name: String
    let age: String
    let bio: String
    let images: [String]
}

struct SwipeView: View {
    
    @State private var users: [UserModel] = []
    
    @State private var currentUserIndex = 0
    @State private var currentImageIndex = 0
    
    @State private var liked = false
    @State private var showMatchText = false
    
    var body: some View {
        VStack {
            
            Spacer()
            
            if users.isEmpty {
                
                Text("Inga användare")
                    .font(.title2)
                    .foregroundColor(.gray)
                
            } else if users.indices.contains(currentUserIndex) {
                
                let user = users[currentUserIndex]
                
                ZStack {
                    
                    // MARK: - IMAGES
                    TabView(selection: $currentImageIndex) {
                        
                        ForEach(user.images.indices, id: \.self) { index in
                            
                            AsyncImage(url: URL(string: user.images[index])) { image in
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
                    
                    // MARK: - LIKE BUTTON
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
                
                // MARK: - USER INFO
                VStack(spacing: 8) {
                    
                    Text(user.name)
                        .font(.title2)
                        .bold()
                    
                    Text(user.age)
                        .foregroundColor(.gray)
                    
                    // 👇 BIO
                    if !user.bio.isEmpty {
                        
                        Text(user.bio)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 30)
                            .padding(.top, 5)
                    }
                }
                .padding(.top, 10)
                
                Spacer()
                
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
                
                let name = data["name"] as? String ?? ""
                let bio = data["bio"] as? String ?? ""
                
                var ageText = ""
                
                if let timestamp = data["birthDate"] as? Double {
                    
                    let date = Date(timeIntervalSince1970: timestamp)
                    
                    let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
                    
                    ageText = "\(years) år"
                }
                
                let images = data["images"] as? [String] ?? []
                
                if !images.isEmpty {
                    
                    loadedUsers.append(
                        UserModel(
                            id: userId,
                            name: name,
                            age: ageText,
                            bio: bio,
                            images: images
                        )
                    )
                }
            }
            
            DispatchQueue.main.async {
                self.users = loadedUsers
            }
        }
    }
    
    // MARK: - LIKE LOGIC
    func toggleLike() {
        liked.toggle()
        
        if liked {
            likeUser()
        }
    }
    
    func likeUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard users.indices.contains(currentUserIndex) else { return }
        
        let likedUserId = users[currentUserIndex].id
        
        let ref = Database.database().reference()
        
        // A likes B
        ref.child("likes")
            .child(currentUserId)
            .child(likedUserId)
            .setValue(true)
        
        // check if B liked A
        checkMatch(likedUserId: likedUserId)
    }
    
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
        
        showMatch()
    }
    
    func showMatch() {
        DispatchQueue.main.async {
            showMatchText = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showMatchText = false
            }
        }
    }
    
    func nextUser() {
        liked = false
        currentImageIndex = 0
        
        if currentUserIndex < users.count - 1 {
            currentUserIndex += 1
        } else {
            currentUserIndex = 0
        }
    }
}
