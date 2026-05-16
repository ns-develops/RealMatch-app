//
//  LoginView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
//
import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct LoginView: View {
    
    @Binding var isLoggedIn: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLogin = true
    @State private var errorMessage = ""
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            Text(isLogin ? "Logga In" : "Skapa Konto")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            SecureField("Lösenord", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            Button {
                handleAuth()
            } label: {
                Text(isLogin ? "Logga In" : "Registrera")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button {
                isLogin.toggle()
            } label: {
                Text(isLogin ?
                     "Har du inget konto? Registrera" :
                     "Har du redan konto? Logga in")
            }
            
            Text(errorMessage)
                .foregroundColor(.red)
        }
        .padding()
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
            
            print("STARTING REGISTRATION...")
            
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                
                if let error = error {
                    print("❌ CREATE USER ERROR:", error.localizedDescription)
                    errorMessage = error.localizedDescription
                    return
                }
                
                print("USER CREATED IN AUTH")
                
                guard let user = result?.user else {
                    print("NO USER RETURNED")
                    return
                }
                
                print(" WRITING TO DATABASE FOR UID:", user.uid)
                
                let ref = Database.database().reference()
                
                ref.child("users")
                    .child(user.uid)
                    .setValue([
                        "email": email
                    ]) { error, _ in
                        
                        if let error = error {
                            print(" DATABASE WRITE ERROR:", error.localizedDescription)
                        } else {
                            print(" SAVED TO REALTIME DATABASE")
                        }
                    }
                
                isLoggedIn = true
            }
        }
    }
}
