import SwiftUI

struct GoogleLogo: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Blue Path
                Path { path in
                    path.move(to: CGPoint(x: 255.878, y: 133.451))
                    path.addCurve(to: CGPoint(x: 253.122, y: 106.761), control1: CGPoint(x: 255.878, y: 122.717), control2: CGPoint(x: 255.007, y: 114.884))
                    path.addLine(to: CGPoint(x: 130.55, y: 106.761))
                    path.addLine(to: CGPoint(x: 130.55, y: 155.209))
                    path.addLine(to: CGPoint(x: 202.497, y: 155.209))
                    path.addCurve(to: CGPoint(x: 175.807, y: 197.565), control1: CGPoint(x: 201.047, y: 167.249), control2: CGPoint(x: 193.214, y: 185.381))
                    path.addLine(to: CGPoint(x: 214.562, y: 227.588))
                    path.addCurve(to: CGPoint(x: 255.878, y: 133.451), control1: CGPoint(x: 239.221, y: 204.814), control2: CGPoint(x: 255.878, y: 171.306))
                }
                .fill(Color(red: 66/255, green: 133/255, blue: 244/255))

                // Green Path
                Path { path in
                    path.move(to: CGPoint(x: 130.55, y: 261.1))
                    path.addCurve(to: CGPoint(x: 216.903, y: 229.478), control1: CGPoint(x: 165.798, y: 261.1), control2: CGPoint(x: 195.389, y: 249.495))
                    path.addLine(to: CGPoint(x: 175.707, y: 197.565))
                    path.addCurve(to: CGPoint(x: 130.55, y: 210.62), control1: CGPoint(x: 164.683, y: 205.253), control2: CGPoint(x: 149.887, y: 210.62))
                    path.addCurve(to: CGPoint(x: 56.281, y: 156.37), control1: CGPoint(x: 96.027, y: 210.62), control2: CGPoint(x: 66.726, y: 187.847))
                    path.addLine(to: CGPoint(x: 15.983, y: 187.557))
                    path.addCurve(to: CGPoint(x: 130.55, y: 261.1), control1: CGPoint(x: 35.393, y: 231.798), control2: CGPoint(x: 79.49, y: 261.1))
                }
                .fill(Color(red: 52/255, green: 168/255, blue: 83/255))

                // Yellow Path
                Path { path in
                    path.move(to: CGPoint(x: 56.281, y: 156.37))
                    path.addCurve(to: CGPoint(x: 51.93, y: 130.55), control1: CGPoint(x: 53.525, y: 148.247), control2: CGPoint(x: 51.93, y: 139.543))
                    path.addCurve(to: CGPoint(x: 56.136, y: 104.73), control1: CGPoint(x: 51.93, y: 121.556), control2: CGPoint(x: 53.525, y: 112.853))
                    path.addLine(to: CGPoint(x: 15.26, y: 71.312))
                    path.addCurve(to: CGPoint(x: 0, y: 130.55), control1: CGPoint(x: 5.077, y: 89.644), control2: CGPoint(x: 0, y: 109.517))
                    path.addCurve(to: CGPoint(x: 13.925, y: 189.152), control1: CGPoint(x: 0, y: 151.583), control2: CGPoint(x: 5.077, y: 171.456))
                    path.addLine(to: CGPoint(x: 56.281, y: 156.37))
                }
                .fill(Color(red: 251/255, green: 188/255, blue: 5/255))

                // Red Path
                Path { path in
                    path.move(to: CGPoint(x: 130.55, y: 50.479))
                    path.addCurve(to: CGPoint(x: 181.029, y: 69.917), control1: CGPoint(x: 155.064, y: 50.479), control2: CGPoint(x: 171.6, y: 61.068))
                    path.addLine(to: CGPoint(x: 217.873, y: 33.943))
                    path.addCurve(to: CGPoint(x: 130.55, y: 0), control1: CGPoint(x: 195.245, y: 12.91), control2: CGPoint(x: 165.798, y: 0))
                    path.addCurve(to: CGPoint(x: 13.925, y: 71.947), control1: CGPoint(x: 79.49, y: 0), control2: CGPoint(x: 35.393, y: 29.301))
                    path.addLine(to: CGPoint(x: 56.136, y: 104.73))
                    path.addCurve(to: CGPoint(x: 130.55, y: 50.479), control1: CGPoint(x: 66.726, y: 73.253), control2: CGPoint(x: 96.027, y: 50.479))
                }
                .fill(Color(red: 235/255, green: 67/255, blue: 53/255))
            }
            .scaleEffect(geometry.size.width / 256, anchor: .topLeading)
        }
    }
}

