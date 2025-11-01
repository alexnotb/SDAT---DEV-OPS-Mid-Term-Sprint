# Sprint Week Flight Project

This workspace contains both parts of the Sprint Week assignment:

- `api-server` – Spring Boot REST API backed by MySQL.
- `cli-client` – Java CLI that answers the four required questions via HTTP `GET` calls.

## What Was Built

- Full CRUD endpoints for cities, airports, passengers, and aircraft.
- Entity relationships that satisfy the project rubric.
- Aggregation endpoints backing the CLI questions.
- CLI menu that calls each aggregation endpoint and prints friendly answers.
- JUnit tests (API service + CLI with mocks).
- GitHub Actions workflow for the CLI (`mvn verify`).
- Sample data loaded at startup to help with Postman demos.

## Team Roles

- Backend (Spring Boot API): Ivan Zymalov
- CLI, testing, DevOps tooling: Oleksii Bezkibalnyi

## Next Steps for Submission

1. Initialize two separate GitHub repositories and push `api-server` and `cli-client` independently.
2. Create branches, open pull requests, and document progress with a project board.
3. Record the team demo video that highlights architecture, wins, blockers, and lessons learned.
4. Update `reflection.md` with your personal notes, then submit the repo links + video link + reflection.
