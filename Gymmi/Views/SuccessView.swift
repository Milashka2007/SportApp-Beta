import SwiftUI

struct SuccessView: View {
    let message: String
    @EnvironmentObject var authService: AuthService
    @State private var showMainView = false
    
    var body: some View {
        Group {
            if showMainView {
                MainTabView()
                    .navigationBarBackButtonHidden(true)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text(message)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .navigationBarBackButtonHidden(true)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showMainView = true
                        }
                    }
                }
            }
        }
    }
} 