import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

struct BanknoteOverlayView: View {
    let recognized: [RecognizedBanknote]
    let onTapFeature: (RecognizedBanknote, SecurityFeature) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(recognized) { banknote in
                    BanknoteMarkerView(banknote: banknote, proxy: proxy, onTap: { feature in
                        onTapFeature(banknote, feature)
                    })
                }
            }
        }
    }
}

struct BanknoteMarkerView: View {
    let banknote: RecognizedBanknote
    let proxy: GeometryProxy
    let onTap: (SecurityFeature) -> Void

    var body: some View {
        let rect = banknote.boundingBox
        let frame = CGRect(
            x: proxy.size.width * rect.x,
            y: proxy.size.height * rect.y,
            width: proxy.size.width * rect.width,
            height: proxy.size.height * rect.height
        )
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: 3)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)

            VStack(spacing: 6) {
                Text(banknote.denomination.formatted)
                    .font(.headline)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                if let definition = banknote.definition {
                    ForEach(definition.securityFeatures) { feature in
                        FeaturePin(feature: feature, parentFrame: frame)
                            .onTapGesture { onTap(feature) }
                    }
                }
            }
            .position(x: frame.midX, y: frame.midY - frame.height / 2 - 30)
        }
    }
}

struct FeaturePin: View {
    let feature: SecurityFeature
    let parentFrame: CGRect

    var body: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.8))
            .frame(width: 14, height: 14)
            .overlay(
                Circle().stroke(.white, lineWidth: 2)
            )
            .position(
                x: parentFrame.width * feature.position.x,
                y: parentFrame.height * feature.position.y
            )
            .accessibilityLabel(feature.title)
    }
}
