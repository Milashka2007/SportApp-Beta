import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack {
            Text("Настройки")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
            
            if let user = authService.currentUser {
                VStack(spacing: 20) {
                    Text("Профиль")
                        .font(.headline)
                    
                    Text("Email: \(user.email)")
                        .font(.body)
                    
                    if let name = user.name {
                        Text("Имя: \(name)")
                            .font(.body)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {
                authService.logout()
            }) {
                Text("Выйти")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
} 