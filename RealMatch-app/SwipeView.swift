//
//  SwipeView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SwipeView: View {
    
    @State private var users: [[String]] = []   // varje user = 4 bilder
    @State private var currentUserIndex = 0
    @State private var currentImageIndex = 0
    
    @State private var liked = false
    
    var body: some View {
        
        VStack {
            
            Spacer()
            
            if users.isEmpty {
                Text("Inga användare")
            } else {
                
                let images = users[currentUserIndex]
                
                ZStack {
                    
                    // 🖼️ KARUSELL (4 bilder per user)
                    TabView(selection: $currentImageIndex) {
                        
                        ForEach(images.indices, id: \.self) { index in
                            
                            AsyncImage(url: URL(string: images[index])) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
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
                            .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                    )
                    
                    // ❤️ HJÄRTA (overlay alltid synlig)
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Button {
                                toggleLike()
                            } label: {
                                Image(systemName: liked ? "heart.fill" : "heart")
                                    .font(.system(size: 26))
                                    .foregroundColor(liked ? .red : .gray)
                                    .padding(14)
                                    .background(Color.white)
                                    .overlay(
                                        Circle().stroke(Color.gray.opacity(0.6), lineWidth: 2)
                                    )
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .padding(.trailing, 30)
                            .padding(.bottom, 20)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            fetchUsers()
        }
    }
    
    // MARK: - Toggle like
    func toggleLike() {
        liked.toggle()
        
        if liked {
            likeUser()
        }
    }
    
    // MARK: - Fetch users (4 images per user)
    func fetchUsers() {
        
        let db = Firestore.firestore()
        
        db.collection("users").getDocuments { snapshot, error in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let docs = snapshot?.documents else { return }
            
            var allUsers: [[String]] = []
            
            for doc in docs {
                if let images = doc.data()["images"] as? [String],
                   images.count > 0 {
                    
                    allUsers.append(images)
                }
            }
            
            self.users = allUsers
        }
    }
    
    // MARK: - Like save
    func likeUser() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        db.collection("likes").addDocument(data: [
            "from": userId,
            "timestamp": Timestamp()
        ])
    }
}
