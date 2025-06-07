import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var isPasswordVisible = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(isRegistering ? "Регистрация" : "Вход")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                    
                    TextField("Введите email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    if let error = authService.validationErrors["email"] {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Пароль")
                        .font(.headline)
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Введите пароль", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Введите пароль", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.password)
                                .onChange(of: password) { oldValue, newValue in
                                    // Оставляем только английские буквы, цифры и специальные символы
                                    let filtered = newValue.filter { char in
                                        let allowedChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
                                        return String(char).rangeOfCharacter(from: allowedChars) != nil
                                    }
                                    if filtered != newValue {
                                        password = filtered
                                    }
                                }
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let error = authService.validationErrors["password"] {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    if isRegistering {
                        let userProfile = UserProfile(gender: nil, height: nil, weight: nil, goal: nil, targetWeight: nil, diet: nil, experience: nil, workoutFrequency: nil)
                        authService.register(email: email, password: password, profile: userProfile) { success in
                            if success {
                                successMessage = "Регистрация успешна!"
                                showSuccess = true
                            }
                        }
                    } else {
                        authService.login(email: email, password: password) { success in
                            if success {
                                successMessage = "Вход выполнен успешно!"
                                showSuccess = true
                            }
                        }
                    }
                }) {
                    Text(isRegistering ? "Зарегистрироваться" : "Войти")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(authService.isLoading)
                
                Button(action: {
                    isRegistering.toggle()
                    authService.validationErrors.removeAll()
                }) {
                    Text(isRegistering ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                        .foregroundColor(.blue)
                }
                
                if authService.isLoading {
                    ProgressView()
                }
            }
            .padding()
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showSuccess) {
                SuccessView(message: successMessage)
                    .environmentObject(authService)
            }
            .ignoresSafeArea(.keyboard)
        }
    }
} 