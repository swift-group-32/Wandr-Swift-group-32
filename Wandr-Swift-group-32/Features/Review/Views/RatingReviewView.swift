import SwiftUI
import PhotosUI

struct RatingReviewView: View {
    @StateObject private var viewModel: RatingReviewViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @FocusState private var notesFocused: Bool
    private let canvas = Color(red: 246/255, green: 245/255, blue: 241/255)
    private let inactive = Color(red: 236/255, green: 234/255, blue: 228/255)
    private let gold = Color(red: 251/255, green: 237/255, blue: 199/255)

    init(context: ReviewContext) {
        _viewModel = StateObject(wrappedValue: RatingReviewViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                celebrationCard
                questCard
                ratingCard
                highlightsCard
                notesCard
                photosCard
                accuracyCard
                actions
            }
            .padding(16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(canvas.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Rating & Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(canvas, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.wandrGreen)
                    .accessibilityHidden(true)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { notesFocused = false }
            }
        }
        .disabled(viewModel.isSubmitting)
        .onChange(of: selectedPhotos) { _, items in
            Task {
                viewModel.isLoadingPhotos = true
                defer { viewModel.isLoadingPhotos = false; selectedPhotos = [] }
                for item in items {
                    do {
                        if let data = try await item.loadTransferable(type: Data.self) {
                            viewModel.addPhoto(data)
                        } else {
                            viewModel.errorMessage = "This photo could not be loaded. Please try again."
                        }
                    } catch {
                        viewModel.errorMessage = "This photo could not be loaded. Please try again."
                    }
                }
            }
        }
        .alert("Could not save review", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: { Text(viewModel.errorMessage ?? "") }
        .alert("Review saved", isPresented: $viewModel.didSave) {
            Button("Done") { dismiss() }
        } message: {
            Text(viewModel.submissionResult?.alreadySubmitted == true
                 ? "Your review was already submitted. No additional XP was awarded."
                 : "Thanks for helping fellow explorers discover more with Wandr. You earned \(viewModel.submissionResult?.xpEarned ?? 0) XP!")
        }
    }

    private var celebrationCard: some View {
        card {
            HStack(spacing: 12) {
                Image("ReviewMascot")
                    .resizable().scaledToFit().padding(4).frame(width: 56, height: 64)
                    .background(Color.wandrSage.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            badge("Quest Accomplished", icon: "checkmark.seal.fill", color: .wandrSage.opacity(0.15))
                            Spacer(minLength: 4)
                            badge("+\(viewModel.context.xpEarned) pts", icon: "star.fill", color: gold)
                        }
                        badge("Quest Accomplished", icon: "checkmark.seal.fill", color: .wandrSage.opacity(0.15))
                    }
                    Text("Wandr says: Great discovery!").font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.wandrGreen)
                    Text("Leave your verdict to immortalize this spot.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var questCard: some View {
        card {
            HStack(spacing: 12) {
                Group {
                    if viewModel.context.id == ReviewContext.preview.id {
                        Image(systemName: "birthday.cake.fill")
                            .font(.title).foregroundStyle(Color.wandrGreen)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(gold)
                    } else {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title).foregroundStyle(Color.wandrGreen)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.wandrSage.opacity(0.15))
                    }
                }
                .frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.white, Color.wandrGreen)
                        .padding(3).accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.context.placeName.uppercased())
                        .font(.caption2.weight(.semibold)).tracking(1).foregroundStyle(Color.wandrGreen)
                    Text(viewModel.context.title).font(.subheadline.weight(.semibold))
                    if let address = viewModel.context.address {
                        Label(address, systemImage: "mappin.and.ellipse")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var ratingCard: some View {
        card {
            VStack(spacing: 18) {
                Text("How was your side quest?").font(.title3.weight(.semibold)).foregroundStyle(Color.wandrGreen)
                Text("Your review helps fellow explorers uncover authentic spots.")
                    .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button { viewModel.rating = star } label: {
                            Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
                                .font(.system(size: 29)).foregroundStyle(star <= viewModel.rating ? Color.orange : .gray)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(star) \(star == 1 ? "star" : "stars")")
                        .accessibilityValue(star == viewModel.rating ? "Selected" : "")
                    }
                }
                Text("\(viewModel.rating).0  ·  \(viewModel.ratingDescription)")
                    .font(.caption.weight(.semibold)).foregroundStyle(Color(red: 99/255, green: 72/255, blue: 0))
                    .padding(.horizontal, 14).padding(.vertical, 8).background(gold, in: Capsule())
            }
            .frame(maxWidth: .infinity).padding(.vertical, 4)
        }
    }

    private var highlightsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Quick Highlights", detail: "Select all that apply")
                ReviewFlowLayout(spacing: 8) {
                    ForEach(viewModel.highlights, id: \.self) { highlight in
                        let selected = viewModel.selectedHighlights.contains(highlight)
                        Button { viewModel.toggleHighlight(highlight) } label: {
                            HStack(spacing: 6) {
                                if selected { Image(systemName: "checkmark").font(.caption2) }
                                Text(highlight).font(.caption)
                            }
                            .padding(.horizontal, 14).frame(minHeight: 36)
                            .foregroundStyle(selected ? .white : Color.primary)
                            .background(selected ? Color.wandrGreen : inactive, in: Capsule())
                        }
                        .buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
        }
    }

    private var notesCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Quest Notes", detail: "\(viewModel.notes.unicodeScalars.count)/\(viewModel.characterLimit)")
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        if viewModel.notes.isEmpty {
                            Text("Write what made this spot special, secret tips…")
                                .font(.subheadline).foregroundStyle(.secondary).padding(.top, 8).padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $viewModel.notes).font(.subheadline)
                            .scrollContentBackground(.hidden).frame(minHeight: 105)
                            .focused($notesFocused).accessibilityLabel("Quest notes")
                    }
                    Divider()
                    Label("Share a tip for the next explorer", systemImage: "sparkles")
                        .font(.caption).foregroundStyle(Color.wandrGreen)
                }
                .padding(12).background(canvas, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var photosCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Photos & Proof", detail: "\(viewModel.photos.count) \(viewModel.photos.count == 1 ? "photo" : "photos") attached")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.photos) { photo in
                        if let image = UIImage(data: photo.data) {
                            GeometryReader { geometry in
                                Image(uiImage: image).resizable().scaledToFill()
                                    .frame(width: geometry.size.width, height: 120).clipped()
                            }
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(alignment: .topTrailing) {
                                    Button { viewModel.photos.removeAll { $0.id == photo.id } } label: {
                                        Image(systemName: "xmark").font(.caption.bold()).foregroundStyle(.white)
                                            .padding(8).background(.black.opacity(0.6), in: Circle())
                                    }.padding(8).accessibilityLabel("Remove attached photo")
                                }
                        }
                    }
                    if viewModel.photos.count < viewModel.photoLimit {
                        PhotosPicker(selection: $selectedPhotos,
                                     maxSelectionCount: viewModel.photoLimit - viewModel.photos.count, matching: .images) {
                            VStack(spacing: 8) {
                                if viewModel.isLoadingPhotos { ProgressView() }
                                else { Image(systemName: "camera.badge.ellipsis").font(.title3) }
                                Text("+ Add Photo").font(.caption.weight(.semibold))
                                Text("Up to \(viewModel.photoLimit) photos").font(.caption2).foregroundStyle(.secondary)
                            }
                            .foregroundStyle(Color.wandrGreen).frame(maxWidth: .infinity).frame(height: 120)
                            .background(canvas, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4])))
                        }.disabled(viewModel.isLoadingPhotos)
                    }
                }
                Toggle(isOn: $viewModel.featureOnDiscoveryMap) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Feature on Discovery Map").font(.caption.weight(.semibold))
                        Text("Allow other explorers to discover this spot and see your review photos.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .tint(.wandrGreen).padding(12).background(canvas, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var accuracyCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Accuracy Check", detail: "Did spot match?")
                HStack(spacing: 8) {
                    ForEach(ReviewAccuracy.allCases) { accuracy in
                        let selected = viewModel.accuracy == accuracy
                        Button { viewModel.accuracy = accuracy } label: {
                            Text(accuracy.title).font(.caption.weight(selected ? .semibold : .regular))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .foregroundStyle(selected ? .white : Color.primary)
                                .background(selected ? Color.wandrGreen : inactive, in: RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                notesFocused = false
                Task { await viewModel.save() }
            } label: {
                HStack {
                    if viewModel.isSubmitting { ProgressView().tint(.white) }
                    Text("Submit Review & Claim +20 XP").font(.subheadline.weight(.semibold))
                    Image(systemName: "checkmark")
                }
                .frame(maxWidth: .infinity, minHeight: 52).foregroundStyle(.white)
                .background(Color.wandrGreen, in: Capsule())
            }
            .disabled(viewModel.isLoadingPhotos || viewModel.isSubmitting)
            Button { dismiss() } label: {
                Label("Skip for now", systemImage: "xmark").font(.subheadline)
                    .frame(maxWidth: .infinity, minHeight: 48).foregroundStyle(Color.wandrGreen)
                    .background(.white, in: Capsule())
            }
        }.buttonStyle(.plain).padding(.top, 6)
    }

    private func sectionHeader(_ title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased()).font(.caption.weight(.semibold)).tracking(1)
                .foregroundStyle(Color.wandrGreen)
            Spacer(minLength: 8)
            Text(detail).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func badge(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon).font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.wandrGreen).padding(.horizontal, 8).padding(.vertical, 4)
            .background(color, in: Capsule())
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content().padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.black.opacity(0.04)))
            .shadow(color: .black.opacity(0.025), radius: 8, y: 2)
    }
}

private struct ReviewFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews, width: proposal.width ?? 560).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews, width: bounds.width)
        for (index, point) in arrangement.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                                  proposal: ProposedViewSize(width: min(subviews[index].sizeThatFits(.unspecified).width, bounds.width), height: nil))
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (size: CGSize, points: [CGPoint]) {
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        var points: [CGPoint] = []
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: width, height: nil))
            if x > 0 && x + size.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: width, height: y + rowHeight), points)
    }
}

#Preview {
    NavigationStack { RatingReviewView(context: .preview) }
}
