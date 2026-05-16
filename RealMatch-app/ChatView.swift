//
//  ChatView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
//

import SwiftUI

struct ChatView: View {
    let match: MatchModel

    var body: some View {
        VStack {
            Text("Chatta med \(match.name)")
                .font(.title2)
                .padding()

            Spacer()

            Text("Här kommer chatten senare 💬")
                .foregroundColor(.gray)

            Spacer()
        }
        .navigationTitle(match.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
