import SwiftUI
import UIKit

struct AppDataBrowserView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var apps: [InstalledApp] = []
    @State private var isLoading = false
    @State private var isResolving = false
    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var hasLoaded = false
    @State private var workspaceURL: URL?
    @Binding private var tabSession: FilesTabSession
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    private let embedded: Bool

    init(
        tabSession: Binding<FilesTabSession>,
        onOpenSettings: @escaping () -> Void = {},
        onOpenLogs: @escaping () -> Void = {},
        embedded: Bool = false
    ) {
        _tabSession = tabSession
        self.onOpenSettings = onOpenSettings
        self.onOpenLogs = onOpenLogs
        self.embedded = embedded
    }

    private var filteredApps: [InstalledApp] {
        guard !searchText.isEmpty else { return apps }
        let q = searchText.lowercased()
        return apps.filter {
            $0.name.lowercased().contains(q) || $0.bundleID.lowercased().contains(q)
        }
    }

    private var overlayState: AppBrowserOverlayState {
        if (isLoading || isResolving) && apps.isEmpty { return .loading }
        if apps.isEmpty { return .empty }
        if filteredApps.isEmpty { return .noResults }
        return .none
    }

    private var interfaceAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.20)
    }

    var body: some View {
        Group {
            if embedded {
                embeddedContent
            } else {
                navigationContent(tabID: tabSession.selectedTabID)
                    .id(tabSession.selectedTabID)
            }
        }
    }

    private var embeddedContent: some View {
        appList
            .navigationTitle(language.text("browser.application"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { reload() } label: {
                        if isResolving {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isResolving)
                    .accessibilityLabel(language.text("browser.retry"))
                }
            }
            .onAppear {
                if !hasLoaded {
                    hasLoaded = true
                    reload()
                }
            }
    }

    private func navigationContent(tabID: UUID) -> some View {
        NavigationStack(path: navigationPath(for: tabID)) {
            appList
            .navigationTitle(language.text("browser.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    FilesTabToolbarButton(session: $tabSession)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { reload() } label: {
                        if isResolving {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isResolving)
                    .accessibilityLabel(language.text("browser.retry"))
                }
                AppUtilityToolbar(
                    language: language,
                    onOpenSettings: onOpenSettings,
                    onOpenLogs: onOpenLogs
                )
            }
            .onAppear {
                if workspaceURL == nil {
                    workspaceURL = try? PatchWorkspaceService.documentsRootURL()
                    _ = try? PatchWorkspaceService.patchesRootURL()
                }
                if !hasLoaded {
                    hasLoaded = true
                    reload()
                }
            }
            .navigationDestination(for: FileBrowserDestination.self) { destination in
                if destination.startPath == destination.containerPath {
                    FileBrowserView(
                        containerPath: destination.containerPath,
                        title: destination.title,
                        bundleID: destination.bundleID,
                        filesTabSession: $tabSession
                    )
                } else {
                    FileBrowserView(
                        containerPath: destination.containerPath,
                        startPath: destination.startPath,
                        title: destination.title,
                        bundleID: destination.bundleID,
                        filesTabSession: $tabSession
                    )
                }
            }
        }
    }

    private func navigationPath(for tabID: UUID) -> Binding<[FileBrowserDestination]> {
        Binding(
            get: { tabSession.navigationPath(for: tabID) },
            set: { tabSession.setNavigationPath($0, for: tabID) }
        )
    }

    private var appList: some View {
        VStack(spacing: 0) {
            if horizontalSizeClass == .regular {
                FilesTabStrip(session: $tabSession)
            }
            AppSearchField(
                text: $searchText,
                prompt: language.text("browser.search"),
                clearLabel: language.text("common.clear")
            )
            Divider()
            appRows
        }
    }

    private var appRows: some View {
        List {
            if !embedded, let workspaceURL {
                Section(language.text("browser.workspace")) {
                    let workspaceDestination = FileBrowserDestination(
                        containerPath: workspaceURL.path,
                        startPath: workspaceURL.path,
                        title: "3105",
                        bundleID: nil
                    )
                    NavigationLink(value: workspaceDestination) {
                        HStack(spacing: 10) {
                            AppRowIcon(systemName: "folder.fill")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("3105")
                                    .font(.subheadline.weight(.semibold))
                                Text(language.text("browser.workspace_subtitle"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .contextMenu {
                        openInNewTabButton(workspaceDestination)
                    }
                }
            }
            Section {
                ForEach(filteredApps) { app in
                    if app.containerPath.isEmpty {
                        appRow(app)
                    } else {
                        let appDestination = FileBrowserDestination(
                            containerPath: app.containerPath,
                            startPath: app.containerPath,
                            title: app.displayName,
                            bundleID: app.bundleID
                        )
                        NavigationLink(value: appDestination) {
                            appRow(app)
                        }
                        .contextMenu {
                            openInNewTabButton(appDestination)
                        }
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Text(language.text("browser.apps_count", Int64(filteredApps.count)))
                    Spacer()
                    if isResolving {
                        ProgressView()
                            .controlSize(.mini)
                        Text(language.text("browser.mha_scanning"))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.defaultMinListRowHeight, 48)
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            Group {
                switch overlayState {
                case .loading:
                    ProgressView(language.text("browser.loading"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .empty:
                    emptyView
                case .noResults:
                    searchEmptyView
                case .none:
                    EmptyView()
                }
            }
            .transition(.opacity)
            .animation(interfaceAnimation, value: overlayState)
        }
    }

    private func appRow(_ app: InstalledApp) -> some View {
        HStack(spacing: 10) {
            BrowserAppIcon(app: app)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                Text(app.bundleID)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if !app.version.isEmpty {
                Text(app.version)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 12))
    }

    private func openInNewTabButton(_ destination: FileBrowserDestination) -> some View {
        Button {
            tabSession.openTab(navigationPath: [destination])
        } label: {
            Label(language.text("browser.open_new_tab"), systemImage: "square.on.square")
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: AppTheme.emptyIconSize, weight: .light))
                .foregroundStyle(.secondary)
            Text(errorMessage ?? language.text("browser.empty"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Button(language.text("browser.retry")) { reload() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var searchEmptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: AppTheme.emptyIconSize, weight: .light))
                .foregroundStyle(.secondary)
            Text(language.text("browser.search_empty"))
                .font(.subheadline.weight(.medium))
            Text(language.text("browser.search_apps_empty_message"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func reload() {
        isLoading = true
        isResolving = true
        errorMessage = nil
        let emptyMessage = language.text("browser.empty")
        DispatchQueue.global(qos: .userInitiated).async {
            let bundleMetadata = ContainerStore.applicationBundleMetadataCatalog()
            let apiApps = ContainerStore.applyingBundleMetadata(
                to: ContainerStore.installedAppsFromAPI(),
                catalog: bundleMetadata
            )
            if apiApps.isEmpty {
                log("browser: installed-app API unavailable; trying MCM class-2 enumeration...")
            }
            let dynamicIdentifiers = ContainerStore.dynamicAppIdentifiers()
            let mcmApps = ContainerStore.installedAppsFromMCM(
                identifiers: dynamicIdentifiers,
                bundleMetadata: bundleMetadata
            )
            let filesystemApps = ContainerStore.containersFromFilesystem()
            let baseIdentifiedApps = mcmApps + apiApps
            var result = ContainerDiscoveryMerger.merge(
                enumerated: filesystemApps,
                identified: baseIdentifiedApps,
                path: { $0.containerPath }
            )
            log("browser: merged api=\(apiApps.count), MCM=\(mcmApps.count), filesystem=\(filesystemApps.count) -> \(result.count)")
            result.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

            let preliminary = result.filter {
                ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
            }
            DispatchQueue.main.async {
                apps = preliminary
                isLoading = false
            }

            let launchServicesIdentifiers = ContainerStore.launchServicesStoreIdentifiers()
            let mhaIdentifiers = MHAIdentifierCatalog.identifiers(
                dynamic: dynamicIdentifiers,
                installed: apiApps.map(\.bundleID),
                research: ContainerStore.researchAppIdentifiers,
                custom: bundleMetadata.keys.sorted(),
                launchServices: launchServicesIdentifiers
            )
            log(
                "browser: MHA catalog dynamic=\(dynamicIdentifiers.count), " +
                "installed=\(apiApps.count), research=\(ContainerStore.researchAppIdentifiers.count), " +
                "LaunchServices=\(launchServicesIdentifiers.count) -> \(mhaIdentifiers.count) candidates"
            )
            let mhaApps = ContainerStore.installedAppsFromMHACandidates(
                identifiers: mhaIdentifiers,
                bundleMetadata: bundleMetadata
            ) { discoveredApps in
                var progressiveResult = AppDataCatalogMerger.merge(
                    identified: discoveredApps + baseIdentifiedApps,
                    fallback: [],
                    identifier: { $0.bundleID },
                    path: { $0.containerPath }
                )
                progressiveResult = progressiveResult.filter {
                    ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
                }
                progressiveResult.sort {
                    $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
                }
                DispatchQueue.main.async {
                    apps = progressiveResult
                }
            }

            let allKnownApps = mhaApps + baseIdentifiedApps
            let identifiedPaths = Set(allKnownApps.map {
                ContainerDiscoveryMerger.canonicalPath($0.containerPath)
            })
            let unmatchedFilesystemApps = filesystemApps.filter {
                !identifiedPaths.contains(
                    ContainerDiscoveryMerger.canonicalPath($0.containerPath)
                )
            }
            let inferredFilesystemApps = ContainerStore.inferUnidentifiedApps(
                in: unmatchedFilesystemApps,
                knownApps: allKnownApps,
                launchServicesIdentifiers: Set(launchServicesIdentifiers)
            ).filter {
                ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
            }
            result = AppDataCatalogMerger.merge(
                identified: allKnownApps,
                fallback: inferredFilesystemApps,
                identifier: { $0.bundleID },
                path: { $0.containerPath }
            )
            result = result.filter {
                ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
            }
            result.sort {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

            DispatchQueue.main.async {
                apps = result
                isLoading = false
                isResolving = false
                if result.isEmpty {
                    errorMessage = emptyMessage
                }
            }
        }
    }
}

private enum AppBrowserOverlayState: Equatable {
    case loading
    case empty
    case noResults
    case none
}

struct BrowserAppIcon: View {
    let app: InstalledApp
    @State private var resolvedIcon: UIImage?
    @State private var didRequestIcon = false

    init(app: InstalledApp) {
        self.app = app
        _resolvedIcon = State(initialValue: app.icon)
    }

    var body: some View {
        Group {
            if let resolvedIcon {
                Image(uiImage: resolvedIcon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "app")
                    .font(.system(size: AppTheme.rowIconSize, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: AppTheme.appIconSize, height: AppTheme.appIconSize)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .accessibilityHidden(true)
        .onAppear {
            guard resolvedIcon == nil, !didRequestIcon else { return }
            didRequestIcon = true
            let bundleID = app.bundleID
            DispatchQueue.global(qos: .utility).async {
                let icon = iconForBundleID(bundleID)
                DispatchQueue.main.async {
                    resolvedIcon = icon
                }
            }
        }
    }
}

enum FilesRootLocation: String, CaseIterable, Identifiable {
    case application
    case appGroup
    case systemAppGroup

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .application: return "browser.application"
        case .appGroup: return "browser.app_group"
        case .systemAppGroup: return "browser.system_app_group"
        }
    }

    var detailKey: String? {
        switch self {
        case .application: return "browser.application_detail"
        case .appGroup: return "browser.app_group_detail"
        case .systemAppGroup: return nil
        }
    }

    var systemImage: String {
        switch self {
        case .application: return "square.stack.3d.up.fill"
        case .appGroup: return "person.2.fill"
        case .systemAppGroup: return "gearshape.2.fill"
        }
    }
}

struct FilesHomeView: View {
    @Environment(\.appLanguage) private var language
    @Binding private var tabSession: FilesTabSession
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    @State private var workspaceURL: URL?

    init(
        tabSession: Binding<FilesTabSession>,
        onOpenSettings: @escaping () -> Void = {},
        onOpenLogs: @escaping () -> Void = {}
    ) {
        _tabSession = tabSession
        self.onOpenSettings = onOpenSettings
        self.onOpenLogs = onOpenLogs
    }

    var body: some View {
        NavigationStack(path: navigationPath) {
            List {
                if let workspaceURL {
                    Section(language.text("browser.workspace")) {
                        NavigationLink(
                            value: FileBrowserDestination(
                                containerPath: workspaceURL.path,
                                startPath: workspaceURL.path,
                                title: "3105",
                                bundleID: nil
                            )
                        ) {
                            HStack(spacing: 10) {
                                AppRowIcon(systemName: "folder.fill")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("3105")
                                        .font(.subheadline.weight(.semibold))
                                    Text(language.text("browser.workspace_subtitle"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section {
                    ForEach(FilesRootLocation.allCases) { location in
                        NavigationLink {
                            destinationView(for: location)
                        } label: {
                            HStack(spacing: 10) {
                                AppRowIcon(systemName: location.systemImage)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(language.text(location.titleKey))
                                        .font(.subheadline.weight(.semibold))
                                    if let detailKey = location.detailKey {
                                        Text(language.text(detailKey))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text(language.text("browser.application_locations"))
                } footer: {
                    Text(language.text("browser.application_access_note"))
                }

                Section {
                    NavigationLink {
                        FileFavoritesView(tabSession: $tabSession)
                    } label: {
                        Label(language.text("browser.favorites"), systemImage: "star.fill")
                    }
                } header: {
                    Text(language.text("browser.favorites"))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(language.text("browser.tabs_root"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    FilesTabToolbarButton(session: $tabSession)
                }
                AppUtilityToolbar(
                    language: language,
                    onOpenSettings: onOpenSettings,
                    onOpenLogs: onOpenLogs
                )
            }
            .onAppear {
                if workspaceURL == nil {
                    workspaceURL = try? PatchWorkspaceService.documentsRootURL()
                    _ = try? PatchWorkspaceService.patchesRootURL()
                }
            }
            .navigationDestination(for: FileBrowserDestination.self) { destination in
                if destination.startPath == destination.containerPath {
                    FileBrowserView(
                        containerPath: destination.containerPath,
                        title: destination.title,
                        bundleID: destination.bundleID,
                        filesTabSession: $tabSession
                    )
                } else {
                    FileBrowserView(
                        containerPath: destination.containerPath,
                        startPath: destination.startPath,
                        title: destination.title,
                        bundleID: destination.bundleID,
                        filesTabSession: $tabSession
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for location: FilesRootLocation) -> some View {
        switch location {
        case .application:
            AppDataBrowserView(
                tabSession: $tabSession,
                onOpenSettings: onOpenSettings,
                onOpenLogs: onOpenLogs,
                embedded: true
            )
        case .appGroup:
            SharedContainerBrowser(
                mode: .appGroup,
                tabSession: $tabSession,
                onOpenSettings: onOpenSettings,
                onOpenLogs: onOpenLogs
            )
        case .systemAppGroup:
            SharedContainerBrowser(
                mode: .systemAppGroup,
                tabSession: $tabSession,
                onOpenSettings: onOpenSettings,
                onOpenLogs: onOpenLogs
            )
        }
    }

    private var navigationPath: Binding<[FileBrowserDestination]> {
        Binding(
            get: { tabSession.navigationPath(for: tabSession.selectedTabID) },
            set: { tabSession.setNavigationPath($0, for: tabSession.selectedTabID) }
        )
    }
}

struct SharedContainerBrowser: View {
    enum Mode: Hashable {
        case appGroup
        case systemAppGroup

        var parentPath: String {
            switch self {
            case .appGroup: return "/var/mobile/Containers/Shared/AppGroup"
            case .systemAppGroup: return "/var/containers/Shared/SystemGroup"
            }
        }

        var titleKey: String {
            switch self {
            case .appGroup: return "browser.app_group"
            case .systemAppGroup: return "browser.system_app_group"
            }
        }
    }

    @Environment(\.appLanguage) private var language
    let mode: Mode
    @Binding var tabSession: FilesTabSession
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    @State private var containers: [SharedContainer] = []
    @State private var hasLoaded = false
    @State private var accessFailed = false

    var body: some View {
        List {
            if containers.isEmpty {
                if hasLoaded {
                    Text(language.text("browser.shared_containers_access_note"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(containers) { container in
                    NavigationLink(
                        value: FileBrowserDestination(
                            containerPath: container.path,
                            startPath: container.path,
                            title: container.name,
                            bundleID: nil
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(container.name)
                                .font(.subheadline.weight(.semibold))
                            Text(container.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(language.text(mode.titleKey))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        let parent = mode.parentPath
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: parent) else {
            accessFailed = true
            return
        }
        containers = entries.compactMap { entry in
            let path = (parent as NSString).appendingPathComponent(entry)
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                  isDirectory.boolValue else { return nil }
            let name = Self.groupIdentifier(at: path) ?? entry
            return SharedContainer(id: path, name: name, path: path)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func groupIdentifier(at path: String) -> String? {
        let metadataPath = (path as NSString)
            .appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
        guard let metadata = NSDictionary(contentsOfFile: metadataPath) else { return nil }
        return metadata["MCMMetadataIdentifier"] as? String
    }
}

struct SharedContainer: Identifiable {
    let id: String
    let name: String
    let path: String
}

struct FileFavoritesView: View {
    @Environment(\.appLanguage) private var language
    @Binding var tabSession: FilesTabSession
    @ObservedObject private var store = FileFavoritesStore.shared

    var body: some View {
        List {
            if store.favorites.isEmpty {
                Text(language.text("browser.favorites_empty"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.favorites) { favorite in
                    NavigationLink(value: destination(for: favorite)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(favorite.name)
                                .font(.subheadline.weight(.semibold))
                            Text(favorite.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.remove(path: favorite.path)
                        } label: {
                            Label(language.text("browser.delete"), systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(language.text("browser.favorites"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func destination(for favorite: FileFavorite) -> FileBrowserDestination {
        FileBrowserDestination(
            containerPath: Self.containerRoot(for: favorite.path),
            startPath: favorite.path,
            title: favorite.name,
            bundleID: nil
        )
    }

    private static func containerRoot(for path: String) -> String {
        let roots = [
            "/var/mobile/Containers/Data/Application/",
            "/var/mobile/Containers/Shared/AppGroup/",
            "/var/containers/Shared/SystemGroup/"
        ]
        for root in roots {
            guard let range = path.range(of: root) else { continue }
            let remainder = path[range.upperBound...]
            guard let component = remainder.split(separator: "/").first else { continue }
            return root + component
        }
        return path
    }
}
