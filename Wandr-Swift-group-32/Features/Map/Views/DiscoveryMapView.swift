import MapKit
import SwiftUI

struct DiscoveryMapView: View {
    @StateObject private var viewModel = DiscoveryMapViewModel()
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var mode: MapMode = .nearby
    @State private var camera: MapCameraPosition = .region(Self.region(center: .bogota, radiusKm: 5))
    @State private var selectedPin: String?
    @State private var isVisible = false

    private enum MapMode: String, CaseIterable {
        case nearby = "Nearby", activity = "Neighborhoods"
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroll in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Picker("Map content", selection: $mode) {
                            ForEach(MapMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("map.mode")

                        if mode == .nearby { radiusPicker }
                        map
                        if let notice = viewModel.locationNotice { locationNotice(notice) }
                        if mode == .nearby { nearbySection } else { activitySection }
                    }
                    .padding()
                }
                .refreshable { await viewModel.refresh() }
                .onChange(of: selectedPin) { _, pin in
                    guard let pin else { return }
                    withAnimation { scroll.scrollTo(pin, anchor: .center) }
                }
            }
            .background(Color.wandrCream)
            .navigationTitle("Discovery Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        updateCamera()
                    } label: {
                        Image(systemName: "location.fill")
                    }
                    .accessibilityLabel("Center map")
                }
            }
        }
        .tint(Color.wandrGreen)
        .onAppear { isVisible = true; viewModel.start() }
        .onDisappear { isVisible = false; viewModel.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && isVisible { viewModel.start() } else { viewModel.stop() }
        }
        .onChange(of: viewModel.center) { _, _ in
            if mode == .nearby { updateCamera() }
        }
        .onChange(of: viewModel.radiusKm) { _, _ in updateCamera() }
        .onChange(of: mode) { _, _ in
            selectedPin = nil
            updateCamera()
        }
        .onChange(of: viewModel.activity) { _, _ in
            if mode == .activity { updateCamera() }
        }
    }

    private var radiusPicker: some View {
        HStack(spacing: 10) {
            ForEach(DiscoveryMapViewModel.radiusOptions, id: \.self) { radius in
                Button {
                    selectedPin = nil
                    viewModel.setRadius(radius)
                } label: {
                    Text("\(Int(radius)) km")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(viewModel.radiusKm == radius ? Color.wandrGreen : Color.white)
                        .foregroundStyle(viewModel.radiusKm == radius ? Color.white : Color.wandrGreen)
                        .clipShape(Capsule())
                }
                .accessibilityLabel("Search within \(Int(radius)) kilometers")
                .accessibilityAddTraits(viewModel.radiusKm == radius ? [.isSelected] : [])
            }
        }
    }

    private var map: some View {
        Map(position: $camera, selection: $selectedPin) {
            if viewModel.showsUserLocation { UserAnnotation() }
            if mode == .nearby {
                MapCircle(center: viewModel.center.coordinate, radius: viewModel.radiusKm * 1_000)
                    .foregroundStyle(Color.wandrSage.opacity(0.12))
                    .stroke(Color.wandrSage.opacity(0.5), lineWidth: 1)
                ForEach(viewModel.quests) { quest in
                    Marker(quest.title, systemImage: "flag.fill", coordinate: quest.point.coordinate)
                        .tint(Color.wandrGreen)
                        .tag("quest-\(quest.id)")
                }
            } else {
                ForEach(viewModel.activeNeighborhoods) { neighborhood in
                    Annotation(neighborhood.name, coordinate: neighborhood.point.coordinate) {
                        Text("\(neighborhood.completedQuests)")
                            .font(.headline)
                            .padding(10)
                            .background(Color.wandrGreen)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .accessibilityLabel("\(neighborhood.name): \(neighborhood.completedQuests) completed quests")
                    }
                    .tag("neighborhood-\(neighborhood.id)")
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls { MapCompass() }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityIdentifier("map.canvas")
        .overlay(alignment: .topLeading) {
            if mode == .nearby && viewModel.isLoadingNearby {
                ProgressView().padding(12).background(.regularMaterial, in: Capsule()).padding(12)
            }
        }
    }

    private func locationNotice(_ notice: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(notice, systemImage: "location.slash")
                .font(.footnote)
            if viewModel.locationState == .denied {
                Button("Open location settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .font(.footnote.weight(.semibold))
            } else if viewModel.locationState == .unavailable {
                Button("Retry location") { viewModel.stop(); viewModel.start() }
                    .font(.footnote.weight(.semibold))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wandrSand.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder private var nearbySection: some View {
        Text("Quests within \(Int(viewModel.radiusKm)) km").font(.title3.bold())
        if viewModel.isLoadingNearby {
            ProgressView("Loading nearby quests…").frame(maxWidth: .infinity)
        } else if let error = viewModel.nearbyError {
            errorCard(error, retry: viewModel.reloadNearby)
        } else if viewModel.quests.isEmpty {
            emptyCard("No quests nearby", detail: "Try a larger radius to find your next discovery.", icon: "flag")
        } else {
            ForEach(viewModel.quests) { quest in
                Button {
                    selectedPin = "quest-\(quest.id)"
                    camera = .region(Self.region(center: quest.point, radiusKm: 0.5))
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "flag.fill")
                            .font(.title3).foregroundStyle(Color.wandrGreen)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(quest.title).font(.headline).foregroundStyle(Color.wandrGreen)
                            Text(quest.placeName).font(.subheadline).foregroundStyle(.secondary)
                            HStack {
                                Text("\(quest.distanceKm, specifier: "%.1f") km")
                                if quest.duration > 0 { Text("· \(quest.duration) min") }
                            }
                            .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
                .id("quest-\(quest.id)")
            }
        }
    }

    @ViewBuilder private var activitySection: some View {
        Text("Neighborhood activity").font(.title3.bold())
        Text("All mapped neighborhoods · Last \(viewModel.activityDays) days")
            .font(.subheadline).foregroundStyle(.secondary)
        if viewModel.isLoadingActivity {
            ProgressView("Loading neighborhood activity…").frame(maxWidth: .infinity)
        } else if let error = viewModel.activityError {
            errorCard(error, retry: viewModel.reloadActivity)
        } else if let report = viewModel.activity {
            if !viewModel.leadingNeighborhoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Most quest activity", systemImage: "chart.bar.fill")
                        .font(.caption.weight(.semibold))
                    Text(viewModel.leadingNeighborhoods.map { "\($0.name), \($0.city)" }.joined(separator: "; "))
                        .font(.title3.bold())
                    Text("\(viewModel.leadingNeighborhoods[0].completedQuests) completed quests each. Prioritize these areas for local business partnerships.")
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.white)
                .background(Color.wandrGreen, in: RoundedRectangle(cornerRadius: 16))
            } else {
                emptyCard("No ranked activity yet", detail: "No completed quests were assigned to neighborhoods during this period.", icon: "chart.bar")
            }
            if report.unassignedCompletions > 0 {
                Label("\(report.unassignedCompletions) completed quests have no neighborhood assignment and are excluded from the ranking.", systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Text("\(report.windowStart.formatted(date: .abbreviated, time: .omitted)) – \(report.windowEnd.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(report.neighborhoods) { neighborhood in
                Button {
                    selectedPin = "neighborhood-\(neighborhood.id)"
                    camera = .region(Self.region(center: neighborhood.point, radiusKm: 1))
                } label: {
                    HStack(spacing: 12) {
                        let rank = 1 + report.neighborhoods.filter { $0.completedQuests > neighborhood.completedQuests }.count
                        Text("\(rank)").font(.title2.bold()).foregroundStyle(Color.wandrSage)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(neighborhood.name).font(.headline).foregroundStyle(Color.wandrGreen)
                            Text(neighborhood.city).font(.caption).foregroundStyle(.secondary)
                            Text("\(neighborhood.activeParticipants) participants · \(neighborhood.activePlaces) places")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        VStack {
                            Text("\(neighborhood.completedQuests)").font(.title2.bold())
                            Text("completed").font(.caption2)
                        }
                        .foregroundStyle(Color.wandrGreen)
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
                .id("neighborhood-\(neighborhood.id)")
            }
        }
    }

    private func errorCard(_ message: String, retry: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(message, systemImage: "exclamationmark.circle")
            Button("Retry", action: retry).buttonStyle(.bordered)
        }
        .cardStyle()
    }

    private func emptyCard(_ title: String, detail: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private func updateCamera() {
        if mode == .activity, !viewModel.activeNeighborhoods.isEmpty {
            var rect = MKMapRect.null
            for neighborhood in viewModel.activeNeighborhoods {
                let point = MKMapPoint(neighborhood.point.coordinate)
                rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 1, height: 1))
            }
            let padding = max(rect.width, rect.height) * 0.15 + 4_000
            camera = .rect(rect.insetBy(dx: -padding, dy: -padding))
        } else {
            camera = .region(Self.region(center: viewModel.center, radiusKm: viewModel.radiusKm))
        }
    }

    private static func region(center: MapPoint, radiusKm: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(center: center.coordinate, latitudinalMeters: radiusKm * 2_500,
                           longitudinalMeters: radiusKm * 2_500)
    }
}
