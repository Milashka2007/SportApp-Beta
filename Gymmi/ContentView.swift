//
//  ContentView.swift
//  Gymmi
//
//  Created by Ivan Kirsanov on 30.03.2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
        MainTabView()
                    .environmentObject(authService)
                    .onAppear {
                        print("📱 Отображение MainTabView")
                    }
            } else {
                LoginView()
                    .environmentObject(authService)
                    .onAppear {
                        print("📱 Отображение LoginView")
                    }
            }
        }
        .onAppear {
            print("👤 Текущий пользователь: \(String(describing: authService.currentUser))")
            print("🔑 Состояние аутентификации: \(authService.isAuthenticated)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
