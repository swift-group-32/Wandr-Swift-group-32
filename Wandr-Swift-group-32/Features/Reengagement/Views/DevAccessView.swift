//
//  DevAccessView.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 26/11/26.
//

import SwiftUI

struct DeveloperAccessView: View {

    @State private var codigo = ""
    @State private var mostrarError = false
    @State private var accesoConcedido = false

    var body: some View {
        VStack(spacing: 24) {

            Image(systemName: "briefcase.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.wandrGreen)

            Text("Developer Access")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter the developer code to access re-engagement insights.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            SecureField("Developer code", text: $codigo)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            if mostrarError {
                Text("Invalid developer code.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Continue") {
                if codigo == "123" {
                    mostrarError = false
                    accesoConcedido = true
                } else {
                    mostrarError = true
                    accesoConcedido = false
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.wandrGreen)

            NavigationLink(
                destination: DeveloperDashboardView(),
                isActive: $accesoConcedido
            ) {
                EmptyView()
            }
            .hidden()
        }
        .padding()
        .navigationTitle("Developer Access")
    }
}

#Preview {
    NavigationStack {
        DeveloperAccessView()
    }
}
