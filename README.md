# 📌 BẮT BUỘC

- Đây là một dự án **PlatformIO**, để xây dựng nó trong **VSCode** cần cài đặt extension **PlatformIO IDE**.

---

# 🚀 CHẠY TRÊN MÔ PHỎNG WOKWI

1. Cài Extension **"Wokwi Simulator"**  
   ➜ Nhấn `F1` → chọn `Wokwi: request a new license`.

2. Build dự án:  
   ➜ Nhấn `F1` → `PlatformIO: New terminal`  
   ➜ Nếu chưa ở trong thư mục `esp32` thì chạy:

   ```bash
   cd esp32
   ```

   ➜ Sau đó chạy lệnh:

   ```bash
   pio run -e wokwi
   ```

3. Chạy mô phỏng:  
   ➜ Double click vào file `diagram.json` rồi nhấn nút **Run**.

4. Điều khiển khóa qua ứng dụng **Flutter** với tài khoản:
   ```
   Email: wokwi@simulator.com
   Mật khẩu: 12345678
   ```
   (hoặc tài khoản đã có liên kết với khóa có ID `WokwiBoard01`)

---

# 🔌 NẠP CODE CHO BOARD THẬT

**(Kit Wifi BLE ESP32 NodeMCU-32S CH340 Ai-Thinker)**

