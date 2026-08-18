import SwiftUI

struct MechanicBoardView: View {
    let authViewModel: AuthViewModel
    let taskViewModel: TaskViewModel

    @Environment(\.appTheme) private var theme
    @State private var isShowingSettings = false
    @State private var selectedList: TaskList?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let errorMessage = taskViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                if taskViewModel.isLoading && taskViewModel.taskLists.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if taskViewModel.taskLists.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 32))
                            .foregroundStyle(theme.textSecondary)
                        Text("board.empty.title")
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(taskViewModel.vehiclesByStatus, id: \.status) { group in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(LocalizedStringKey(group.status.labelKey))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(theme.textSecondary)
                                        .padding(.horizontal, 16)

                                    ForEach(group.vehicles) { vehicle in
                                        Button {
                                            selectedList = vehicle
                                        } label: {
                                            VehicleCard(vehicle: vehicle)
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background)
            .navigationTitle(Text("app.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if taskViewModel.hasPendingSync {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(theme.textSecondary)
                            .symbolEffect(.rotate, isActive: true)
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(authViewModel: authViewModel)
            }
            .task {
                await taskViewModel.loadLists()
            }
            .navigationDestination(item: $selectedList) { list in
                VehicleDetailView(taskViewModel: taskViewModel, list: list)
            }
            .searchable(text: Binding(
                get: { taskViewModel.searchText },
                set: { taskViewModel.searchText = $0 }
            ), prompt: Text("board.search.prompt"))
        }
    }
}

private struct VehicleCard: View {
    let vehicle: TaskList
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vehicle.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.text)
            Text("\(vehicle.items.filter(\.completed).count)/\(vehicle.items.count) serviços")
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
