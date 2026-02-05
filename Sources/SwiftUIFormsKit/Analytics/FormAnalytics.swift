import SwiftUI
import Combine

// MARK: - Form Event

/// Events tracked during form interaction
public enum FormEvent: Equatable {
    case formStarted(formId: String)
    case formCompleted(formId: String, duration: TimeInterval)
    case formAbandoned(formId: String, lastField: String?, duration: TimeInterval)
    case fieldFocused(fieldId: String)
    case fieldBlurred(fieldId: String, value: String?)
    case fieldChanged(fieldId: String, oldValue: String?, newValue: String?)
    case fieldError(fieldId: String, error: String)
    case fieldErrorCleared(fieldId: String)
    case stepChanged(fromStep: Int, toStep: Int)
    case validationFailed(fieldIds: [String])
    case submitAttempted(success: Bool)
}

// MARK: - Field Metrics

/// Metrics tracked for individual fields
public struct FieldMetrics: Identifiable {
    public let id: String
    public var focusCount: Int = 0
    public var changeCount: Int = 0
    public var errorCount: Int = 0
    public var totalFocusTime: TimeInterval = 0
    public var averageInputLength: Double = 0
    public var correctionCount: Int = 0
    public var firstInteractionTime: Date?
    public var lastInteractionTime: Date?
    
    public init(id: String) {
        self.id = id
    }
    
    /// Field completion rate (0-1)
    public var completionScore: Double {
        guard focusCount > 0 else { return 0 }
        let errorPenalty = Double(errorCount) * 0.1
        let correctionPenalty = Double(correctionCount) * 0.05
        return max(0, min(1, 1.0 - errorPenalty - correctionPenalty))
    }
    
    /// Average time spent on field
    public var averageFocusTime: TimeInterval {
        guard focusCount > 0 else { return 0 }
        return totalFocusTime / Double(focusCount)
    }
}

// MARK: - Form Metrics

/// Aggregated metrics for entire form
public struct FormMetrics {
    public let formId: String
    public var startTime: Date?
    public var endTime: Date?
    public var fieldMetrics: [String: FieldMetrics] = [:]
    public var totalFields: Int = 0
    public var completedFields: Int = 0
    public var submitAttempts: Int = 0
    public var successfulSubmits: Int = 0
    public var stepHistory: [Int] = []
    public var events: [FormEventRecord] = []
    
    public init(formId: String) {
        self.formId = formId
    }
    
    /// Total time spent on form
    public var totalDuration: TimeInterval {
        guard let start = startTime else { return 0 }
        let end = endTime ?? Date()
        return end.timeIntervalSince(start)
    }
    
    /// Form completion percentage
    public var completionRate: Double {
        guard totalFields > 0 else { return 0 }
        return Double(completedFields) / Double(totalFields)
    }
    
    /// Submission success rate
    public var submissionSuccessRate: Double {
        guard submitAttempts > 0 else { return 0 }
        return Double(successfulSubmits) / Double(submitAttempts)
    }
    
    /// Fields with most errors
    public var problematicFields: [String] {
        fieldMetrics.values
            .sorted { $0.errorCount > $1.errorCount }
            .prefix(3)
            .map { $0.id }
    }
    
    /// Average field completion time
    public var averageFieldTime: TimeInterval {
        let totalTime = fieldMetrics.values.reduce(0) { $0 + $1.totalFocusTime }
        let fieldCount = fieldMetrics.count
        return fieldCount > 0 ? totalTime / Double(fieldCount) : 0
    }
}

// MARK: - Event Record

/// Timestamped event record
public struct FormEventRecord: Identifiable {
    public let id = UUID()
    public let event: FormEvent
    public let timestamp: Date
    public let metadata: [String: String]?
    
    public init(event: FormEvent, timestamp: Date = Date(), metadata: [String: String]? = nil) {
        self.event = event
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// MARK: - Analytics Provider Protocol

/// Protocol for analytics backends
public protocol FormAnalyticsProvider {
    func track(_ event: FormEvent, metadata: [String: String]?)
    func flush()
}

// MARK: - Console Analytics Provider

/// Simple console logging provider for development
public class ConsoleAnalyticsProvider: FormAnalyticsProvider {
    public init() {}
    
    public func track(_ event: FormEvent, metadata: [String: String]?) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("📊 [\(timestamp)] Form Event: \(event)")
        if let metadata = metadata {
            print("   Metadata: \(metadata)")
        }
    }
    
    public func flush() {
        print("📊 Analytics flushed")
    }
}

// MARK: - Form Analytics Manager

/// Central manager for form analytics
public class FormAnalytics: ObservableObject {
    public static let shared = FormAnalytics()
    
    @Published public private(set) var metrics: [String: FormMetrics] = [:]
    
    private var providers: [FormAnalyticsProvider] = []
    private var currentFocusField: String?
    private var focusStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    public init() {}
    
    // MARK: - Configuration
    
    /// Add an analytics provider
    public func addProvider(_ provider: FormAnalyticsProvider) {
        providers.append(provider)
    }
    
    /// Remove all providers
    public func removeAllProviders() {
        providers.removeAll()
    }
    
