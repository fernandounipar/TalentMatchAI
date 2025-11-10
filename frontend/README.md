Frontend TalentMatchIA (Flutter Web)

Run locally

- Ensure backend is running on `http://localhost:4000`.
- Run Flutter Web with API base configured and mocks disabled:
  - `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000 --dart-define=USE_MOCK_API=false`

Notes

- The app requires authentication. Login via the user created on `POST /api/auth/registrar`.
- All lists and actions call the backend; there is no mock fallback when `USE_MOCK_API=false`.

