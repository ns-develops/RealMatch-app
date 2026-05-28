//
//  LoginView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import Combine

struct LoginView: View {
    
    @Binding var isLoggedIn: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    
    @State private var birthDate = Date()
    
    @State private var isLogin = true
    @State private var errorMessage = ""
    
    // Bakgrundsbilder
    @State private var currentImage = 0
    
    let images = ["item", "item2", "item3"]
    
    let timer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()
    
    var body: some View {
        
        ZStack {
            
            // BAKGRUNDSBILD
            Image(images[currentImage])
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentImage)
                .onReceive(timer) { _ in
                    currentImage = (currentImage + 1) % images.count
                }
            
            // Mörk overlay
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            // LOGIN UI
            VStack(spacing: 16) {
                
                Text(isLogin ? "Logga In" : "Skapa Konto")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: 320)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(14)
                
                SecureField("Lösenord", text: $password)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: 320)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(14)
                
                // Endast vid registrering
                if !isLogin {
                    
                    TextField("Namn", text: $name)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: 320)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(14)
                    
                    DatePicker(
                        "Födelsedatum",
                        selection: $birthDate,
                        displayedComponents: .date
                    )
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: 320)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(14)
                }
                
                Button {
                    handleAuth()
                } label: {
                    Text(isLogin ? "Logga In" : "Registrera")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(width: 320)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                
                Button {
                    isLogin.toggle()
                } label: {
                    Text(isLogin ?
                         "Har du inget konto? Registrera" :
                         "Har du redan konto? Logga in")
                        .foregroundColor(.white)
                        .font(.footnote)
                }
                
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            .padding(.horizontal, 24)
        }
    }
    
    func handleAuth() {
        
        if isLogin {
            
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                
                if let error = error {
                    print("LOGIN ERROR:", error.localizedDescription)
                    errorMessage = error.localizedDescription
                    return
                }
                
                print("LOGIN SUCCESS")
                isLoggedIn = true
            }
            
        } else {
            
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                
                if let error = error {
                    print("CREATE USER ERROR:", error.localizedDescription)
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let user = result?.user else { return }
                
                let ref = Database.database().reference()
                
                let timestamp = birthDate.timeIntervalSince1970
                
                ref.child("users")
                    .child(user.uid)
                    .setValue([
                        "email": email,
                        "name": name,
                        "birthDate": timestamp
                    ]) { error, _ in
                        
                        if let error = error {
                            print("DATABASE ERROR:", error.localizedDescription)
                        } else {
                            print("SAVED USER WITH TIMESTAMP BIRTHDATE")
                        }
                    }
                
                isLoggedIn = true
            }
        }
    }
}