    // MARK: - Event Tracking
    
    /// Track a form event
    public func track(_ event: FormEvent, metadata: [String: String]? = nil) {
        let record = FormEventRecord(event: event, metadata: metadata)
        
        // Update metrics
        updateMetrics(for: event)
        
        // Send to providers
        for provider in providers {
            provider.track(event, metadata: metadata)
        }
        
        // Store event
        if case .formStarted(let formId) = event {
            metrics[formId]?.events.append(record)
        } else {
            // Find form for this event
            for (formId, _) in metrics {
                metrics[formId]?.events.append(record)
            }
        }
    }
    
    // MARK: - Form Lifecycle
    
    /// Start tracking a form
    public func startForm(_ formId: String, totalFields: Int) {
        var formMetrics = FormMetrics(formId: formId)
        formMetrics.startTime = Date()
        formMetrics.totalFields = totalFields
        metrics[formId] = formMetrics
        
        track(.formStarted(formId: formId))
    }
    
    /// Complete a form
    public func completeForm(_ formId: String) {
        guard var formMetrics = metrics[formId] else { return }
        formMetrics.endTime = Date()
        metrics[formId] = formMetrics
        
        track(.formCompleted(formId: formId, duration: formMetrics.totalDuration))
    }
    
    /// Mark form as abandoned
    public func abandonForm(_ formId: String, lastField: String?) {
        guard var formMetrics = metrics[formId] else { return }
        formMetrics.endTime = Date()
        metrics[formId] = formMetrics
        
        track(.formAbandoned(formId: formId, lastField: lastField, duration: formMetrics.totalDuration))
    }
    
    // MARK: - Field Tracking
    
    /// Track field focus
    public func fieldFocused(_ fieldId: String, formId: String) {
        currentFocusField = fieldId
        focusStartTime = Date()
        
        var fieldMetrics = metrics[formId]?.fieldMetrics[fieldId] ?? FieldMetrics(id: fieldId)
        fieldMetrics.focusCount += 1
        if fieldMetrics.firstInteractionTime == nil {
            fieldMetrics.firstInteractionTime = Date()
        }
        fieldMetrics.lastInteractionTime = Date()
        metrics[formId]?.fieldMetrics[fieldId] = fieldMetrics
        
        track(.fieldFocused(fieldId: fieldId))
    }
    
    /// Track field blur
    public func fieldBlurred(_ fieldId: String, formId: String, value: String?) {
        if let startTime = focusStartTime, currentFocusField == fieldId {
            let focusTime = Date().timeIntervalSince(startTime)
            metrics[formId]?.fieldMetrics[fieldId]?.totalFocusTime += focusTime
        }
        
        currentFocusField = nil
        focusStartTime = nil
        
        track(.fieldBlurred(fieldId: fieldId, value: value))
    }
    
    /// Track field value change
    public func fieldChanged(_ fieldId: String, formId: String, oldValue: String?, newValue: String?) {
        var fieldMetrics = metrics[formId]?.fieldMetrics[fieldId] ?? FieldMetrics(id: fieldId)
        fieldMetrics.changeCount += 1
        
        // Track corrections (shorter than previous)
        if let old = oldValue, let new = newValue, new.count < old.count {
            fieldMetrics.correctionCount += 1
        }
        
        // Update average input length
        if let new = newValue {
            let totalLength = fieldMetrics.averageInputLength * Double(fieldMetrics.changeCount - 1) + Double(new.count)
            fieldMetrics.averageInputLength = totalLength / Double(fieldMetrics.changeCount)
        }
        
        fieldMetrics.lastInteractionTime = Date()
        metrics[formId]?.fieldMetrics[fieldId] = fieldMetrics
        
        track(.fieldChanged(fieldId: fieldId, oldValue: oldValue, newValue: newValue))
    }
    
    /// Track field error
    public func fieldError(_ fieldId: String, formId: String, error: String) {
        metrics[formId]?.fieldMetrics[fieldId]?.errorCount += 1
        track(.fieldError(fieldId: fieldId, error: error))
    }
    
    /// Track error cleared
    public func fieldErrorCleared(_ fieldId: String, formId: String) {
        track(.fieldErrorCleared(fieldId: fieldId))
    }
    
    /// Track field completion
    public func fieldCompleted(_ fieldId: String, formId: String) {
        metrics[formId]?.completedFields += 1
    }
    
    // MARK: - Step Tracking
    
    /// Track step change in multi-step form
    public func stepChanged(formId: String, from: Int, to: Int) {
        metrics[formId]?.stepHistory.append(to)
        track(.stepChanged(fromStep: from, toStep: to))
    }
    
    // MARK: - Submission Tracking
    
    /// Track submit attempt
    public func submitAttempted(formId: String, success: Bool) {
        metrics[formId]?.submitAttempts += 1
        if success {
            metrics[formId]?.successfulSubmits += 1
        }
        track(.submitAttempted(success: success))
    }
    
    // MARK: - Metrics Retrieval
    
    /// Get metrics for a specific form
    public func getMetrics(for formId: String) -> FormMetrics? {
        metrics[formId]
    }
    
