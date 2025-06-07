import Foundation

enum Gender: String, Codable {
    case male = "MALE"
    case female = "FEMALE"
}

enum Goal: String, Codable {
    case loseWeight = "LOSE_WEIGHT"
    case gainMuscle = "GAIN_MUSCLE"
    case getEnergy = "GET_ENERGY"
}

enum Diet: String, Codable {
    case noDiet = "NO_DIET"
    case vegan = "VEGAN"
    case vegetarian = "VEGETARIAN"
}

enum Experience: String, Codable {
    case noExperience = "NO_EXPERIENCE"
    case lessThanYear = "LESS_THAN_YEAR"
    case oneToThree = "ONE_TO_THREE"
    case moreThanThree = "MORE_THAN_THREE"
}

enum WorkoutFrequency: String, Codable {
    case oneToTwo = "ONE_TO_TWO"
    case threeToFour = "THREE_TO_FOUR"
    case fourToFive = "FOUR_TO_FIVE"
    case sixToSeven = "SIX_TO_SEVEN"
}

struct UserProfile: Codable {
    var gender: Gender?
    var height: Double?
    var weight: Double?
    var goal: Goal?
    var targetWeight: Double?
    var diet: Diet?
    var experience: Experience?
    var workoutFrequency: WorkoutFrequency?
}

// Расширения для локализованного отображения
extension Gender {
    var localizedString: String {
        switch self {
        case .male: return "Мужской"
        case .female: return "Женский"
        }
    }
}

extension Goal {
    var localizedString: String {
        switch self {
        case .loseWeight: return "Похудеть"
        case .gainMuscle: return "Набрать мышечную массу"
        case .getEnergy: return "Зарядиться энергией"
        }
    }
}

extension Diet {
    var localizedString: String {
        switch self {
        case .noDiet: return "Без диеты"
        case .vegan: return "Веганская"
        case .vegetarian: return "Вегетарианская"
        }
    }
}

extension Experience {
    var localizedString: String {
        switch self {
        case .noExperience: return "Нету"
        case .lessThanYear: return "Меньше года"
        case .oneToThree: return "1-3 года"
        case .moreThanThree: return "Более 3 лет"
        }
    }
}

extension WorkoutFrequency {
    var localizedString: String {
        switch self {
        case .oneToTwo: return "1-2 раза в неделю"
        case .threeToFour: return "3-4 раза в неделю"
        case .fourToFive: return "4-5 раз в неделю"
        case .sixToSeven: return "6-7 раз в неделю"
        }
    }
} 