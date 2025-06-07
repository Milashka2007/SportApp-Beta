import SwiftUI
import UIKit
import AVFoundation
import PhotosUI

// Обертка для установки начального смещения ScrollView
struct ScrollViewOffsetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    if let scrollView = geometry.view?.findScrollView() {
                        scrollView.contentOffset.x = 1000
                    }
                }
            }
        )
    }
}

// Расширение для поиска ScrollView
extension UIView {
    func findScrollView() -> UIScrollView? {
        if let scrollView = self as? UIScrollView {
            return scrollView
        }
        for subview in subviews {
            if let scrollView = subview.findScrollView() {
                return scrollView
            }
        }
        return nil
    }
}

// Расширение для доступа к UIView из GeometryProxy
extension GeometryProxy {
    var view: UIView? {
        UIView.getView(from: self)
    }
}

extension UIView {
    static func getView(from proxy: GeometryProxy) -> UIView? {
        let mirror = Mirror(reflecting: proxy)
        for child in mirror.children {
            if let view = child.value as? UIView {
                return view
            }
        }
        return nil
    }
}

struct HorizontalScrollView: UIViewRepresentable {
    var content: [Date]
    var selectedDate: Date
    var monthFormatter: DateFormatter
    var onDateSelected: (Date) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDateSelected: onDateSelected)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.tag = 100
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.tag = 200
        
        // Добавляем ячейки с датами
        for date in content {
            let dateCell = DateCell(
                date: date,
                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                monthFormatter: monthFormatter
            ) {
                onDateSelected(date)
            }
            
            let hostingController = UIHostingController(rootView: dateCell)
            hostingController.view.backgroundColor = .clear
            context.coordinator.hostingControllers.append(hostingController)
            
            // Настраиваем размеры и добавляем view
            hostingController.view.frame = CGRect(x: 0, y: 0, width: 50, height: 180)
            
            // Добавляем обработчик нажатия
            let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.dateTapped(_:)))
            hostingController.view.addGestureRecognizer(tap)
            hostingController.view.tag = content.firstIndex(of: date) ?? 0
            hostingController.view.isUserInteractionEnabled = true
            
            stackView.addArrangedSubview(hostingController.view)
        }
        
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 180)
        ])
        
        // Устанавливаем начальное смещение в конец
        DispatchQueue.main.async {
            scrollView.contentOffset.x = scrollView.contentSize.width - scrollView.bounds.width
        }
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Находим stackView по тегу
        guard let stackView = uiView.viewWithTag(200) as? UIStackView else { return }
        
        // Очищаем старые контроллеры
        context.coordinator.cleanup()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Добавляем новые ячейки
        for date in content {
            let dateCell = DateCell(
                date: date,
                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                monthFormatter: monthFormatter
            ) {
                onDateSelected(date)
            }
            
            let hostingController = UIHostingController(rootView: dateCell)
            hostingController.view.backgroundColor = .clear
            context.coordinator.hostingControllers.append(hostingController)
            
            // Настраиваем размеры и добавляем view
            hostingController.view.frame = CGRect(x: 0, y: 0, width: 50, height: 180)
            
            // Добавляем обработчик нажатия
            let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.dateTapped(_:)))
            hostingController.view.addGestureRecognizer(tap)
            hostingController.view.tag = content.firstIndex(of: date) ?? 0
            hostingController.view.isUserInteractionEnabled = true
            
            stackView.addArrangedSubview(hostingController.view)
        }
    }
    
    class Coordinator: NSObject {
        var hostingControllers: [UIHostingController<DateCell>] = []
        var onDateSelected: (Date) -> Void
        
        init(onDateSelected: @escaping (Date) -> Void) {
            self.onDateSelected = onDateSelected
            super.init()
        }
        
        @objc func dateTapped(_ sender: UITapGestureRecognizer) {
            guard let view = sender.view,
                  let index = view.tag as Int?,
                  index < hostingControllers.count else { return }
            
            let hostingController = hostingControllers[index]
            onDateSelected(hostingController.rootView.date)
        }
        
        func cleanup() {
            for controller in hostingControllers {
                controller.view.removeFromSuperview()
            }
            hostingControllers.removeAll()
        }
    }
}

