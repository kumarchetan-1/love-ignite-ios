import Foundation
import FirebaseAI
import FirebaseAILogic

class AITaskService {
    static let shared = AITaskService()
    
    private var model: GenerativeModel?
    
    private init() {
        // Correct initialization for the latest Firebase AI Logic SDK
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        self.model = ai.generativeModel(modelName: "gemini-1.5-flash")
    }
    
    func generateDailyTasks(hideExplicit: Bool) async -> [Challenge] {
        guard let model = model else {
            return []
        }
        
        let prompt = """
        Act as a relationship expert and creative romantic coach. 
        Create 5 unique, innovative, and short romantic tasks for a couple to do today. 
        Focus on deepening connection, playfulness, and intimacy.
        
        Tone: \(hideExplicit ? "Sweet, romantic, and playful (PG-rated)" : "Passionate, intimate, and spicy (Adult-rated)")
        
        Requirements:
        1. Keep each task under 15 words.
        2. Format: Return ONLY the tasks, each on a new line.
        3. No numbers, no introduction, no emojis.
        """
        
        do {
            let response = try await model.generateContent(prompt)
            guard let text = response.text else { return [] }
            
            let taskTitles = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(5)
            
            return taskTitles.enumerated().map { index, title in
                Challenge(
                    id: "ai_task_\(index)_\(Int(Date().timeIntervalSince1970))",
                    number: 0,
                    title: title,
                    category: .general,
                    difficulty: .medium,
                    hint: "Daily AI Spark",
                    imageName: nil,
                    isLocked: false
                )
            }
        } catch {
            return []
        }
    }
}
