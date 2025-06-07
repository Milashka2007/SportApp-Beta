import SwiftUI

enum TabSelection: Int {
    case workouts = 0
    case nutrition = 1
    case settings = 2
    case social = 3
}

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab: TabSelection = .nutrition
    @State private var showComingSoon = false
    @State private var previousTab: TabSelection = .nutrition
    
    var body: some View {
            TabView(selection: $selectedTab) {
                WorkoutsView()
                    .tabItem {
                    Image(systemName: selectedTab == .workouts ? "dumbbell.fill" : "dumbbell")
                    }
                .tag(TabSelection.workouts)
                
                NutritionView()
                    .tabItem {
                    Image(systemName: selectedTab == .nutrition ? "leaf.fill" : "leaf")
                    }
                .tag(TabSelection.nutrition)
                
                SettingsView()
                    .tabItem {
                    Image(systemName: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                    }
                .tag(TabSelection.settings)
                    
            Color.clear
                    .tabItem {
                        Image(systemName: "person.3")
                    }
                .tag(TabSelection.social)
            }
            .tint(.blue)
        .overlay(alignment: .bottom) {
            if showComingSoon {
                        Text("Скоро")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.blue)
                            .cornerRadius(6)
                    .offset(y: -70)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
        .onAppear {
            print("📱 MainTabView появился")
            selectedTab = .nutrition
            previousTab = .nutrition
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            print("🔄 Смена вкладки: \(oldValue) -> \(newValue)")
            if newValue == .social {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showComingSoon = true
                }
                selectedTab = previousTab
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showComingSoon = false
                    }
                }
            } else {
                previousTab = newValue
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
} 
