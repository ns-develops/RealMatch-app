//
//  LoginView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    
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
                    errorMessage = error.localizedDescription
                    return
                }
                
                print("Inloggad")
            }
            
        } else {
            
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                print("Konto skapat")
            }
        }
    }
}