1. Tải và cài đặt driver:  
   [https://www.wch.cn/download/file?id=65](https://www.wch.cn/download/file?id=65)

2. Nạp code:  
   ➜ Chạy lệnh `pio run -e nodemcu-32s -t upload`

---

# 🛠️ CÁCH THAY ĐỔI SƠ ĐỒ LINH KIỆN TRONG MÔ PHỎNG WOKWI

- Chỉnh sửa sơ đồ trên [https://wokwi.com](https://wokwi.com)
- Copy nội dung file `diagram.json`
- Trong VSCode:
  - Click phải vào `diagram.json` → chọn `Open with...` → `Text editor`
  - Dán nội dung đã copy vào.

---

# 🛠️ Cách phát hành một phiên bản Firmware mới

- Tạo một tag mới với tag name bắt đầu bằng "v"
- Push tag lên nhánh main
- Sau một thời gian ngắn, thông báo về phiên bản mới sẽ được gửi đến người dùng và sẵn sàng để được tải về.
- Có thể xem qua các phiên bản đã phát hành [tại đây](https://github.com/TDeV-VN/IOT-SmartLock-Firmware/tree/firmware)
- Ví dụ:
  `git tag v1.2.3`
  `git push origin v1.2.3`

---

# ℹ️ MỘT SỐ THÔNG TIN KHÁC

- Tài khoản truy cập **Firebase**, **HiveMQ**, **Render.com**:
  ```
  Email: slocktdtu@gmail.com
  Mật khẩu: #12345678SLock
  ```
- Trong trường hợp hỏng dữ liệu ở **Firebase Realtime Database**:
  ```
  - Xóa toàn bộ dữ liệu bằng **Firbase console**
  - Nhập lại dữ liệu mới từ file `BaseData.json`
  ```
  # LecturerSupportSystem

Professional Lecturer Support System — a C# application (with T-SQL scripts) designed to help lecturers and academic staff manage courses, schedules, attendance, grading, resources, and communications. This single README provides a concise project overview plus a detailed Functions & Tasks backlog you can use to onboard contributors, create issues, and drive development.

[![Language](https://img.shields.io/badge/Language-C%23-blue)]()
[![DB](https://img.shields.io/badge/Database-SQL%20Server-brightgreen)]()
[![Status](https://img.shields.io/badge/Status-Active-green)]()

---

## Professional overview

LecturerSupportSystem centralizes common academic workflows for lecturers and course administrators: course & section management, scheduling, attendance tracking, assignment & grade recording, resource distribution (slides, readings), and notifications to students. The project is implemented mainly in C# with T-SQL used for schema and helper scripts. It is suitable for small-to-medium institutions, faculty teams, or as a reference implementation to integrate with institutional systems (LMS / SIS).

Core goals:
- Make daily lecturer tasks easier and more reliable (attendance, grading, announcements).
- Keep the architecture modular: domain logic, persistence (DAL), web/API or desktop UI adapters.
- Provide clear DB scripts and a single, easy-to-change DatabaseAccess entry point for local setup.
- Support testable services and CI-friendly .NET build flows.

Note: If you run the repository locally, check the DAL/DatabaseAccess (or similar) file for the connection string placeholder (often near the top / around line ~15) and update the Data Source to match your SQL Server instance.

---

## Key features

- Course, section, and syllabus management
- Timetabling & schedule management with conflict detection
- Attendance recording (manual, QR/scan, or imported)
- Assignment and grade management with gradebook and GPA calculations
- Student lists, enrollment views, and exportable class rosters
- Resource management (upload/download lecture materials)
- Notifications: email and in-app announcements
- Reporting: attendance reports, grade distributions, missing assignments
- RBAC: Admin, Lecturer, TA, Student roles and permissions
- Database-first scripts and DAL wrapper for SQL Server
- Unit & integration tests suitable for CI

---

## Technology & recommended stack

- Language: C# (~96% of repo)
- Data scripts: T-SQL (~4% of repo)
- .NET: .NET 6 or .NET 7 recommended (confirm repo target)
- Data store: Microsoft SQL Server (Express/Developer / Docker)
- Data access: ADO.NET DAL in repo; consider EF Core or Dapper migration if desired
- Build & run: dotnet CLI (dotnet restore, build, test, run)
- Testing: xUnit / NUnit / MSTest as used in repo
- Optional: Docker for SQL Server and local dev environment

---

## System requirements

- .NET SDK 6.0 or 7.0 (matching the project)
- SQL Server (Express, Developer, or Docker image)
- Optional: Visual Studio / VS Code with C# extension
- Docker (recommended for reproducible local DB)

---

## Quick start — provision DB and run

1. Provision the database
   - Run the provided T-SQL schema and seed scripts (if present) via SSMS or sqlcmd:
     ```bash
     sqlcmd -S "YOUR_SERVER_NAME" -i ./database/01_schema.sql
     sqlcmd -S "YOUR_SERVER_NAME" -i ./database/02_seed.sql
     ```
   - If no scripts exist, create an empty DB and allow the app to initialize or provide migration steps.

2. Update the connection string (DatabaseAccess / DAL)
   - Open the DAL file (commonly at src/.../DAL/DatabaseAccess.cs).
   - Replace the Data Source placeholder (often around line ~15) with your SQL Server name:
     ```csharp
     // Example: DatabaseAccess.cs
     private const string ConnectionString = "Data Source=YOUR_SERVER_NAME;Initial Catalog=LecturerSupportDB;Integrated Security=True;";
     ```
   - Preferred approach: move this to appsettings.json and read via IConfiguration.

3. Build & run the app
   ```bash
   dotnet restore
   dotnet build
   dotnet run --project src/LecturerSupportSystem.App/LecturerSupportSystem.App.csproj
   ```
   - Adjust project path to match the repository layout.

4. Run tests
   ```bash
   dotnet test
   ```

5. Docker (SQL Server example)
   ```bash
   docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourPassword123" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-latest
   ```

---

## Connection string examples

- Integrated Security (Windows auth)
  ```
  Data Source=YOUR_SERVER_NAME;Initial Catalog=LecturerSupportDB;Integrated Security=True;
  ```
- SQL Authentication
  ```
  Data Source=YOUR_SERVER_NAME;Initial Catalog=LecturerSupportDB;User ID=sa;Password=YourPassword123;
  ```
- LocalDB (developer convenience)
  ```
  Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=LecturerSupportDB;Integrated Security=True;
  ```

If the repo contains a hardcoded string in DatabaseAccess.cs (line ~15), update it and consider externalizing to appsettings.json or environment variables before committing.

---

## Architecture (high level)

- Domain: Course, Section, User, Enrollment, Attendance, Assignment, Grade
- Services: business logic (scheduling, grade calculations, attendance policies)
- Persistence: DAL/Repository layer (ADO.NET or EF Core)
- API/UI: Web API controllers or desktop/web UI adapters
- Background jobs: scheduled tasks for nightly reports, notifications, grade aggregation
- Tests: unit tests for services and integration tests against a test DB

---

## Functions & Tasks (combined: use this as the implementation backlog)

This section lists core functions and a prioritized backlog (P0/P1/P2). Each function includes acceptance criteria and test guidance so items can be converted directly into issues.

Priority legend:
- P0 — must have baseline features and DB connectivity
- P1 — important usability, reliability and integrations
- P2 — enhancements and optional features

### Core functions

1. Course & Section Management
   - Purpose: CRUD for courses and sections, including syllabi and capacity.
   - Acceptance:
     - CRUD endpoints/UI components work with validation
     - Section capacity warnings on enrollment
   - Tests: service and controller/unit tests

2. Scheduling & Timetabling
   - Purpose: Create schedules, detect conflicts (lecturer or room double-booking).
   - Acceptance:
     - Reject conflicting schedules with informative errors
     - Support recurring sessions (weekly, custom)
   - Tests: unit tests for conflict detection

3. Enrollment & Rosters
   - Purpose: Manage student enrollment lists, waitlists.
   - Acceptance:
     - Enroll/withdraw workflows; waitlist promotion when seats free
     - Exportable class rosters (CSV)
   - Tests: integration tests for enrollment flows

4. Attendance Tracking
   - Purpose: Record attendance per session via UI or import (CSV/scan).
   - Acceptance:
     - Attendance entries tied to sessions and students; reports aggregable by date range
   - Tests: unit and integration tests for import and report aggregation

5. Assignments & Grading
   - Purpose: Create assignments, accept submissions (link/file), grade entries, and compute grades/GPA.
   - Acceptance:
     - Gradebook stores grades; grade calculations per course are correct and tested
   - Tests: grade calculation unit tests including edge cases (excused/incomplete)

6. Resource Management
   - Purpose: Upload and share lecture materials, readings, and links.
   - Acceptance:
     - Secure file upload and role-based access (only course members can access)
   - Tests: integration tests for storage and permission checks

7. Notifications & Announcements
   - Purpose: Email/in-app announcements to enrolled students and staff.
   - Acceptance:
     - Configurable templates; mockable mail adapter for tests
   - Tests: mock mail adapter tests

8. Reports & Exports
   - Purpose: Attendance, grade distributions, and teaching load reports.
   - Acceptance:
     - Exports (CSV/PDF) match DB data and filters
   - Tests: report correctness tests

9. Roles & Access Control (RBAC)
   - Purpose: Enforce Admin, Lecturer, TA, Student permissions.
   - Acceptance:
     - Role checks enforced on sensitive endpoints/actions
   - Tests: security integration tests

10. Auditing & Activity Logs
    - Purpose: Record who changed critical records and when.
    - Acceptance:
      - Audit entries for create/update/delete; searchable by admin
    - Tests: audit verification in integration tests

11. Background Jobs & Scheduling
    - Purpose: Nightly reports, email reminders for missing grades/attendance, waitlist promotions.
    - Acceptance:
      - Jobs are idempotent and observable; provide health endpoints/logs
    - Tests: job integration tests

---

### Suggested data model (high level)

- User { Id, Username, Email, DisplayName, Roles[], CreatedAt, UpdatedAt }
- Course { Id, Code, Title, Description, Credits, SyllabusUrl, CreatedAt }
- Section { Id, CourseId, Term, LecturerUserId, Room, Capacity, Schedule[] }
- Enrollment { Id, StudentId, SectionId, Status (enrolled/waitlisted/withdrawn), EnrolledAt }
- Session { Id, SectionId, StartAt, EndAt, Location, Topic }
- Attendance { Id, SessionId, StudentId, Status (present/absent/late), RecordedAt }
- Assignment { Id, SectionId, Title, Description, DueAt, MaxPoints }
- Submission { Id, AssignmentId, StudentId, FileUrl, SubmittedAt, GradeId? }
- Grade { Id, SubmissionId?, EnrollmentId?, Points, Scale, RecordedBy, RecordedAt }
- Audit { Id, EntityType, EntityId, Action, ActorUserId, Details, Timestamp }

---

### Prioritized implementation tasks (backlog)

P0 — Core (must have)
- Task: Externalize DB connection string (move hardcoded DatabaseAccess.cs Data Source to appsettings.json / env vars)
  - Complexity: low
  - Tests: app connects using configured connection string
- Task: Add/verify T-SQL schema and seed scripts
  - Complexity: low
  - Tests: scripts create schema and seed sample data
- Task: Implement Course & Section CRUD + Schedule conflict detection
  - Complexity: medium
  - Tests: unit & integration tests for CRUD and conflict scenarios
- Task: Implement Enrollment & Rosters (with waitlist)
  - Complexity: medium
  - Tests: integration tests for enrollment and waitlist promotion
- Task: Implement Attendance recording and session listing
  - Complexity: medium
  - Tests: unit tests for recording and aggregated attendance reports

P1 — Important
- Task: Assignment & Gradebook with grade calculations and export
  - Complexity: medium
  - Tests: grade calculation tests and export validation
- Task: Notification system (email adapter + templates)
  - Complexity: medium
- Task: Add authentication & RBAC enforcement
  - Complexity: medium
  - Tests: security integration tests
- Task: CI pipeline (GitHub Actions) with build, test, and optional integration tests using Dockerized SQL Server
  - Complexity: low-medium

P2 — Enhancements
- Task: Migrate DAL to EF Core or add Dapper as option
  - Complexity: medium-high
- Task: Add QR/scan-based attendance capture and mobile-friendly endpoints
  - Complexity: medium
- Task: Add advanced timetable optimization / auto-scheduler
  - Complexity: high
- Task: Add monitoring (Prometheus) and dashboards (Grafana)
  - Complexity: medium

---

## Example API sketches / UI flows

- GET /api/courses
- POST /api/courses
- GET /api/sections/{id}/schedule
- POST /api/sections/{id}/enroll
- GET /api/sections/{id}/roster/export?format=csv
- POST /api/sessions/{id}/attendance  (bulk upload)
- POST /api/assignments/{id}/grade

---

## Tests & CI

- Run unit tests:
  ```bash
  dotnet test
  ```
- Recommended CI (GitHub Actions) steps:
  - Restore & build
  - Run linters and unit tests
  - Startup SQL Server service (Docker) for integration tests
  - Run integration tests against DB

---

## Docker (dev stack example)

docker-compose.yml:
```yaml
version: "3.8"
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2019-latest
    environment:
      SA_PASSWORD: "YourPassword123"
      ACCEPT_EULA: "Y"
    ports:
      - "1433:1433"
    volumes:
      - sql-data:/var/opt/mssql
  app:
    build: .
    command: dotnet run --project src/LecturerSupportSystem.App/LecturerSupportSystem.App.csproj
    environment:
      - ConnectionStrings__Default="Server=sqlserver;Database=LecturerSupportDB;User Id=sa;Password=YourPassword123;"
    depends_on:
      - sqlserver
volumes:
  sql-data:
```

---

## Contributing

- Fork the repo, create a feature branch, add tests, and open a PR with clear acceptance criteria.
- Add CONTRIBUTING.md and CODE_OF_CONDUCT.md to guide contributors.
- Use semantic commits and include DB migration changes in PRs that alter schema.

---

## Troubleshooting & FAQ

- "Cannot connect": verify Data Source value and that SQL Server is running; check firewall and ports.
- "Login failed for user": check authentication mode and credentials (Windows vs SQL auth).
- "Schema missing": run the provided SQL schema scripts or ensure migrations ran.
- If DatabaseAccess is hardcoded, refactor to configuration variables before committing.

---

## License & maintainers

- License: MIT (replace if you prefer another license)
- Maintainer: oggishi (https://github.com/oggishi)
- Contact: include email or profile link in repository

---

Thank you for reviewing LecturerSupportSystem. This README provides a professional overview and a concrete Functions & Tasks backlog so you can quickly provision the database, update the DAL connection string, and start implementing prioritized features.
