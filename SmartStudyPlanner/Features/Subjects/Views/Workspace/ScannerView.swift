import SwiftUI

enum ScanFlashMode: String, CaseIterable {
    case flash  = "Flash"
    case auto   = "Auto"
    case manual = "Manual"
}

struct ScannerView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    var onSave: (Resource) -> Void

    @State private var selectedMode: ScanFlashMode = .auto
    @State private var capturedCount: Int = 0
    @State private var isCaptured: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topControls
                    .padding(.top, theme.spacing.lg)

                Spacer()

                scanFrame

                Spacer()

                instructionText

                bottomControls
                    .padding(.bottom, theme.spacing.xl)
            }
        }
    }

    private var topControls: some View {
        HStack(spacing: theme.spacing.xl) {
            Button {
            } label: {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13))
                    Text(ScanFlashMode.flash.rawValue)
                        .font(theme.typography.bodySmall)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
            }

            HStack(spacing: 0) {
                ForEach(ScanFlashMode.allCases, id: \.self) { mode in
                    if mode == .flash { EmptyView() } else {
                        Button {
                            selectedMode = mode
                        } label: {
                            Text(mode.rawValue)
                                .font(theme.typography.bodySmall)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedMode == mode ? theme.colors.textOnPrimary : .white)
                                .padding(.horizontal, theme.spacing.md)
                                .padding(.vertical, theme.spacing.xs + 2)
                                .background(
                                    selectedMode == mode ? theme.colors.primary : Color.clear
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())

            Button {
            } label: {
                Text("Manual")
                    .font(theme.typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, theme.spacing.xl)
    }

    private var scanFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: theme.radius.lg)
                .fill(Color.white.opacity(0.05))
                .frame(width: 280, height: 360)

            RoundedRectangle(cornerRadius: theme.radius.lg)
                .stroke(theme.colors.primary, lineWidth: 2)
                .frame(width: 280, height: 360)

            Rectangle()
                .fill(theme.colors.primary.opacity(0.3))
                .frame(width: 280, height: 1)

            cornerMarkers

            if isCaptured {
                RoundedRectangle(cornerRadius: theme.radius.lg)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 280, height: 360)
                    .transition(.opacity)
            }
        }
        .shadow(color: theme.colors.primary.opacity(0.4), radius: 20, x: 0, y: 0)
    }

    private var cornerMarkers: some View {
        ZStack {
            VStack {
                HStack {
                    cornerMark(rotation: 0)
                    Spacer()
                    cornerMark(rotation: 90)
                }
                Spacer()
                HStack {
                    cornerMark(rotation: 270)
                    Spacer()
                    cornerMark(rotation: 180)
                }
            }
            .frame(width: 280, height: 360)
        }
    }

    private func cornerMark(rotation: Double) -> some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 20))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 20, y: 0))
            }
            .stroke(theme.colors.primary, lineWidth: 3)
            .frame(width: 20, height: 20)
        }
        .rotationEffect(.degrees(rotation))
        .padding(theme.spacing.sm)
    }

    private var instructionText: some View {
        Text("Position the document in view")
            .font(theme.typography.bodyMedium)
            .foregroundColor(.white.opacity(0.7))
            .padding(.bottom, theme.spacing.lg)
    }

    private var bottomControls: some View {
        HStack(spacing: 0) {
            Button {
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: theme.radius.md)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 56, height: 56)

                    if capturedCount > 0 {
                        RoundedRectangle(cornerRadius: theme.radius.md)
                            .stroke(theme.colors.primary, lineWidth: 2)
                            .frame(width: 56, height: 56)

                        Text("\(capturedCount)")
                            .font(theme.typography.bodySmall)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.1)) { isCaptured = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isCaptured = false
                    capturedCount += 1
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 72, height: 72)
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 84, height: 84)
                }
            }

            Spacer()

            Button {
                if capturedCount > 0 {
                    let resource = Resource(
                        name: "Scan \(Date().formatted(date: .abbreviated, time: .shortened))",
                        type: .scan,
                        size: "\(capturedCount) page\(capturedCount > 1 ? "s" : "")"
                    )
                    onSave(resource)
                }
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, theme.spacing.xxl)
    }
}
