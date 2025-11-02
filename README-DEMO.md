# Demo recording guide

I prepared this guide to record a short demo for the Sprint Week Flight project.

Developers on this project:
- Oleksii Bezkibalnyi — Front-end
- Ivan Zymalov — Back-end

Goal
- Show the API server starting, demonstrate the 4 aggregate endpoints, and use the CLI client to answer the 4 questions.

Quick checklist before recording
- Ensure MySQL is running and `flight_api` is prepared (see `api-server/README-db.md`).
- Ensure Maven is installed and available on PATH (or `C:\Tools\apache-maven-3.9.6\bin\mvn.cmd` exists).
- Open three terminal windows: Server, API checks, CLI.

Recording timeline (recommended, ~2-4 minutes)

00:00–00:15 — Intro (voice)
- "Hi — this is our Sprint Week Flight project. It contains a Spring Boot API and a Java CLI that answers four questions about flights. I'll demonstrate the API and the CLI." 

00:15–00:40 — Start server (terminal #1)
- Command:
```powershell
cd "d:\Alex\SD13 Projects\qap1\SDAT---DEV-OPS-Mid-Term-Sprint\api-server"
mvn spring-boot:run
```
-- Narration: "Starting the API — it will listen on port 8080 and connect to MySQL."

00:40–01:00 — Quick API check (terminal #2)
- Commands (execute while server is running):
```powershell
Invoke-RestMethod -Uri "http://localhost:8080/cities/airports" -Method GET | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "http://localhost:8080/passengers/aircraft" -Method GET | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "http://localhost:8080/aircraft/airports" -Method GET | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "http://localhost:8080/passengers/airports" -Method GET | ConvertTo-Json -Depth 5
```
-- Narration: "These endpoints show the airports per city, aircraft flown by passengers, airports used by aircraft, and airports used by passengers."

01:00–02:00 — Run CLI (terminal #3)
- Build and run CLI:
```powershell
cd "d:\Alex\SD13 Projects\qap1\SDAT---DEV-OPS-Mid-Term-Sprint\cli-client"
mvn -DskipTests package
mvn -Dexec.mainClass=com.example.flightcli.FlightCliApplication -Dexec.args='http://localhost:8080' -DskipTests exec:java
```
-- Interact with the menu: choose 1, 2, 3, 4 to demonstrate answers.
-- Narration: "The CLI calls the same API endpoints and prints user-friendly answers."

02:00–02:30 — Wrap up
-- Narration: "That's the demo. Repositories, tests, and the project board are linked in the README." 

Optional: use the helper script
-- A helper PowerShell script is included at `scripts/demo.ps1` that automates the common steps: optional data load, start server in background, call the 4 endpoints, and run the CLI. Run with `-LoadData` to run `data.sql` interactively.

Notes and troubleshooting

Notes and troubleshooting
- If the SQL script fails due to duplicate keys, the project contains `INSERT IGNORE` statements for join tables. I can TRUNCATE the join tables before rerunning the SQL if needed.
- If `mvn` is not found, install Maven or modify the script to point to your `mvn` executable.

Good luck — I recommend recording in short segments and then editing them together for a polished video.
