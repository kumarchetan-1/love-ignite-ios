import UIKit
import SwiftUI

final class ScratchUIView: UIView {
    private var maskImage: UIImage?
    private var maskLayer = CALayer()
    private let lineWidth: CGFloat = 28
    private var revealedAlready = false
    var onReveal: (() -> Void)?
    private var revealThreshold: CGFloat = 0.35

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = false
        clipsToBounds = true
        backgroundColor = UIColor.clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupMaskIfNeeded()
    }

    private func setupMaskIfNeeded() {
        if maskLayer.superlayer == nil {
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            let img = renderer.image { ctx in
                UIColor.gray.setFill()
                ctx.fill(bounds)
            }
            maskImage = img
            maskLayer.contents = maskImage?.cgImage
            maskLayer.frame = bounds
            layer.mask = maskLayer
        }
    }

    private func drawLine(from p1: CGPoint, to p2: CGPoint) {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let newImg = renderer.image { ctx in
            maskImage?.draw(at: .zero)
            ctx.cgContext.setBlendMode(.clear)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineWidth(lineWidth)
            ctx.cgContext.move(to: p1)
            ctx.cgContext.addLine(to: p2)
            ctx.cgContext.strokePath()
        }
        maskImage = newImg
        maskLayer.contents = maskImage?.cgImage
        checkRevealProgressAsync()
    }

    private func checkRevealProgressAsync() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self, let data = self.maskImage?.pngData() else { return }
            if let uiImg = UIImage(data: data), let cg = uiImg.cgImage {
                let width = cg.width
                let height = cg.height
                let bytesPerPixel = 4
                let bytesPerRow = bytesPerPixel * width
                let totalBytes = height * bytesPerRow
                var pixelData = [UInt8](repeating: 0, count: totalBytes)
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let context = CGContext(data: &pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                context?.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
                var cleared = 0
                for i in stride(from: 0, to: pixelData.count, by: 4) {
                    let alpha = pixelData[i+3]
                    if alpha == 0 { cleared += 1 }
                }
                let fraction = Double(cleared) / Double(width * height)
                if fraction > Double(self.revealThreshold) && !self.revealedAlready {
                    self.revealedAlready = true
                    DispatchQueue.main.async {
                        self.onReveal?()
                    }
                }
            }
        }
    }

    private var lastPoint: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastPoint = touches.first?.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        if let lp = lastPoint {
            drawLine(from: lp, to: p)
            // Add light haptic feedback while scratching
            if Int.random(in: 0...5) == 0 { // Don't overwhelm the haptic engine
                Haptics.light()
            }
        }
        lastPoint = p
    }
}

struct ScratchUIViewRepresentable: UIViewRepresentable {
    var onReveal: () -> Void

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.clear

        // content view placeholder
        let contentView = UIView()
        contentView.backgroundColor = UIColor.systemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        container.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: container.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let scratch = ScratchUIView()
        scratch.onReveal = onReveal
        scratch.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scratch)
        NSLayoutConstraint.activate([
            scratch.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scratch.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scratch.topAnchor.constraint(equalTo: container.topAnchor),
            scratch.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}