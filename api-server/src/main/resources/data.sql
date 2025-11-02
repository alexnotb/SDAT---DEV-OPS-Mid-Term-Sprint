CREATE DATABASE IF NOT EXISTS `flight_api` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `flight_api`;


-- Table: city
CREATE TABLE IF NOT EXISTS city (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255),
  state VARCHAR(255),
  population BIGINT
) ENGINE=InnoDB;

-- Table: airport
CREATE TABLE IF NOT EXISTS airport (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255),
  code VARCHAR(50),
  city_id BIGINT,
  CONSTRAINT fk_airport_city FOREIGN KEY (city_id) REFERENCES city(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Table: aircraft
CREATE TABLE IF NOT EXISTS aircraft (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  type VARCHAR(255),
  airline_name VARCHAR(255),
  number_of_passengers INT
) ENGINE=InnoDB;

-- Table: passenger
CREATE TABLE IF NOT EXISTS passenger (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  phone_number VARCHAR(50),
  city_id BIGINT,
  CONSTRAINT fk_passenger_city FOREIGN KEY (city_id) REFERENCES city(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Join table: aircraft_airports (aircraft <-> airport)
CREATE TABLE IF NOT EXISTS aircraft_airports (
  aircraft_id BIGINT NOT NULL,
  airport_id BIGINT NOT NULL,
  PRIMARY KEY (aircraft_id, airport_id),
  CONSTRAINT fk_aa_aircraft FOREIGN KEY (aircraft_id) REFERENCES aircraft(id) ON DELETE CASCADE,
  CONSTRAINT fk_aa_airport FOREIGN KEY (airport_id) REFERENCES airport(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Join table: aircraft_passengers (passenger <-> aircraft)
CREATE TABLE IF NOT EXISTS aircraft_passengers (
  passenger_id BIGINT NOT NULL,
  aircraft_id BIGINT NOT NULL,
  PRIMARY KEY (passenger_id, aircraft_id),
  CONSTRAINT fk_ap_passenger FOREIGN KEY (passenger_id) REFERENCES passenger(id) ON DELETE CASCADE,
  CONSTRAINT fk_ap_aircraft FOREIGN KEY (aircraft_id) REFERENCES aircraft(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Sample data: cities (match DataInitializer)
INSERT INTO city (name, state, population) VALUES
  ('Seattle', 'WA', 733919),
  ('New York', 'NY', 8467513),
  ('Chicago', 'IL', 2679000);

-- Sample data: airports (attach to cities above)
INSERT INTO airport (name, code, city_id) VALUES
  ('Seattle-Tacoma International', 'SEA', 1),
  ('Boeing Field', 'BFI', 1),
  ('John F. Kennedy International', 'JFK', 2),
  ('LaGuardia', 'LGA', 2),
  ('O''Hare International', 'ORD', 3);

-- Sample data: aircraft
INSERT INTO aircraft (type, airline_name, number_of_passengers) VALUES
  ('Boeing 737', 'Alaska Airlines', 180),
  ('Airbus A320', 'Delta', 190),
  ('Embraer 175', 'SkyWest', 76);

-- Sample data: passengers
INSERT INTO passenger (first_name, last_name, phone_number, city_id) VALUES
  ('Alex', 'Chen', '206-555-0100', 1),
  ('Jordan', 'Diaz', '212-555-0145', 2),
  ('Maya', 'Singh', '312-555-0199', 3);

-- Link aircraft to airports (match DataInitializer sets)
-- boeing737 (id 1) -> sea(1), jfk(3)
-- airbusA320 (id 2) -> lga(4), ord(5)
-- embraer175 (id 3) -> bfi(2), ord(5)
-- Use INSERT IGNORE so re-running the script doesn't fail on duplicate composite PKs
INSERT IGNORE INTO aircraft_airports (aircraft_id, airport_id) VALUES
  (1, 1),
  (1, 3),
  (2, 4),
  (2, 5),
  (3, 2),
  (3, 5);

-- Link passengers to aircraft
-- alex (1) -> boeing737(1), embraer175(3)
-- jordan (2) -> boeing737(1), airbusA320(2)
-- maya (3) -> airbusA320(2)
-- Use INSERT IGNORE so re-running the script doesn't fail on duplicate composite PKs
INSERT IGNORE INTO aircraft_passengers (passenger_id, aircraft_id) VALUES
  (1, 1),
  (1, 3),
  (2, 1),
  (2, 2),
  (3, 2);

-- End of data.sql
