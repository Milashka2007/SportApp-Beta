import Foundation

struct GymmiUser: Codable, Identifiable {
    let id: Int
    let email: String
    var name: String?
    let isActive: Bool
    var gender: Gender?
    var height: Double?
    var weight: Double?
    var goal: Goal?
    var targetWeight: Double?
    var diet: Diet?
    var experience: Experience?
    var workoutFrequency: WorkoutFrequency?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case isActive = "is_active"
        case gender
        case height
        case weight
        case goal
        case targetWeight = "target_weight"
        case diet
        case experience
        case workoutFrequency = "workout_frequency"
    }
} 