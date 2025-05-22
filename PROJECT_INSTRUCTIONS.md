# Cash In-Out Mobile Application - Project Instructions

## Project Overview
"Cash In-Out" is a mobile application tailored for users in the textile market to efficiently manage their client information and payment transactions. The app enables users to record client details, track payments (including installment-based payments), and view real-time updates on received amounts and outstanding balances. This application aims to simplify financial record-keeping, improve transparency, and enhance client relationship management for textile businesses.

## Technology Stack
- **Frontend:** Flutter (Dart)
- **Backend:** PHP + MySQL (API endpoints)
- **Communication:** RESTful API using HTTP requests
- **Authentication:** Firebase Authentication (planned/integrated)
- **Other:** Payment and transaction models, installment tracking

## Frontend-Backend Connection
- The Flutter frontend uses a `PaymentService` class to interact with backend API endpoints.
- `PaymentService` handles HTTP requests for creating payments, fetching payments, recording transactions, adding installments, and updating payment statuses.
- The backend API base URL is configured in `lib/main.dart` and passed to `PaymentService`.
- Screens such as `TransactionsScreen` use `PaymentService` to fetch and display real transaction data.
- The app uses a modular screen structure with `HomeScreen` managing navigation between `DashboardScreen`, `TransactionsScreen`, and `ProfileScreen`.
- Backend responses are parsed into Dart models (`Payment`, `Transaction`, `Installment`) for use in the UI.

## Key Modules and Their Roles
- **main.dart:** App entry point, sets up `PaymentService` and navigation.
- **HomeScreen:** Manages bottom navigation and passes `PaymentService` to child screens.
- **DashboardScreen:** Displays balance and recent transactions (currently with placeholder data).
- **TransactionsScreen:** Fetches and displays transaction list from backend.
- **ProfileScreen:** Displays user profile information (static data currently).
- **PaymentService:** Handles all backend API calls and data serialization.
- **Models:** Define data structures for payments, transactions, and installments.

## Running the App
1. Ensure backend API is running and accessible. Update the `baseUrl` in `lib/main.dart` accordingly.
2. Install Flutter SDK and dependencies.
3. Run `flutter pub get` to fetch packages.
4. Use `flutter run` to launch the app on an emulator or physical device.
5. Navigate through the app to view dashboard, transactions, and profile screens.
6. Transactions screen will fetch real data from backend via API.

## Testing and Enhancements
- Add unit and widget tests for frontend components.
- Implement real backend integration for dashboard and profile screens.
- Add authentication flows using Firebase.
- Improve UI/UX based on user feedback.
- Optimize network error handling and loading states.

## Contact and Support
For any issues or support, contact:
- Phone: +91 75675 83505
- Email: support@agevole.in
- Website: www.agevole.in

---

This document provides a comprehensive overview and instructions for the "Cash In-Out" mobile application project. Follow the steps to set up, run, and extend the app effectively.
