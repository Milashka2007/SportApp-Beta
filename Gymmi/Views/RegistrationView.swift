import SwiftUI
import Foundation

struct RegistrationView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Профиль пользователя
    @State private var gender: Gender?
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var goal: Goal?
    @State private var targetWeight: String = ""
    @State private var diet: Diet?
    @State private var experience: Experience?
    @State private var workoutFrequency: WorkoutFrequency?
    
    @State private var currentStep = 1
    @State private var showTargetWeightField = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Регистрация")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if currentStep == 1 {
                    basicInfoStep
                } else if currentStep == 2 {
                    fitnessProfileStep
                }
                
                HStack(spacing: 20) {
                    if currentStep > 1 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Назад")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    if currentStep < 2 {
                        Button(action: {
                            withAnimation {
                                currentStep += 1
                            }
                        }) {
                            Text("Далее")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            let profile = UserProfile(
                                gender: gender,
                                height: Double(height),
                                weight: Double(weight),
                                goal: goal,
                                targetWeight: Double(targetWeight),
                                diet: diet,
                                experience: experience,
                                workoutFrequency: workoutFrequency
                            )
                            authService.register(email: email, password: password, profile: profile) { success in
                                if success {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }) {
                            Text("Зарегистрироваться")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "arrow.left")
                .foregroundColor(.blue)
        })
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var basicInfoStep: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)
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
    }
    
    private var fitnessProfileStep: some View {
        VStack(spacing: 20) {
            Picker("Пол", selection: $gender) {
                Text("Выберите пол").tag(nil as Gender?)
                ForEach([Gender.male, Gender.female], id: \.self) { gender in
                    Text(gender.rawValue).tag(gender as Gender?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            TextField("Рост (см)", text: $height)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            
            TextField("Вес (кг)", text: $weight)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            
            Picker("Цель", selection: $goal) {
                Text("Выберите цель").tag(nil as Goal?)
                ForEach([Goal.loseWeight, Goal.gainMuscle, Goal.getEnergy], id: \.self) { goal in
                    Text(goal.rawValue).tag(goal as Goal?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: goal) { oldValue, newValue in
                showTargetWeightField = newValue == .loseWeight || newValue == .gainMuscle
            }
            
            if showTargetWeightField {
                TextField("Целевой вес (кг)", text: $targetWeight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
            }
            
            Picker("Диета", selection: $diet) {
                Text("Выберите диету").tag(nil as Diet?)
                ForEach([Diet.noDiet, Diet.vegan, Diet.vegetarian], id: \.self) { diet in
                    Text(diet.rawValue).tag(diet as Diet?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            Picker("Опыт тренировок", selection: $experience) {
                Text("Выберите опыт").tag(nil as Experience?)
                ForEach([Experience.noExperience, Experience.lessThanYear, Experience.oneToThree, Experience.moreThanThree], id: \.self) { experience in
                    Text(experience.rawValue).tag(experience as Experience?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            Picker("Тренировки в неделю", selection: $workoutFrequency) {
                Text("Выберите частоту").tag(nil as WorkoutFrequency?)
                ForEach([WorkoutFrequency.oneToTwo, WorkoutFrequency.threeToFour, WorkoutFrequency.fourToFive, WorkoutFrequency.sixToSeven], id: \.self) { frequency in
                    Text(frequency.rawValue).tag(frequency as WorkoutFrequency?)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
            .environmentObject(AuthService())
    }
} 