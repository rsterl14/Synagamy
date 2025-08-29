//
//  NotificationManager.swift
//  Synagamy3.0
//
//  Local notification management for cycle tracking and reminders.
//

import SwiftUI
import UserNotifications

@MainActor
class NotificationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var scheduledNotifications: [ScheduledNotification] = []
    @Published var enableCycleReminders = false {
        didSet {
            if enableCycleReminders {
                Task {
                    _ = await requestPermission()
                }
            } else {
                cancelAllCycleNotifications()
            }
        }
    }
    
    private let center = UNUserNotificationCenter.current()
    
    struct ScheduledNotification: Identifiable {
        let id: String
        let title: String
        let body: String
        let scheduledDate: Date
        let type: NotificationType
        
        enum NotificationType {
            case fertileWindow
            case ovulationApproaching
            case periodReminder
            case medicationReminder
            case appointmentReminder
            
            var categoryIdentifier: String {
                switch self {
                case .fertileWindow: return "FERTILE_WINDOW"
                case .ovulationApproaching: return "OVULATION"
                case .periodReminder: return "PERIOD"
                case .medicationReminder: return "MEDICATION"
                case .appointmentReminder: return "APPOINTMENT"
                }
            }
            
            var icon: String {
                switch self {
                case .fertileWindow: return "heart.circle.fill"
                case .ovulationApproaching: return "target"
                case .periodReminder: return "calendar"
                case .medicationReminder: return "pills"
                case .appointmentReminder: return "stethoscope"
                }
            }
        }
    }
    
    override init() {
        super.init()
        center.delegate = self
        setupNotificationCategories()
        Task {
            await updateAuthorizationStatus()
            await loadScheduledNotifications()
        }
    }
    
    // MARK: - Permission Management
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await updateAuthorizationStatus()
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    private func updateAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    // MARK: - Cycle Notifications
    
    func scheduleNotificationsForCycle(_ cycle: MenstrualCycle) async {
        guard authorizationStatus == .authorized else { return }
        
        // Cancel existing cycle notifications
        cancelAllCycleNotifications()
        
        let calendar = Calendar.current
        let now = Date()
        
        // Fertile window start (5 days before ovulation)
        let fertileStart = cycle.fertileWindowStart
        if fertileStart > now {
            await scheduleNotification(
                id: "fertile_start",
                title: "Fertile Window Begins",
                body: "Your fertile window starts today. This is a great time to focus on conception.",
                date: fertileStart,
                type: .fertileWindow
            )
        }
        
        // Ovulation day
        let ovulationDate = cycle.ovulationDate
        if ovulationDate > now {
            // Day before ovulation
            if let dayBefore = calendar.date(byAdding: .day, value: -1, to: ovulationDate) {
                await scheduleNotification(
                    id: "ovulation_tomorrow",
                    title: "Ovulation Tomorrow",
                    body: "Peak fertility expected tomorrow. Consider timing intercourse today and tomorrow.",
                    date: dayBefore,
                    type: .ovulationApproaching
                )
            }
            
            // Ovulation day
            await scheduleNotification(
                id: "ovulation_day",
                title: "Peak Fertility Today",
                body: "Today is your predicted ovulation day - peak fertility window!",
                date: ovulationDate,
                type: .ovulationApproaching
            )
        }
        
        // Next period reminder
        let nextPeriod = cycle.nextPeriodDate
        if let reminderDate = calendar.date(byAdding: .day, value: -2, to: nextPeriod) {
            if reminderDate > now {
                await scheduleNotification(
                    id: "period_reminder",
                    title: "Period Expected Soon",
                    body: "Your next period is expected in 2 days. Track any symptoms in the app.",
                    date: reminderDate,
                    type: .periodReminder
                )
            }
        }
        
        await loadScheduledNotifications()
    }
    
    private func scheduleNotification(
        id: String,
        title: String,
        body: String,
        date: Date,
        type: ScheduledNotification.NotificationType
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = type.categoryIdentifier
        
        // Add custom data
        content.userInfo = [
            "type": type.categoryIdentifier,
            "scheduledDate": date.timeIntervalSince1970
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            print("Scheduled notification: \(title) for \(date)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - Medication Reminders
    
    func scheduleMedicationReminder(
        medicationName: String,
        time: Date,
        frequency: MedicationFrequency
    ) async {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "Time to take your \(medicationName)"
        content.sound = .default
        content.categoryIdentifier = ScheduledNotification.NotificationType.medicationReminder.categoryIdentifier
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger: UNNotificationTrigger
        
        switch frequency {
        case .daily:
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .weekly:
            let weeklyComponents = calendar.dateComponents([.weekday, .hour, .minute], from: time)
            trigger = UNCalendarNotificationTrigger(dateMatching: weeklyComponents, repeats: true)
        case .asNeeded:
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        
        let id = "medication_\(medicationName.lowercased().replacingOccurrences(of: " ", with: "_"))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule medication reminder: \(error)")
        }
    }
    
    enum MedicationFrequency {
        case daily, weekly, asNeeded
    }
    
    // MARK: - Appointment Reminders
    
    func scheduleAppointmentReminder(
        title: String,
        location: String?,
        date: Date
    ) async {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Appointment Reminder"
        content.body = title + (location.map { " at \($0)" } ?? "")
        content.sound = .default
        content.categoryIdentifier = ScheduledNotification.NotificationType.appointmentReminder.categoryIdentifier
        
        // Schedule 24 hours and 1 hour before
        let calendar = Calendar.current
        
        // 24 hours before
        if let dayBefore = calendar.date(byAdding: .day, value: -1, to: date) {
            let dayBeforeComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dayBefore)
            let dayBeforeTrigger = UNCalendarNotificationTrigger(dateMatching: dayBeforeComponents, repeats: false)
            
            let dayBeforeRequest = UNNotificationRequest(
                identifier: "appointment_24h_\(date.timeIntervalSince1970)",
                content: content,
                trigger: dayBeforeTrigger
            )
            
            try? await center.add(dayBeforeRequest)
        }
        
        // 1 hour before
        if let hourBefore = calendar.date(byAdding: .hour, value: -1, to: date) {
            let hourBeforeContent = UNMutableNotificationContent()
            hourBeforeContent.title = "Appointment in 1 Hour"
            hourBeforeContent.body = title + (location.map { " at \($0)" } ?? "")
            hourBeforeContent.sound = .default
            hourBeforeContent.categoryIdentifier = ScheduledNotification.NotificationType.appointmentReminder.categoryIdentifier
            
            let hourBeforeComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: hourBefore)
            let hourBeforeTrigger = UNCalendarNotificationTrigger(dateMatching: hourBeforeComponents, repeats: false)
            
            let hourBeforeRequest = UNNotificationRequest(
                identifier: "appointment_1h_\(date.timeIntervalSince1970)",
                content: hourBeforeContent,
                trigger: hourBeforeTrigger
            )
            
            try? await center.add(hourBeforeRequest)
        }
    }
    
    // MARK: - Management
    
    private func loadScheduledNotifications() async {
        let pendingRequests = await center.pendingNotificationRequests()
        
        scheduledNotifications = pendingRequests.compactMap { request in
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                  let date = Calendar.current.nextDate(
                    after: Date(),
                    matching: trigger.dateComponents,
                    matchingPolicy: .nextTime
                  ),
                  let typeString = request.content.userInfo["type"] as? String else {
                return nil
            }
            
            let type: ScheduledNotification.NotificationType
            switch typeString {
            case "FERTILE_WINDOW": type = .fertileWindow
            case "OVULATION": type = .ovulationApproaching
            case "PERIOD": type = .periodReminder
            case "MEDICATION": type = .medicationReminder
            case "APPOINTMENT": type = .appointmentReminder
            default: return nil
            }
            
            return ScheduledNotification(
                id: request.identifier,
                title: request.content.title,
                body: request.content.body,
                scheduledDate: date,
                type: type
            )
        }
    }
    
    func cancelNotification(_ id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        scheduledNotifications.removeAll { $0.id == id }
    }
    
    func cancelAllCycleNotifications() {
        let cycleNotificationIds = ["fertile_start", "ovulation_tomorrow", "ovulation_day", "period_reminder"]
        center.removePendingNotificationRequests(withIdentifiers: cycleNotificationIds)
        scheduledNotifications.removeAll { cycleNotificationIds.contains($0.id) }
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        scheduledNotifications.removeAll()
    }
    
    // MARK: - Notification Categories
    
    private func setupNotificationCategories() {
        let categories: [UNNotificationCategory] = [
            // Fertile window actions
            UNNotificationCategory(
                identifier: "FERTILE_WINDOW",
                actions: [
                    UNNotificationAction(
                        identifier: "VIEW_CYCLE",
                        title: "View Cycle",
                        options: [.foreground]
                    ),
                    UNNotificationAction(
                        identifier: "LOG_SYMPTOMS",
                        title: "Log Symptoms",
                        options: [.foreground]
                    )
                ],
                intentIdentifiers: []
            ),
            
            // Ovulation actions
            UNNotificationCategory(
                identifier: "OVULATION",
                actions: [
                    UNNotificationAction(
                        identifier: "VIEW_RECOMMENDATIONS",
                        title: "View Tips",
                        options: [.foreground]
                    )
                ],
                intentIdentifiers: []
            ),
            
            // Medication actions
            UNNotificationCategory(
                identifier: "MEDICATION",
                actions: [
                    UNNotificationAction(
                        identifier: "MARK_TAKEN",
                        title: "Taken",
                        options: []
                    ),
                    UNNotificationAction(
                        identifier: "SNOOZE",
                        title: "Remind Later",
                        options: []
                    )
                ],
                intentIdentifiers: []
            )
        ]
        
        center.setNotificationCategories(Set(categories))
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.actionIdentifier
        
        switch identifier {
        case "VIEW_CYCLE":
            // Navigate to cycle view
            NotificationCenter.default.post(name: .navigateToCycle, object: nil)
        case "VIEW_RECOMMENDATIONS":
            // Navigate to recommendations
            NotificationCenter.default.post(name: .navigateToRecommendations, object: nil)
        case "MARK_TAKEN":
            // Mark medication as taken
            // Could integrate with health data
            break
        case "SNOOZE":
            // Reschedule notification for later
            break
        default:
            break
        }
        
        completionHandler()
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToCycle = Notification.Name("navigateToCycle")
    static let navigateToRecommendations = Notification.Name("navigateToRecommendations")
}