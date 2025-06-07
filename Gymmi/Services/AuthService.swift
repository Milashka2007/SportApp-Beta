import Foundation
import SwiftUI
import Network

enum ValidationError: LocalizedError {
    case invalidEmail
    case invalidPassword(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Неверный формат email. Пожалуйста, введите корректный email-адрес"
        case .invalidPassword(let reason):
            return reason
        }
    }
}

enum AuthError: Error {
    case invalidURL
    case invalidResponse
    case invalidCredentials
    case registrationFailed
    case serverError(String)
    case unauthorized
    case unknown
}

class AuthService: NSObject, ObservableObject, URLSessionDelegate {
    @Published var currentUser: GymmiUser?
    @Published var isAuthenticated = false
    @Published var error: String?
    @Published var shouldShowLogin = false
    @Published var shouldShowRegistration = false
    @Published var showSuccessView = false
    @Published var successMessage = ""
    @Published var validationErrors: [String: String] = [:]
    @Published var isLoading = false
    
    private let baseURL = "http://192.168.1.168:8000/api/v1"
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "authToken"
    private var session: URLSession!
    private var networkMonitor: NWPathMonitor?
    
    override init() {
        super.init()
        setupSession()
        setupNetworkMonitoring()
        checkExistingToken()
    }
    
    private func checkExistingToken() {
        guard userDefaults.string(forKey: tokenKey) != nil else {
            print("🔑 Токен не найден")
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        print("🔑 Найден существующий токен")
            Task {
                do {
                    print("🔑 Проверка существующего токена...")
                // Сначала загружаем профиль
                    try await fetchUserProfile()
                // Затем устанавливаем состояние аутентификации
                await MainActor.run {
                    self.isAuthenticated = true
                }
                print("✅ Аутентификация успешна")
                } catch {
                    print("⚠️ Ошибка при проверке токена: \(error.localizedDescription)")
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.currentUser = nil
                        userDefaults.removeObject(forKey: tokenKey)
                    print("❌ Аутентификация не удалась")
                }
            }
        }
    }
    
    private func setupSession() {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 60
        sessionConfig.timeoutIntervalForResource = 60
        sessionConfig.waitsForConnectivity = true
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        sessionConfig.urlCache = nil
        sessionConfig.httpMaximumConnectionsPerHost = 1
        sessionConfig.shouldUseExtendedBackgroundIdleMode = true
        
        // Добавляем заголовки
        sessionConfig.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Connection": "keep-alive",
            "User-Agent": "Gymmi/1.0",
            "Cache-Control": "no-cache",
            "Pragma": "no-cache"
        ]
        
        // Создаем сессию с настройками
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInitiated
        