    /// Get all field metrics for a form
    public func getFieldMetrics(for formId: String) -> [FieldMetrics] {
        Array(metrics[formId]?.fieldMetrics.values ?? [])
    }
    
    /// Export metrics as JSON
    public func exportMetrics(for formId: String) -> String? {
        guard let formMetrics = metrics[formId] else { return nil }
        
        var dict: [String: Any] = [
            "formId": formMetrics.formId,
            "totalDuration": formMetrics.totalDuration,
            "completionRate": formMetrics.completionRate,
            "submitAttempts": formMetrics.submitAttempts,
            "successfulSubmits": formMetrics.successfulSubmits,
            "problematicFields": formMetrics.problematicFields,
            "averageFieldTime": formMetrics.averageFieldTime
        ]
        
        var fieldStats: [[String: Any]] = []
        for (_, field) in formMetrics.fieldMetrics {
            fieldStats.append([
                "id": field.id,
                "focusCount": field.focusCount,
                "changeCount": field.changeCount,
                "errorCount": field.errorCount,
                "totalFocusTime": field.totalFocusTime,
                "completionScore": field.completionScore
            ])
        }
        dict["fields"] = fieldStats
        
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return nil
    }
    
    /// Clear metrics for a form
    public func clearMetrics(for formId: String) {
        metrics.removeValue(forKey: formId)
    }
    
    /// Flush all providers
    public func flush() {
        for provider in providers {
            provider.flush()
        }
    }
    
    // MARK: - Private
    
    private func updateMetrics(for event: FormEvent) {
        // Additional metric updates based on event type
    }
}

// MARK: - Analytics View Modifier

/// View modifier that automatically tracks form analytics
public struct FormAnalyticsModifier: ViewModifier {
    let formId: String
    let totalFields: Int
    let analytics: FormAnalytics
    
    @State private var hasStarted = false
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasStarted {
                    analytics.startForm(formId, totalFields: totalFields)
                    hasStarted = true
                }
            }
            .onDisappear {
                let metrics = analytics.getMetrics(for: formId)
                if metrics?.completionRate ?? 0 < 1.0 {
                    analytics.abandonForm(formId, lastField: nil)
                }
            }
    }
}

public extension View {
    /// Track analytics for this form
    func trackAnalytics(
        formId: String,
        totalFields: Int,
        analytics: FormAnalytics = .shared
    ) -> some View {
        modifier(FormAnalyticsModifier(formId: formId, totalFields: totalFields, analytics: analytics))
    }
}

// MARK: - Analytics Dashboard View

/// Visual dashboard for form analytics
public struct FormAnalyticsDashboard: View {
    let formId: String
    @ObservedObject var analytics: FormAnalytics
    
    public init(formId: String, analytics: FormAnalytics = .shared) {
        self.formId = formId
        self.analytics = analytics
    }
    
    private var metrics: FormMetrics? {
        analytics.getMetrics(for: formId)
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let metrics = metrics {
                    // Overview
                    overviewSection(metrics)
                    
                    // Field breakdown
                    fieldBreakdownSection(metrics)
                    
                    // Problematic fields
                    if !metrics.problematicFields.isEmpty {
                        problematicFieldsSection(metrics)
                    }
                } else {
                    Text("No analytics data available")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Form Analytics")
    }
    
    private func overviewSection(_ metrics: FormMetrics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Completion",
                    value: String(format: "%.0f%%", metrics.completionRate * 100),
                    icon: "checkmark.circle"
                )
                
                StatCard(
                    title: "Duration",
                    value: formatDuration(metrics.totalDuration),
                    icon: "clock"
                )
                
                StatCard(
                    title: "Submit Rate",
                    value: String(format: "%.0f%%", metrics.submissionSuccessRate * 100),
                    icon: "paperplane"
                )
                
                StatCard(
                    title: "Avg Field Time",
                    value: formatDuration(metrics.averageFieldTime),
                    icon: "timer"
                )
            }
        }
    }
    
    private func fieldBreakdownSection(_ metrics: FormMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Field Breakdown")
                .font(.headline)
            
            ForEach(Array(metrics.fieldMetrics.values)) { field in
                HStack {
                    VStack(alignment: .leading) {
                        Text(field.id)
                            .font(.subheadline.weight(.medium))
                        Text("\(field.focusCount) focus · \(field.changeCount) changes · \(field.errorCount) errors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Completion score indicator
                    Circle()
                        .fill(scoreColor(field.completionScore))
                        .frame(width: 12, height: 12)
                }
                .padding(.vertical, 8)
                
                Divider()
            }
        }
    }
    
    private func problematicFieldsSection(_ metrics: FormMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ Fields Needing Attention")
                .font(.headline)
            
            ForEach(metrics.problematicFields, id: \.self) { fieldId in
                if let field = metrics.fieldMetrics[fieldId] {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(fieldId)
                        Spacer()
                        Text("\(field.errorCount) errors")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.0fs", duration)
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        if score >= 0.5 { return .yellow }
        return .red
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FormAnalyticsDashboard(formId: "test-form")
    }
}
