# Database setup and demo instructions (for mentor demo)

I prepared these steps to create the `flight_api` MySQL database and load demo data so the API can be demonstrated without extra setup.

Developers on this project:
- Oleksii Bezkibalnyi — Front-end
- Ivan Zymalov — Back-end

Prerequisites
- MySQL server installed and running locally
- PowerShell (Windows) or a shell with the `mysql` client available

Quick steps (PowerShell)

1. Run the SQL file (you will be prompted for the MySQL root password):

```powershell
mysql -u root -p < "${PWD}\api-server\src\main\resources\data.sql"
```

2. Confirm the data exists (example queries):

```powershell
# list cities
mysql -u flight_user -pflight_pass -e "USE flight_api; SELECT id,name,state,population FROM city;"

# list airports
mysql -u flight_user -pflight_pass -e "USE flight_api; SELECT id,name,code,city_id FROM airport;"
```

Run the API
1. I may need to adjust credentials in `src/main/resources/application.properties` if necessary (defaults are `flight_user` / `flight_pass`).
2. Start the Spring Boot app in `api-server`:

```powershell
# from project root
cd api-server
mvn spring-boot:run
```

Verification
- Open `http://localhost:8080/cities/airports` in Postman or a browser — you should see the demo cities with airports.
- Use the CLI client (in `cli-client`) to answer the 4 questions.

Notes
- The project already contains a `DataInitializer` that seeds the same demo data when the app runs against an empty DB. I included `data.sql` as an alternative so I can prepare the database ahead of time for an in-person demo.

Create user (optional)

If you want the `flight_user` database account (used by the application) created automatically, run the following commands as a privileged MySQL user (for example, as `root`):

```sql
CREATE USER 'flight_user'@'localhost' IDENTIFIED BY 'flight_pass';
GRANT ALL PRIVILEGES ON `flight_api`.* TO 'flight_user'@'localhost';
FLUSH PRIVILEGES;
```

I removed CREATE USER/GRANT statements from `data.sql` to avoid requiring root when I run the script during demos. Run the snippet above once as root if you prefer to create the user automatically.