// Безопасный доступ к элементу массива
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct NutritionView: View {
    // Сервис аутентификации для доступа к данным пользователя
    @EnvironmentObject var authService: AuthService
    
    // Состояния для хранения значений макронутриентов
    @State private var proteins = 0
    @State private var fats = 0
    @State private var carbs = 0
    @State private var calories = 0
    
    // Выбранная дата и референс для программного скролла
    @State private var selectedDate: Date
    
    // Календарь для работы с датами
    private let calendar = Calendar.current
    
    // Массив дней недели для отображения
    private let weekDays = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
    
    // Форматтер для отображения названия месяца на русском
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    // Инициализатор с установкой текущей даты
    init() {
        let today = Date()
        _selectedDate = State(initialValue: today)
    }
    
    // Функция получения массива дат за последние 2 месяца
    private func getDatesArray() -> [Date] {
        let today = Date()
        let calendar = Calendar.current
        
        // Получаем даты за последние 2 месяца (60 дней) до сегодняшнего дня
        let dates = (0...60).compactMap { days in
            calendar.date(byAdding: .day, value: -days, to: today)
        }
        
        // Возвращаем массив в обратном порядке (от старых к новым)
        return Array(dates.reversed())
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Скролл с датами в самом верху
                    HorizontalScrollView(
                        content: getDatesArray(),
                        selectedDate: selectedDate,
                        monthFormatter: monthFormatter,
                        onDateSelected: { date in
                                selectedDate = date
                            }
                    )
                    .frame(height: 180)
                    .background(Color(.systemBackground))
                    
                    // Подписи под скроллом
                    VStack(spacing: 8) {
                        // Основные надписи
                        HStack(spacing: 0) {
                            Text("Белки")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                            
                            Text("Жиры")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                            
                            Text("Углеводы")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                            
                            Text("Калории")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                        }
                        
                        // Надписи прогресса
                        HStack(spacing: 0) {
                            Text("0 из 120")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                            
                            Text("0 из 40")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                            
                            Text("0 из 300")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                            
                            Text("0 из 2000")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 0)
                    
                    // Секция макронутриентов
                    HStack(alignment: .top, spacing: 10) {
                        // Прямоугольник слева
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(width: 100, height: 120)
                            .cornerRadius(12)
                        
                        // Макронутриенты справа
                        VStack(alignment: .leading, spacing: 15) {
                            // Б
                            HStack(spacing: 5) {
                                Text("Б")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(height: 8)
                                            .cornerRadius(4)
                                        
                                        Rectangle()
                                            .fill(Color(.systemGray4))
                                            .frame(width: geometry.size.width * 0, height: 8)
                                            .cornerRadius(4)
                    }
                }
                                .frame(height: 8)
                            }
                            
                            // Ж
                            HStack(spacing: 5) {
                                Text("Ж")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(height: 8)
                                            .cornerRadius(4)
                                        
                                        Rectangle()
                                            .fill(Color(.systemGray4))
                                            .frame(width: geometry.size.width * 0, height: 8)
                                            .cornerRadius(4)
                                    }
                                }
                                .frame(height: 8)
                            }
                            
                            // У
                            HStack(spacing: 5) {
                                Text("У")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(height: 8)
                                            .cornerRadius(4)
                                        
                                        Rectangle()
                                            .fill(Color(.systemGray4))
                                            .frame(width: geometry.size.width * 0, height: 8)
                                            .cornerRadius(4)
                                    }
                                }
                                .frame(height: 8)
                            }
                            
                            // К
                            HStack(spacing: 5) {
                                Text("К")
                            .font(.headline)
                            .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(height: 8)
                                            .cornerRadius(4)
                                        
                                        Rectangle()
                                            .fill(Color(.systemGray4))
                                            .frame(width: geometry.size.width * 0, height: 8)
                                            .cornerRadius(4)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                        .frame(height: 120)
                        
                        Spacer()
                }
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                    // Кнопки приёмов пищи
                    VStack(spacing: 20) {
                        MealButton(title: "Завтрак", systemImage: "sunrise.fill")
                        MealButton(title: "Обед", systemImage: "sun.max.fill")
                        MealButton(title: "Ужин", systemImage: "moon.stars.fill")
            }
            .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// Компонент ячейки даты
struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let monthFormatter: DateFormatter
    let action: () -> Void
    
    private let calendar = Calendar.current
    private let weekDays = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
    
    // Проверка, является ли дата первым днем месяца
    private var isFirstDayOfMonth: Bool {
        calendar.component(.day, from: date) == 1
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Отображение названия месяца для первого дня
                    if isFirstDayOfMonth {
                        Text(monthFormatter.string(from: date).capitalized)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 5)
                        .frame(height: 20)
                        .background(Color.clear)
                        .zIndex(1)
                } else {
                    Spacer()
                        .frame(height: 20)
                }
                
                // Отображение дня недели и числа
                VStack(spacing: 2) {
                    Text(weekDays[calendar.component(.weekday, from: date) - 1])
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? .white : .primary)
                        .fixedSize()
                    
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                        .fixedSize()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.black : Color.clear)
                        .shadow(color: isSelected ? Color.black.opacity(0.1) : .clear, radius: 2, x: 0, y: 1)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
            }
            .frame(height: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Компонент карточки макронутриента
struct MacroCard: View {
    let title: String
    let value: Int
    let color: Color
    let systemImageName: String
    let action: () -> Void
    
    var body: some View {
        VStack {
            // Верхняя часть карточки с иконкой и кнопкой добавления
            HStack {
                Image(systemName: systemImageName)
                    .foregroundColor(color)
                
                Spacer()
                
                Button(action: action) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color)
                }
            }
            
            // Название макронутриента
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            // Значение в граммах
            HStack {
                Text("\(value)г")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActionButton: View {
    let systemImage: String
    let action: () -> Void
    let angle: Double
    let isVisible: Bool
    let radius: CGFloat
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? cos(angle * .pi / 180) * radius : 0,
                y: isVisible ? sin(angle * .pi / 180) * radius : 0)
        .scaleEffect(isVisible ? 1 : 0.5)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isVisible)
        .zIndex(1)
    }
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)
                
                // Поле ввода в центре экрана
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                HStack {
                                    if message.isUser {
                                        Spacer()
                                    }
                                    
                                    Text(message.text)
                                        .padding(10)
                                        .background(message.isUser ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(message.isUser ? .white : .primary)
                                        .cornerRadius(12)
                                    
                                    if !message.isUser {
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                .frame(width: UIScreen.main.bounds.width * 0.9, height: 140)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 5)
                .overlay(
                    ZStack(alignment: .topLeading) {
                        if messageText.isEmpty {
                            Text("Опишите ваше блюдо")
                                .foregroundColor(Color(.systemGray3))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .font(.body)
                        }
                        
                        TextEditor(text: $messageText)
                            .padding(8)
                            .focused($isTextFieldFocused)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .font(.body)
                    }
                )
                .onTapGesture {
                    isTextFieldFocused = true
                }
                
                Spacer()
            }
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                },
                trailing: Button("Готово") {
                    if !messageText.isEmpty {
                        messages.append(Message(text: messageText, isUser: true))
                        messageText = ""
                    }
                    dismiss()
                }
                .foregroundColor(.blue)
            )
            .navigationTitle("Опишите блюдо")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        camera.preview = previewLayer
        
        // Запускаем камеру в фоновом потоке
        DispatchQueue.global(qos: .userInitiated).async {
            camera.session.startRunning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Обновляем размер превью при изменении размера view
        DispatchQueue.main.async {
            camera.preview?.frame = uiView.frame
        }
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer?
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] status in
                if status {
                    DispatchQueue.main.async {
                        self?.setUp()
                    }
                }
            }
        case .denied:
            DispatchQueue.main.async {
                self.alert = true
            }
            return
        default:
            return
        }
    }
    
    func setUp() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                self.session.beginConfiguration()
                
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    print("Не удалось получить доступ к камере")
                    return
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
                
                if self.session.canAddOutput(self.output) {
                    self.session.addOutput(self.output)
                }
                
                self.session.commitConfiguration()
            } catch {
                print("Ошибка настройки камеры: \(error.localizedDescription)")
            }
        }
    }
    
    func takePicture() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Ошибка при съемке фото: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Не удалось создать изображение из данных фото")
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        DispatchQueue.main.async { [weak self] in
            self?.isTaken = true
        }
    }
    
    func switchCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Удаляем текущий input
            guard let currentInput = self.session.inputs.first as? AVCaptureDeviceInput else {
                print("Не удалось получить текущий input камеры")
                return
            }
            self.session.removeInput(currentInput)
            
            // Определяем новую позицию камеры
            let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
            
            // Получаем новое устройство
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
                print("Не удалось получить новое устройство камеры")
                return
            }
            
            // Создаем новый input
            guard let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
                print("Не удалось создать новый input камеры")
                return
            }
            
            // Добавляем новый input
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
            }
            
            self.session.commitConfiguration()
        }
    }
}

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraModel()
    @State private var showPhotoLibrary = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Предпросмотр камеры
                CameraPreview(camera: camera)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    HStack(spacing: 60) {
                        // Кнопка галереи
                        Button(action: {
                            showPhotoLibrary = true
                        }) {
                            Image(systemName: "photo.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        // Кнопка съемки
                        Button(action: {
                            camera.takePicture()
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 80, height: 80)
                                )
                        }
                        
                        // Кнопка переключения камеры
                        Button(action: {
                            camera.switchCamera()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            )
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoPicker(selectedImage: $selectedImage)
            }
            .onAppear {
                camera.checkPermissions()
            }
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

struct MealButton: View {
    let title: String
    let systemImage: String
    @State private var showActions = false
    @State private var showAddMeal = false
    @State private var showCamera = false
    
    var body: some View {
        ZStack {
            // Основная кнопка приёма пищи
            HStack(spacing: 15) {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                Text(title)
                    .font(.title3)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Контейнер для плюса и экшн-кнопок
                ZStack {
                    // Экшн-кнопки
                    ActionButton(systemImage: "camera.fill", action: {
                        showCamera = true
                        showActions = false
                    }, angle: 90, isVisible: showActions, radius: 35)
                    
                    ActionButton(systemImage: "text.bubble.fill", action: {
                        showAddMeal = true
                        showActions = false
                    }, angle: 180, isVisible: showActions, radius: 35)
                    
                    ActionButton(systemImage: "book.fill", action: {}, angle: 270, isVisible: showActions, radius: 35)
                    
                    // Кнопка плюса
                    Button(action: {
                        withAnimation {
                            showActions.toggle()
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(showActions ? 45 : 0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showActions)
                    }
                }
                .frame(width: 50, height: 50)
            }
            .padding(.vertical, 20)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .center)
        .padding(.vertical, 4)
        .fullScreenCover(isPresented: $showAddMeal) {
            AddMealView()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
    }
}

#Preview {
    NutritionView()
        .environmentObject(AuthService())
} 