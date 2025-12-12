import SwiftUI
import UIKit

struct ConfettiEmitter: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Add CAEmitterLayer if not present
        if uiView.layer.sublayers?.first(where: { $0.name == "confetti" }) == nil {
            let emitter = CAEmitterLayer()
            emitter.name = "confetti"
            emitter.emitterPosition = CGPoint(x: uiView.bounds.midX, y: -10)
            emitter.emitterShape = .line
            emitter.emitterSize = CGSize(width: uiView.bounds.size.width, height: 1)

            let colors: [UIColor] = [.systemPink, .systemPurple, .systemYellow, .systemTeal, .systemOrange]
            var cells: [CAEmitterCell] = []
            for color in colors {
                let cell = CAEmitterCell()
                cell.birthRate = 6
                cell.lifetime = 4.0
                cell.lifetimeRange = 0.5
                cell.velocity = 200
                cell.velocityRange = 50
                cell.emissionLongitude = .pi
                cell.emissionRange = .pi/4
                cell.spin = 3
                cell.spinRange = 4
                cell.scale = 0.07
                cell.scaleRange = 0.02
                cell.color = color.cgColor
                cell.contents = UIImage(systemName: "heart.fill")?.cgImage
                cells.append(cell)
            }
            emitter.emitterCells = cells
            emitter.beginTime = CACurrentMediaTime()
            uiView.layer.addSublayer(emitter)

            // remove after 1.6s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                emitter.birthRate = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    emitter.removeFromSuperlayer()
                }
            }
        }
    }
}