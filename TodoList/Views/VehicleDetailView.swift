import SwiftUI

struct VehicleDetailView: View {
    let taskViewModel: TaskViewModel
    let list: TaskList

    @Environment(\.appTheme) private var theme
    @State private var newService = ""
    @State private var newQuote = ""
    @State private var selectedFlag = "procurando_peca"

    private var current: TaskList {
        taskViewModel.taskLists.first(where: { $0.id == list.id }) ?? list
    }

    private var quotes: [QuoteItem] {
        taskViewModel.quotesByList[current.id] ?? []
    }

    private var flags: [PendingFlag] {
        taskViewModel.flagsByList[current.id] ?? []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(current.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)

                VStack(alignment: .leading, spacing: 8) {
                    Text("vehicle.section.status")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(VehicleStatus.mechanicTransitions, id: \.self) { status in
                                Button {
                                    Task { await taskViewModel.changeStatus(current, to: status) }
                                } label: {
                                    Text(LocalizedStringKey(status.labelKey))
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(current.status == status ? theme.text : theme.card)
                                        .foregroundStyle(current.status == status ? theme.background : theme.text)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("vehicle.section.services")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                    ForEach(current.items) { item in
                        HStack {
                            Button {
                                Task { await taskViewModel.toggleCompleted(item, in: current) }
                            } label: {
                                Image(systemName: item.completed ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(theme.text)
                            }
                            Text(item.text)
                                .strikethrough(item.completed)
                                .foregroundStyle(theme.text)
                            Spacer()
                        }
                    }
                    HStack {
                        TextField("vehicle.placeholder.service", text: $newService)
                            .textFieldStyle(.plain)
                        Button("common.action.create") {
                            Task {
                                await taskViewModel.addItem(text: newService, to: current)
                                newService = ""
                            }
                        }
                    }
                    .padding(10)
                    .background(theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("vehicle.section.quotes")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                    ForEach(quotes) { quote in
                        Text(quote.text)
                            .font(.subheadline)
                            .foregroundStyle(theme.text)
                    }
                    HStack {
                        TextField("vehicle.placeholder.quote", text: $newQuote)
                            .textFieldStyle(.plain)
                        Button("common.action.create") {
                            Task {
                                await taskViewModel.addQuote(text: newQuote, to: current)
                                newQuote = ""
                            }
                        }
                    }
                    .padding(10)
                    .background(theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("vehicle.section.flags")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                    ForEach(flags) { flag in
                        HStack {
                            Text(flag.flagType)
                                .foregroundStyle(theme.text)
                            Spacer()
                            if flag.resolvedAt == nil {
                                Button("vehicle.action.resolve") {
                                    Task { await taskViewModel.resolveFlag(flag, in: current) }
                                }
                            } else {
                                Text("vehicle.flag.resolved")
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                    HStack {
                        Picker("vehicle.placeholder.flag", selection: $selectedFlag) {
                            Text("flag.procurando_peca").tag("procurando_peca")
                            Text("flag.aguardando_cliente").tag("aguardando_cliente")
                            Text("flag.aguardando_orcamento").tag("aguardando_orcamento")
                            Text("flag.aguardando_peca").tag("aguardando_peca")
                        }
                        Button("common.action.create") {
                            Task { await taskViewModel.addFlag(type: selectedFlag, note: "", to: current) }
                        }
                    }
                }
            }
            .padding(18)
        }
        .background(theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await taskViewModel.loadVehicleExtras(for: current)
        }
    }
}