        session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: operationQueue)
    }
    
    // MARK: - URLSessionDelegate
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("🔒 Получен вызов аутентификации")
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("⚠️ Ошибка сессии: \(error.localizedDescription)")
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                print("🌐 Сетевой статус: \(path.status)")
                if path.status == .satisfied {
                    print("✅ Подключение активно")
                } else {
                    print("❌ Нет подключения")
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor?.start(queue: queue)
    }
    
    deinit {
        networkMonitor?.cancel()
        session.invalidateAndCancel()
    }
    
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        validationErrors.removeAll()
        
        Task {
            do {
                try await login(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let validationError = error as? ValidationError {
                        validationErrors["email"] = validationError.localizedDescription
                    } else if let authError = error as? AuthError {
                        switch authError {
                        case .invalidCredentials:
                            validationErrors["password"] = "Неверный email или пароль"
                        case .serverError(let message):
                            validationErrors["general"] = message
                        default:
                            validationErrors["general"] = "Произошла ошибка. Пожалуйста, попробуйте снова."
                        }
                    }
                    completion(false)
                }
            }
        }
    }
    
    private func login(email: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            print("⚠️ Неверный URL")
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("Gymmi/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        
        let loginData = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        
        print("📤 Отправка запроса авторизации:")
        print("URL: \(url)")
        print("Метод: \(request.httpMethod ?? "UNKNOWN")")
        print("Заголовки: \(request.allHTTPHeaderFields ?? [:])")
        print("Тело: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            print("📥 Получен ответ:")
            guard let httpResponse = response as? HTTPURLResponse else {
                print("⚠️ Некорректный формат ответа")
                throw AuthError.invalidResponse
            }
            
            print("Статус: \(httpResponse.statusCode)")
            print("Заголовки: \(httpResponse.allHeaderFields)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Тело ответа: \(responseString)")
            }
            
            if httpResponse.statusCode == 200 {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                userDefaults.set(tokenResponse.accessToken, forKey: tokenKey)
                try await fetchUserProfile()
                await MainActor.run {
                    self.isAuthenticated = true
                }
            } else {
                let error = try JSONDecoder().decode(AuthErrorResponse.self, from: data)
                throw AuthError.serverError(error.detail)
            }
        } catch let error as URLError {
            print("⚠️ Ошибка сети: \(error.localizedDescription)")
            if error.code == .cannotConnectToHost || error.code == .networkConnectionLost {
                throw AuthError.serverError("Не удается подключиться к серверу. Проверьте подключение к интернету.")
            }
            throw AuthError.serverError(error.localizedDescription)
        } catch {
            print("⚠️ Неизвестная ошибка: \(error)")
            throw error
        }
    }
    
    func register(email: String, password: String, profile: UserProfile, completion: @escaping (Bool) -> Void) {
        isLoading = true
        validationErrors.removeAll()
        
        Task {
            do {
                try await register(email: email, password: password, profile: profile)
                await MainActor.run {
                    isLoading = false
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let validationError = error as? ValidationError {
                        switch validationError {
                        case .invalidEmail:
                            validationErrors["email"] = validationError.localizedDescription
                        case .invalidPassword(let reason):
                            validationErrors["password"] = reason
                        }
                    } else if let authError = error as? AuthError {
                        switch authError {
                        case .serverError(let message):
                            validationErrors["general"] = message
                        default:
                            validationErrors["general"] = "Произошла ошибка. Пожалуйста, попробуйте снова."
                        }
                    }
                    completion(false)
                }
            }
        }
    }
    
    private func register(email: String, password: String, profile: UserProfile) async throws {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let userData: [String: Any] = [
            "email": email,
            "password": password,
            "gender": profile.gender?.rawValue as Any,
            "height": profile.height as Any,
            "weight": profile.weight as Any,
            "goal": profile.goal?.rawValue as Any,
            "target_weight": profile.targetWeight as Any,
            "diet": profile.diet?.rawValue as Any,
            "experience": profile.experience?.rawValue as Any,
            "workout_frequency": profile.workoutFrequency?.rawValue as Any
        ]
        
        print("📤 Отправка запроса регистрации:")
        print("URL: \(url)")
        print("Метод: \(request.httpMethod ?? "UNKNOWN")")
        print("Тело: \(String(data: try JSONSerialization.data(withJSONObject: userData), encoding: .utf8) ?? "")")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: userData)
        
        let (data, response) = try await session.data(for: request)
        
        print("📥 Получен ответ:")
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.unknown
        }
        
        print("Статус: \(httpResponse.statusCode)")
        print("Заголовки: \(httpResponse.allHeaderFields)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Тело ответа: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            let user = try JSONDecoder().decode(GymmiUser.self, from: data)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } else {
            let error = try JSONDecoder().decode(AuthErrorResponse.self, from: data)
            throw AuthError.serverError(error.detail)
        }
    }
    
    private func checkUserExists(email: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/auth/check-email?email=\(email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email)") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let result = try JSONDecoder().decode([String: Bool].self, from: data)
            return result["exists"] ?? false
        }
        
        return false
    }
    
    private func validateEmail(_ email: String) throws {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) {
            throw ValidationError.invalidEmail
        }
    }
    
    private func validatePassword(_ password: String) throws {
        // Проверка длины
        if password.count < 8 {
            throw ValidationError.invalidPassword(reason: "Минимальная длина пароля - 8 символов")
        }
        
        // Проверка на допустимые символы
        let allowedCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        if password.unicodeScalars.contains(where: { !allowedCharacterSet.contains($0) }) {
            throw ValidationError.invalidPassword(reason: "Пароль должен содержать только английские буквы, цифры и символы - _")
        }
        
        // Проверка на наличие заглавной буквы
        let uppercaseLetterRegex = ".*[A-Z]+.*"
        if !NSPredicate(format: "SELF MATCHES %@", uppercaseLetterRegex).evaluate(with: password) {
            throw ValidationError.invalidPassword(reason: "Пароль должен содержать хотя бы одну заглавную букву")
        }
        
        // Проверка на наличие цифры
        let digitRegex = ".*[0-9]+.*"
        if !NSPredicate(format: "SELF MATCHES %@", digitRegex).evaluate(with: password) {
            throw ValidationError.invalidPassword(reason: "Пароль должен содержать хотя бы одну цифру")
        }
    }
    
    func logout() {
        userDefaults.removeObject(forKey: tokenKey)
        
        // Сбрасываем состояние
        currentUser = nil
        isAuthenticated = false
        
        // Очищаем другие данные
        resetState()
    }
    
    private func fetchUserProfile() async throws {
        guard let token = userDefaults.string(forKey: tokenKey),
              let url = URL(string: "\(baseURL)/auth/me") else {
            print("⚠️ Невалидный URL или отсутствует токен")
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("📤 Запрос профиля пользователя:")
        print("URL: \(url)")
        print("Метод: GET")
        print("Заголовки: Authorization: Bearer \(token)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            print("📥 Ответ профиля:")
            guard let httpResponse = response as? HTTPURLResponse else {
                print("⚠️ Некорректный формат ответа")
                throw AuthError.invalidResponse
            }
            
            print("Статус: \(httpResponse.statusCode)")
            print("Заголовки: \(httpResponse.allHeaderFields)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Тело ответа: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    print("📦 Начинаем декодирование данных пользователя")
                    print("📄 Полученные данные: \(String(data: data, encoding: .utf8) ?? "нет данных")")
                    let decoder = JSONDecoder()
                    let user = try decoder.decode(GymmiUser.self, from: data)
                    print("✅ Успешно декодирован пользователь: \(user)")
                await MainActor.run {
                    self.currentUser = user
                    print("✅ Профиль пользователя успешно загружен")
                    }
                } catch {
                    print("⚠️ Ошибка декодирования пользователя: \(error)")
                    print("⚠️ Детали ошибки: \(String(describing: error))")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("🔑 Отсутствует ключ: \(key.stringValue)")
                            print("📍 Контекст: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("📋 Несоответствие типа: ожидается \(type)")
                            print("📍 Контекст: \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("❌ Значение не найдено для типа: \(type)")
                            print("📍 Контекст: \(context.debugDescription)")
                        default:
                            print("❓ Другая ошибка декодирования: \(decodingError)")
                        }
                    }
                    throw error
                }
            case 401:
                print("⚠️ Неавторизованный доступ")
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    userDefaults.removeObject(forKey: tokenKey)
                }
                throw AuthError.unauthorized
            case 404:
                print("⚠️ Профиль пользователя не найден")
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    userDefaults.removeObject(forKey: tokenKey)
                }
                throw AuthError.invalidResponse
            default:
                print("⚠️ Неожиданный статус ответа: \(httpResponse.statusCode)")
                throw AuthError.invalidResponse
            }
        } catch let error as URLError {
            print("⚠️ Ошибка сети: \(error.localizedDescription)")
            if error.code == .cannotConnectToHost || error.code == .networkConnectionLost {
                throw AuthError.serverError("Не удается подключиться к серверу. Проверьте подключение к интернету.")
            }
            throw AuthError.serverError(error.localizedDescription)
        } catch {
            print("⚠️ Неизвестная ошибка: \(error)")
            throw error
        }
    }
    
    func resetState() {
        showSuccessView = false
        successMessage = ""
        error = nil
        shouldShowLogin = false
        shouldShowRegistration = false
        validationErrors.removeAll()
    }
}

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

struct AuthErrorResponse: Codable {
    let detail: String
}
