import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
        VStack {
            Text("Тренировки")
                    .font(.title)
                .padding()
            
            Text("Здесь будут ваши тренировки")
                .foregroundColor(.gray)
            }
            .navigationTitle("Тренировки")
        }
        .onAppear {
            print("📱 Отображение WorkoutsView")
        }
    }
}

#Preview {
    WorkoutsView()
        .environmentObject(AuthService())
} 