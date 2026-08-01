//
//  TimelineView.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import SwiftUI

struct TimelineView: View {
    let memories: [Memory]
    let viewModel: MemoryViewModel
    let depo: Depo
    
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        VStack(spacing: 0) {
            ForEach(memories.sorted(by: { $0.date > $1.date })) { memory in
                HStack(alignment: .top, spacing: 16) {
                    // Timeline Axis
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                            .padding(.top, 24)
                        
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(width: 2)
                    }
                    
                    // Card
                    NavigationLink {
                        MemoryDetailView(
                            memory: memory,
                            viewModel: viewModel,
                            depo: depo
                        )
                    } label: {
                        MemoryCard(memory: memory)
                    }
                    .buttonStyle(.plain)
                    .disabled((memory.unlockDate ?? Date.distantPast) > Date())
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
