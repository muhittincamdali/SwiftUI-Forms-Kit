import SwiftUI

// MARK: - Time Picker Style

/// Display style for time picker
public enum TimePickerStyle {
    case wheel
    case compact
    case inline
    case hourMinute
    case duration
}

// MARK: - Time Picker

/// Time selection field with multiple display styles
public struct FormTimePicker: View {
    @Binding private var time: Date
    
    private let label: String
    private let style: TimePickerStyle
    private let minuteInterval: Int
    private let displayedComponents: DatePickerComponents
    
    @Environment(\.formTheme) private var theme
    @State private var isShowingPicker = false
    
    public init(
        _ label: String,
        time: Binding<Date>,
        style: TimePickerStyle = .compact,
        minuteInterval: Int = 1,
        displayedComponents: DatePickerComponents = .hourAndMinute
    ) {
        self.label = label
        self._time = time
        self.style = style
        self.minuteInterval = minuteInterval
        self.displayedComponents = displayedComponents
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            if !label.isEmpty {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.labelColor)
            }
            
            // Picker based on style
            switch style {
            case .wheel:
                wheelPicker
            case .compact:
                compactPicker
            case .inline:
                inlinePicker
            case .hourMinute:
                hourMinutePicker
            case .duration:
                durationPicker
            }
        }
    }
    
    // MARK: - Wheel Picker
    
    private var wheelPicker: some View {
        DatePicker("", selection: $time, displayedComponents: displayedComponents)
            .datePickerStyle(.wheel)
            .labelsHidden()
    }
    
    // MARK: - Compact Picker
    
    private var compactPicker: some View {
        HStack {
            DatePicker("", selection: $time, displayedComponents: displayedComponents)
                .datePickerStyle(.compact)
                .labelsHidden()
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Inline Picker
    
    private var inlinePicker: some View {
        Button(action: { isShowingPicker.toggle() }) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(theme.primaryColor)
                Text(formattedTime)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isShowingPicker ? 180 : 0))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
        }
        .sheet(isPresented: $isShowingPicker) {
            NavigationStack {
                DatePicker("", selection: $time, displayedComponents: displayedComponents)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .navigationTitle(label)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                isShowingPicker = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - Hour Minute Picker
    
    @State private var selectedHour: Int = 0
    @State private var selectedMinute: Int = 0
    @State private var isPM: Bool = false
    
    private var hourMinutePicker: some View {
        HStack(spacing: 8) {
            // Hour picker
            VStack {
                Text("Hour")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: Binding(
                    get: { Calendar.current.component(.hour, from: time) % 12 },
                    set: { newHour in
                        var components = Calendar.current.dateComponents([.year, .month, .day, .minute], from: time)
                        let isPM = Calendar.current.component(.hour, from: time) >= 12
                        components.hour = isPM ? (newHour == 0 ? 12 : newHour) + 12 : (newHour == 0 ? 12 : newHour)
                        if let newDate = Calendar.current.date(from: components) {
                            time = newDate
                        }
                    }
                )) {
                    ForEach(1...12, id: \.self) { hour in
                        Text("\(hour)")
                            .tag(hour % 12)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60)
            }
            
            Text(":")
                .font(.title2.bold())
                .foregroundColor(.secondary)
            
            // Minute picker
            VStack {
                Text("Min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: Binding(
                    get: { Calendar.current.component(.minute, from: time) },
                    set: { newMinute in
                        var components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: time)
                        components.minute = newMinute
                        if let newDate = Calendar.current.date(from: components) {
                            time = newDate
                        }
                    }
                )) {
                    ForEach(Array(stride(from: 0, to: 60, by: minuteInterval)), id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60)
            }
            
            // AM/PM picker
            VStack {
                Text("")
                    .font(.caption)
                
                Picker("", selection: Binding(
                    get: { Calendar.current.component(.hour, from: time) >= 12 },
                    set: { newIsPM in
                        var components = Calendar.current.dateComponents([.year, .month, .day, .minute], from: time)
                        let currentHour = Calendar.current.component(.hour, from: time)
                        if newIsPM && currentHour < 12 {
                            components.hour = currentHour + 12
                        } else if !newIsPM && currentHour >= 12 {
                            components.hour = currentHour - 12
                        }
                        if let newDate = Calendar.current.date(from: components) {
                            time = newDate
                        }
                    }
                )) {
                    Text("AM").tag(false)
                    Text("PM").tag(true)
                }
                .pickerStyle(.wheel)
                .frame(width: 60)
            }
        }
        .frame(height: 150)
    }
    
    // MARK: - Duration Picker
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    
    private var durationPicker: some View {
        HStack(spacing: 4) {
            // Hours
            VStack {
                Text("Hours")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $hours) {
                    ForEach(0...23, id: \.self) { h in
                        Text("\(h)h").tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
            }
            
            // Minutes
            VStack {
                Text("Minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $minutes) {
                    ForEach(Array(stride(from: 0, to: 60, by: minuteInterval)), id: \.self) { m in
                        Text("\(m)m").tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
            }
        }
        .frame(height: 150)
        .onChange(of: hours) { _, _ in updateTimeFromDuration() }
        .onChange(of: minutes) { _, _ in updateTimeFromDuration() }
    }
    
    // MARK: - Helpers
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    private func updateTimeFromDuration() {
        let totalMinutes = hours * 60 + minutes
        let referenceDate = Calendar.current.startOfDay(for: Date())
        if let newDate = Calendar.current.date(byAdding: .minute, value: totalMinutes, to: referenceDate) {
            time = newDate
        }
    }
}

// MARK: - Time Range Picker

/// Picker for selecting a time range (start - end)
public struct FormTimeRangePicker: View {
    @Binding private var startTime: Date
    @Binding private var endTime: Date
    
    private let label: String
    private let minuteInterval: Int
    
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String,
        startTime: Binding<Date>,
        endTime: Binding<Date>,
        minuteInterval: Int = 15
    ) {
        self.label = label
        self._startTime = startTime
        self._endTime = endTime
        self.minuteInterval = minuteInterval
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.labelColor)
            
            HStack(spacing: 16) {
                // Start time
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                // End time
                VStack(alignment: .leading, spacing: 4) {
                    Text("End")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $endTime, in: startTime..., displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
            
            // Duration display
            Text("Duration: \(durationText)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var durationText: String {
        let interval = endTime.timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 30) {
            FormTimePicker("Alarm", time: .constant(Date()), style: .compact)
            
            FormTimePicker("Meeting Time", time: .constant(Date()), style: .inline)
            
            FormTimePicker("Set Time", time: .constant(Date()), style: .hourMinute)
            
            FormTimeRangePicker(
                "Working Hours",
                startTime: .constant(Date()),
                endTime: .constant(Date().addingTimeInterval(3600 * 8))
            )
        }
        .padding()
    }
}
