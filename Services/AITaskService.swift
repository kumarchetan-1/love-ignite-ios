import Foundation
import FirebaseAI
import FirebaseAILogic

class AITaskService {
    static let shared = AITaskService()
    
    private var model: GenerativeModel?
    
    private init() {
        // Correct initialization for the latest Firebase AI Logic SDK
        // Updated from gemini-1.5-flash (retired Sep 24, 2025) to gemini-2.0-flash-exp
        // Alternative models if this doesn't work:
        // - gemini-2.5-flash (recommended stable replacement)
        // - gemini-2.5-flash-lite (lighter version)
        // - gemini-1.5-pro (if still available)
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        self.model = ai.generativeModel(modelName: "gemini-2.0-flash-exp")
    }
    
    func generateDailyTasks() async -> [Challenge] {
        guard let model = model else {
            return []
        }
        
        let prompt = """
        Act as a warm, practical relationship coach for modern couples.
        Create 5 unique, short activities for a couple to do today that help with
        communication, shared expectations, healthy conflict, texting habits, date ideas or quick check-ins.

        Tone: Kind, playful and family-friendly (PG). Keep every activity wholesome and suitable for couples of any age.
        
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
