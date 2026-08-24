import SwiftUI

struct StatsView: View {
    @ObservedObject var historyStore: FocusHistoryStore
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Text("Focus Statistics")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 2)
            
            // Streak & Today Cards
            HStack(spacing: 10) {
                StatCard(
                    title: "Streak",
                    value: "\(historyStore.currentStreak)d",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Today",
                    value: "\(historyStore.todayFocusMinutes)m",
                    icon: "clock.fill",
                    color: Color(red: 76/255, green: 217/255, blue: 100/255)
                )
            }
            
            // History List Header
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            .padding(.top, 4)
            
            // Scrollable History
            ScrollView {
                VStack(spacing: 6) {
                    if historyStore.sortedRecords.isEmpty {
                        Text("No completed sessions yet.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.top, 20)
                    } else {
                        ForEach(historyStore.sortedRecords) { record in
                            HStack {
                                Text(record.dateString)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                Text("\(record.completedSessions) sessions")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("\(record.totalFocusSeconds / 60)m")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(red: 76/255, green: 217/255, blue: 100/255))
                                    .frame(width: 35, alignment: .trailing)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .frame(maxHeight: 120)
        }
        .padding(14)
        .frame(width: 200)
        .background(Color(red: 20/255, green: 22/255, blue: 26/255))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .cornerRadius(8)
    }
}//
//  StatsView.swift
//  PomoFloating
//
//  Created by Stuart McDonnell on 16/8/2026.
//

