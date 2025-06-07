//
//  GymmiApp.swift
//  Gymmi
//
//  Created by Ivan Kirsanov on 30.03.2025.
//

import SwiftUI

@main
struct GymmiApp: App {
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if authService.isAuthenticated {
                        ContentView()
                            .environmentObject(authService)
                            .onAppear {
                                print("📱 Отображение ContentView")
                                if let currentUser = authService.currentUser {
                                    print("👤 Текущий пользователь: \(String(describing: currentUser))")
                                } else {
                                    print("👤 Пользователь не загружен")
                                }
                            }
                    } else {
                        LoginView()
                            .environmentObject(authService)
                            .onAppear {
                                print("📱 Отображение LoginView")
                                if let currentUser = authService.currentUser {
                                    print("👤 Текущий пользователь: \(String(describing: currentUser))")
                                } else {
                                    print("👤 Пользователь не авторизован")
                                }
                            }
                    }
                }
                .onAppear {
                    print("🔑 Состояние аутентификации: \(authService.isAuthenticated)")
                    if let currentUser = authService.currentUser {
                        print("👤 Текущий пользователь: \(String(describing: currentUser))")
                    } else {
                        print("👤 Пользователь не авторизован")
                    }
                }
                .onChange(of: authService.isAuthenticated) { oldValue, newValue in
                    print("🔄 Изменение состояния аутентификации: \(oldValue) -> \(newValue)")
                    if let currentUser = authService.currentUser {
                        print("👤 Текущий пользователь: \(String(describing: currentUser))")
                    } else {
                        print("👤 Пользователь не авторизован")
                    }
                }
            }
        }
    }
}
