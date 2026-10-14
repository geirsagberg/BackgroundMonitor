import SwiftUI

struct IgnoreRulesView: View {
    @ObservedObject var viewModel: JobsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newPattern = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ignore Rules")
                .font(.headline)

            Text("Each rule matches the full command line. Use * to match anything and ? to match one character.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                TextField("*gitstatusd*", text: $newPattern)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit(add)
                    .accessibilityLabel("New ignore rule")

                Button("Add", action: add)
                    .disabled(newPattern.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if viewModel.sortedIgnorePatterns.isEmpty {
                Text("No rules yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                List {
                    ForEach(viewModel.sortedIgnorePatterns, id: \.self) { pattern in
                        HStack(spacing: 8) {
                            Text(pattern)
                                .font(.system(.callout, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(pattern)
                                .textSelection(.enabled)

                            Spacer(minLength: 4)

                            Text(matchText(for: pattern))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .fixedSize()

                            Button {
                                viewModel.removeIgnorePattern(pattern)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                            .help("Remove rule")
                            .accessibilityLabel("Remove rule \(pattern)")
                        }
                    }
                }
                .frame(minHeight: 160)
            }

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 520)
    }

    private func matchText(for pattern: String) -> String {
        let count = viewModel.matchCount(for: pattern)
        return count == 1 ? "1 match" : "\(count) matches"
    }

    private func add() {
        viewModel.addIgnorePattern(newPattern)
        newPattern = ""
    }
}
