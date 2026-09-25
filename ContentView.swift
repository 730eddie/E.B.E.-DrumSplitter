import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private let separator = DrumSeparationService()

    @State private var showImporter = false
    @State private var inputURL: URL?
    @State private var selectedKinds = Set(DrumStem.Kind.allCases)
    @State private var stems: [DrumStem] = []
    @State private var isProcessing = false
    @State private var progressText = ""
    @State private var errorMessage: String?
    @State private var shareURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    importCard
                    stemPicker
                    actionButton
                    results
                }
                .padding()
            }
            .navigationTitle("E.B.E.'s Drum Splitter")
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false,
                onCompletion: handleImport
            )
            .sheet(isPresented: Binding(
                get: { shareURL != nil },
                set: { if !$0 { shareURL = nil } }
            )) {
                if let shareURL { ShareSheet(items: [shareURL]) }
            }
            .alert("Drum Splitter", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.badge.magnifyingglass")
                .font(.system(size: 58, weight: .bold))
            Text("Pull the drums apart.")
                .font(.title2.bold())
            Text("Import a song, choose the drum parts you want, then split and export them.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private var importCard: some View {
        Button { showImporter = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "music.note.list")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(inputURL == nil ? "Choose Audio" : "Audio Selected")
                        .font(.headline)
                    Text(inputURL?.lastPathComponent ?? "WAV, M4A, MP3 and other iOS-supported audio")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var stemPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drum parts")
                .font(.headline)
            ForEach(DrumStem.Kind.allCases) { kind in
                Toggle(isOn: Binding(
                    get: { selectedKinds.contains(kind) },
                    set: { enabled in
                        if enabled { selectedKinds.insert(kind) }
                        else { selectedKinds.remove(kind) }
                    }
                )) {
                    Label(kind.rawValue, systemImage: kind.systemImage)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var actionButton: some View {
        Button(action: splitAudio) {
            HStack {
                if isProcessing { ProgressView() }
                Text(isProcessing ? progressText : "Split Drums")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(inputURL == nil || selectedKinds.isEmpty || isProcessing)
    }

    @ViewBuilder
    private var results: some View {
        if !stems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Separated stems")
                    .font(.headline)
                ForEach(stems) { stem in
                    HStack {
                        Label(stem.kind.rawValue, systemImage: stem.kind.systemImage)
                        Spacer()
                        if let url = stem.outputURL {
                            Button("Export") { shareURL = url }
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let source = try result.get().first else { return }
            let accessed = source.startAccessingSecurityScopedResource()
            defer { if accessed { source.stopAccessingSecurityScopedResource() } }

            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("EBE-input-\(UUID().uuidString)-\(source.lastPathComponent)")
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: source, to: destination)
            inputURL = destination
            stems = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func splitAudio() {
        guard let inputURL else { return }
        isProcessing = true
        progressText = "Separating…"
        stems = []

        Task {
            do {
                let output = try await separator.separate(
                    inputURL: inputURL,
                    kinds: DrumStem.Kind.allCases.filter { selectedKinds.contains($0) }
                )
                await MainActor.run {
                    stems = output
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
}
