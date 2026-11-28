

import SwiftUI

struct PhotoJournalView: View {

    @StateObject private var viewModel = PhotoJournalViewModel()
    @ObservedObject private var network = NetworkMonitor.shared
    @State private var selectedPhoto: JournalPhoto?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let message = viewModel.message {
                    messageBanner(message)
                }

                if let report = viewModel.report {
                    summaryCard(report)
                    if !viewModel.documentedCategories.isEmpty {
                        categoriesCard(report)
                    }
                    gallerySection(report)
                    Text("Updated \(report.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                } else if viewModel.isLoading {
                    ProgressView("Opening your journal...")
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .background(Color.wandrCream)
        .navigationTitle("Photo journal")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refreshAndWait()
        }
        .task {
            await viewModel.load()
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoJournalDetailView(photo: photo, viewModel: viewModel)
        }
    }

    

    func messageBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: network.isConnected ? "exclamationmark.triangle" : "wifi.slash")
                .foregroundColor(.orange)
            Text(text)
                .font(.caption)
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.orange.opacity(0.12))
        .cornerRadius(12)
    }



    func summaryCard(_ report: PhotoJournalReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUESTS WITH PHOTO PROOF")
                .font(.caption2)
                .foregroundColor(.gray)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(report.documentedQuests)")
                    .font(.largeTitle).bold()
                    .foregroundColor(.wandrGreen)
                Text("of \(report.completedQuests) completed")
                    .foregroundColor(.gray)
                Spacer()
                Text("\(report.documentedPercentage)%")
                    .font(.title3).bold()
                    .foregroundColor(.wandrSage)
            }

            ProgressView(value: Double(report.documentedQuests),
                         total: Double(max(report.completedQuests, 1)))
                .tint(.wandrGreen)

            Text(viewModel.summaryText)
                .font(.caption)
                .foregroundColor(.gray)

            if report.totalPhotos > 0 {
                Label("\(report.totalPhotos) \(report.totalPhotos == 1 ? "photo" : "photos") saved",
                      systemImage: "photo.on.rectangle")
                    .font(.caption).bold()
                    .foregroundColor(.wandrGreen)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }



    func categoriesCard(_ report: PhotoJournalReport) -> some View {
        let categories = viewModel.documentedCategories
        let maxValue = max(categories.first?.documentedQuests ?? 1, 1)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MOST DOCUMENTED CATEGORIES")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                if let top = report.topCategory {
                    Label(top.category, systemImage: "crown.fill")
                        .font(.caption).bold()
                        .foregroundColor(.wandrSand)
                }
            }

            ForEach(categories.prefix(5)) { category in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.category)
                            .font(.subheadline).bold()
                            .foregroundColor(.wandrGreen)
                        Spacer()
                        Text("\(category.documentedQuests) of \(category.completedQuests)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.wandrSage.opacity(0.15))
                            Capsule()
                                .fill(category.id == report.topCategory?.id ? Color.wandrGreen : Color.wandrSage)
                                .frame(width: proxy.size.width * CGFloat(category.documentedQuests) / CGFloat(maxValue))
                        }
                    }
                    .frame(height: 8)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .cardStyle()
    }



    @ViewBuilder
    func gallerySection(_ report: PhotoJournalReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR PROOFS")
                .font(.caption2)
                .foregroundColor(.gray)

            if report.totalPhotos == 0 {
                emptyGallery()
            } else {
                categoryChips()
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(viewModel.visiblePhotos) { photo in
                        Button {
                            selectedPhoto = photo
                        } label: {
                            thumbnail(photo)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(photo.questTitle), \(photo.category)")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func categoryChips() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(viewModel.documentedCategories) { category in
                    chip("\(category.category) · \(category.documentedQuests)",
                         isSelected: viewModel.selectedCategory == category.category) {
                        viewModel.selectedCategory = category.category
                    }
                }
            }
        }
    }

    func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption).bold()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.wandrGreen : Color.white)
                .foregroundColor(isSelected ? .white : .wandrGreen)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.wandrSage.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }

    func thumbnail(_ photo: JournalPhoto) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                CachedRemoteImage(
                    key: photo.thumbnailKey,
                    url: viewModel.url(for: photo),
                    maxPixelSize: PhotoJournalViewModel.thumbnailPixels
                ) {
                    ZStack {
                        Color.wandrSage.opacity(0.12)
                        Image(systemName: network.isConnected ? "photo" : "icloud.slash")
                            .foregroundColor(.wandrSage)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func emptyGallery() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 36))
                .foregroundColor(.wandrSage)
            Text("No photo proofs yet")
                .font(.subheadline).bold()
                .foregroundColor(.wandrGreen)
            Text("Quest steps with a camera icon ask for a photo. They will show up here.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}


struct PhotoJournalDetailView: View {
    let photo: JournalPhoto
    @ObservedObject var viewModel: PhotoJournalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var url: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photoCard()
                    infoCard()
                }
                .padding()
            }
            .background(Color.wandrCream)
            .navigationTitle("Quest proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.wandrGreen)
                }
            }
            .task {
                url = await viewModel.detailURL(for: photo)
            }
        }
    }

    func photoCard() -> some View {
        Color.clear
            .aspectRatio(0.8, contentMode: .fit)   // 4:5
            .frame(maxWidth: .infinity)
            .overlay {
                CachedRemoteImage(
                    key: photo.fullKey,
                    url: url,
                    maxPixelSize: PhotoJournalViewModel.fullPixels,
                    fallbackKey: photo.thumbnailKey
                ) {
                    ZStack {
                        Color.wandrSage.opacity(0.12)
                        ProgressView()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .topLeading) {
                Label("Photo proof", systemImage: "checkmark.seal.fill")
                    .font(.caption).bold()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(12)
            }
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    func infoCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(photo.questTitle)
                .font(.title3).bold()
                .foregroundColor(.wandrGreen)
                .fixedSize(horizontal: false, vertical: true)

            Text(photo.category)
                .font(.caption).bold()
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.wandrSage.opacity(0.15))
                .foregroundColor(.wandrGreen)
                .clipShape(Capsule())

            Divider()

            if !photo.placeName.isEmpty {
                infoRow(icon: "mappin.and.ellipse", title: "Place", value: photo.placeName)
            }
            if let date = photo.takenAt {
                infoRow(icon: "calendar", title: "Completed",
                        value: date.formatted(date: .long, time: .shortened))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.wandrGreen)
                .frame(width: 32, height: 32)
                .background(Color.wandrSage.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    NavigationStack {
        PhotoJournalView()
    }
}
