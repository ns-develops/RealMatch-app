//
//  LikesView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
//
import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct MatchModel: Identifiable {
    let id: String
    let userId: String
    let name: String
    let image: String
}

struct LikesView: View {
    
    @State private var matches: [MatchModel] = []
    
    var body: some View {
        NavigationView {
            
            VStack {
                
                if matches.isEmpty {
                    
                    Text("Inga likes ännu 💔")
                        .foregroundColor(.gray)
                        .padding()
                    
                } else {
                    
                    List(matches) { match in
                        
                        NavigationLink(destination: ChatView(match: match)) {
                            
                            HStack(spacing: 15) {
                                
                                AsyncImage(url: URL(string: match.image)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(match.name)
                                        .font(.headline)
                                    
                                    Text("Ny match ❤️")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Matches")
            .onAppear {
                fetchMatches()
            }
        }
    }
    
    // MARK: - FETCH MATCHES
    func fetchMatches() {
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference()
        
        ref.child("matches").observeSingleEvent(of: .value) { snapshot in
            
            var loadedMatches: [MatchModel] = []
            
            for child in snapshot.children {
                
                guard let snap = child as? DataSnapshot,
                      let data = snap.value as? [String: Any],
                      let users = data["users"] as? [String] else {
                    continue
                }
                
                if users.contains(currentUserId) {
                    
                    let otherUserId = users.first { $0 != currentUserId } ?? ""
                    
                    fetchUser(userId: otherUserId) { name, image in
                        
                        let match = MatchModel(
                            id: snap.key,
                            userId: otherUserId,
                            name: name,
                            image: image
                        )
                        
                        DispatchQueue.main.async {
                            loadedMatches.append(match)
                            self.matches = loadedMatches
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - FETCH USER
    func fetchUser(userId: String, completion: @escaping (String, String) -> Void) {
        
        let ref = Database.database().reference()
        
        ref.child("users")
            .child(userId)
            .observeSingleEvent(of: .value) { snapshot in
                
                guard let data = snapshot.value as? [String: Any] else {
                    completion("Okänd", "")
                    return
                }
                
                let name = data["name"] as? String ?? "Okänd"
                let images = data["images"] as? [String] ?? []
                let firstImage = images.first ?? ""
                
                completion(name, firstImage)
            }
    }
}
