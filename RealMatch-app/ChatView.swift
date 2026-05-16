//
//  ChatView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase

// MARK: - MODEL
struct ChatMessage: Identifiable {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Double
}

// MARK: - VIEW
struct ChatView: View {
    
    let match: MatchModel
    
    @State private var messages: [ChatMessage] = []
    @State private var messageText: String = ""
    
    var chatId: String {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        let ids = [currentUserId, match.userId].sorted()
        return ids.joined()
    }
    
    var body: some View {
        VStack {
            
            // MESSAGES
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        
                        ForEach(messages) { msg in
                            HStack {
                                
                                if msg.senderId == Auth.auth().currentUser?.uid {
                                    Spacer()
                                    
                                    Text(msg.text)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                        .frame(maxWidth: 250, alignment: .trailing)
                                    
                                } else {
                                    
                                    Text(msg.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(15)
                                        .frame(maxWidth: 250, alignment: .leading)
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                            .id(msg.id)
                        }
                    }
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // INPUT
            HStack {
                
                TextField("Skriv ett meddelande...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button {
                    sendMessage()
                } label: {
                    Text("Skicka")
                        .bold()
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle(match.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            listenMessages()
        }
    }
    
    // MARK: - SEND MESSAGE
    func sendMessage() {
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let ref = Database.database().reference()
        let messageRef = ref.child("chats").child(chatId).child("messages").childByAutoId()
        
        let data: [String: Any] = [
            "senderId": currentUserId,
            "text": messageText,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        messageRef.setValue(data)
        
        messageText = ""
    }
    
    // MARK: - LISTEN MESSAGES
    func listenMessages() {
        
        let ref = Database.database().reference()
        
        ref.child("chats").child(chatId).child("messages")
            .observe(.value) { snapshot in
                
                var temp: [ChatMessage] = []
                
                for child in snapshot.children {
                    
                    if let snap = child as? DataSnapshot,
                       let data = snap.value as? [String: Any],
                       let senderId = data["senderId"] as? String,
                       let text = data["text"] as? String,
                       let timestamp = data["timestamp"] as? Double {
                        
                        temp.append(ChatMessage(
                            id: snap.key,
                            senderId: senderId,
                            text: text,
                            timestamp: timestamp
                        ))
                    }
                }
                
                temp.sort { $0.timestamp < $1.timestamp }
                
                DispatchQueue.main.async {
                    self.messages = temp
                }
            }
    }
}
