-- Flight Management Course Project Database
-- Project Team 31

/* This is a standard preamble for most of our scripts. The intent is to establish
a consistent environment for the database behavior. */

set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;
set @thisDatabase = 'flight_management';

drop database if exists flight_management;
create database if not exists flight_management;
use flight_management;

CREATE TABLE Airline (
    airlineID VARCHAR(20) PRIMARY KEY,
    revenue FLOAT
);

CREATE TABLE Location (
    locID VARCHAR(10) PRIMARY KEY
);

CREATE TABLE Airport (
    airportID VARCHAR(3) PRIMARY KEY,
    city VARCHAR(50),
    state VARCHAR(50),
    location VARCHAR(10),
    CONSTRAINT airport_location FOREIGN KEY (location) REFERENCES Location(locID)
);

CREATE TABLE Person (
    personID VARCHAR(5) PRIMARY KEY,
    firstName VARCHAR(50),
    lastName VARCHAR(50),
    occupant VARCHAR(10) NOT NULL,
    CONSTRAINT person_occupant FOREIGN KEY (occupant) REFERENCES Location(locID)
);

CREATE TABLE Leg (
    legID VARCHAR(10) PRIMARY KEY,
    distance FLOAT,
    departure VARCHAR(3) NOT NULL,
    arrival VARCHAR(3) NOT NULL,
    CONSTRAINT leg_departure FOREIGN KEY (departure) REFERENCES Airport(airportID),
    CONSTRAINT leg_arrival FOREIGN KEY (arrival) REFERENCES Airport(airportID)
);

CREATE TABLE Route (
    routeID VARCHAR(50) PRIMARY KEY
);

CREATE TABLE Contain (
    routeID VARCHAR(50) NOT NULL,
    legID VARCHAR(10) NOT NULL,
    sequence INT,
    PRIMARY KEY (routeID, legID),
    CONSTRAINT contain_route FOREIGN KEY (routeID) REFERENCES Route(routeID),
    CONSTRAINT contain_leg FOREIGN KEY (legID) REFERENCES Leg(legID)
);

CREATE TABLE Airplanes (
	airlineID VARCHAR(20) NOT NULL,
    tail_num VARCHAR(20) NOT NULL,
    seat_cap INT,
    speed INT,
    location VARCHAR(10),
    plane_type VARCHAR(4),
    num_engines INT,
    num_props INT,
    PRIMARY KEY (airlineID, tail_num),
    CONSTRAINT airlineID FOREIGN KEY (airlineID) REFERENCES Airline(airlineID),
    CONSTRAINT airplanes_location FOREIGN KEY (location) REFERENCES Location(locID)
);

CREATE TABLE Flight (
    flightID VARCHAR(8) PRIMARY KEY,
    routeID VARCHAR(30) NOT NULL,
    support_airline VARCHAR(20),
    support_tail VARCHAR(20),
    progress INT,
    stat VARCHAR(20),
    next_time TIME,
    CONSTRAINT flight_route FOREIGN KEY (routeID) REFERENCES Route(routeID),
    CONSTRAINT flight_tail FOREIGN KEY (support_airline, support_tail) REFERENCES Airplanes(airlineID, tail_num)
);

CREATE TABLE Ticket (
    ticketID VARCHAR(10) PRIMARY KEY,
    cost FLOAT,
    deplane_at VARCHAR(3) NOT NULL,
    customer VARCHAR(5) NOT NULL,
    carrier VARCHAR(8) NOT NULL,
    CONSTRAINT ticket_deplane FOREIGN KEY (deplane_at) REFERENCES Airport(airportID),
    CONSTRAINT ticket_owner FOREIGN KEY (customer) REFERENCES Person(personID),
    CONSTRAINT ticket_flight FOREIGN KEY (carrier) REFERENCES Flight(flightID)
);

CREATE TABLE Pilot (
    personID VARCHAR(3),
    taxID VARCHAR(20) PRIMARY KEY,
    experience INT,
    airlinesID VARCHAR(20),
    tails_num VARCHAR(20),
    CONSTRAINT flies FOREIGN KEY (airlinesID, tails_num) REFERENCES Airplanes(airlineID, tail_num),
    CONSTRAINT pilot_person FOREIGN KEY (personID) REFERENCES Person(personID)
);

CREATE TABLE Passenger (
    personID VARCHAR(5) PRIMARY KEY,
    miles INT,
    CONSTRAINT passenger_person FOREIGN KEY (personID) REFERENCES Person(personID)
);

CREATE TABLE License (
    personID VARCHAR(5) NOT NULL,
    licenseName VARCHAR(50),
    PRIMARY KEY (personID, licenseName),
    CONSTRAINT license_person FOREIGN KEY (personID) REFERENCES Person(personID)
);

CREATE TABLE Seat (
    ticketID VARCHAR(10),
    seat VARCHAR(20),
    PRIMARY KEY (ticketID, seat),
    CONSTRAINT seat_ticket FOREIGN KEY (ticketID) REFERENCES Ticket(ticketID)
);

# INSERT STATEMENTS

INSERT INTO Airline VALUES 
		('Air_France', 25),
        ('American', 45),
        ('Delta', 46),
        ('JetBlue', 8),
        ('Lufthansa', 31),
        ('Southwest', 22),
        ('Spirit', 4),
        ('United', 40);
        
INSERT INTO Location VALUES 
	('plane_1'), ('plane_11'), 
    ('plane_15'), ('plane_2'), 
    ('plane_4'), ('plane_7'), 
    ('plane_8'), ('plane_9'), 
    ('port_1'), ('port_10'), 
    ('port_11'), ('port_13'), 
    ('port_14'), ('port_15'), 
    ('port_17'), ('port_18'), 
    ('port_2'), ('port_3'), 
    ('port_4'), ('port_5'), 
    ('port_7'), ('port_9');

INSERT INTO Airport VALUES
	('ABQ', 'Albuquerque', 'NM', NULL),
	('ANC', 'Anchorage', 'AK', NULL),
	('ATL', 'Atlanta', 'GA', 'port_1'),
	('BDL', 'Hartford', 'CT', NULL),
	('BFI', 'Seattle', 'WA', 'port_10'),
	('BHM', 'Birmingham', 'AL', NULL),
	('BNA', 'Nashville', 'TN', NULL),
	('BOI', 'Boise', 'ID', NULL),
	('BOS', 'Boston', 'MA', NULL),
	('BTV', 'Burlington', 'VT', NULL),
	('BWI', 'Baltimore', 'MD', NULL),
	('BZN', 'Bozeman', 'MT', NULL),
	('CHS', 'Charleston', 'SC', NULL),
	('CLE', 'Cleveland', 'OH', NULL),
	('CLT', 'Charlotte', 'NC', NULL),
	('CRW', 'Charleston', 'WV', NULL),
	('DAL', 'Dallas', 'TX', 'port_7'),
	('DCA', 'Washington', 'DC', 'port_9'),
	('DEN', 'Denver', 'CO', 'port_3'),
	('DFW', 'Dallas', 'TX', 'port_2'),
	('DSM', 'Des Moines', 'IA', NULL),
	('DTW', 'Detroit', 'MI', NULL),
	('EWR', 'Newark', 'NJ', NULL),
	('FAR', 'Fargo', 'ND', NULL),
	('FSD', 'Sioux Falls', 'SD', NULL),
	('GSN', 'Obyan Saipan Island', 'MP', NULL),
	('GUM', 'Agana Tamuning', 'GU', NULL),
	('HNL', 'Honolulu', 'HI', NULL),
	('HOU', 'Houston', 'TX', 'port_18'),
	('IAD', 'Washington', 'DC', 'port_11'),
	('IAH', 'Houston', 'TX', 'port_13'),
	('ICT', 'Wichita', 'KS', NULL),
	('ILG', 'Wilmington', 'DE', NULL),
	('IND', 'Indianapolis', 'IN', NULL),
	('ISP', 'New York Islip', 'NY', 'port_14'),
	('JAC', 'Jackson', 'WY', NULL),
	('JAN', 'Jackson', 'MS', NULL),
	('JFK', 'New York', 'NY', 'port_15'),
	('LAS', 'Las Vegas', 'NV', NULL),
	('LAX', 'Los Angeles', 'CA', 'port_5'),
	('LGA', 'New York', 'NY', NULL),
	('LIT', 'Little Rock', 'AR', NULL),
	('MCO', 'Orlando', 'FL', NULL),
	('MDW', 'Chicago', 'IL', NULL),
	('MHT', 'Manchester', 'NH', NULL),
	('MKE', 'Milwaukee', 'WI', NULL),
	('MRI', 'Anchorage', 'AK', NULL),
	('MSP', 'Minneapolis', 'MN', NULL),
	('MSY', 'New Orleans', 'LA', NULL),
	('OKC', 'Oklahoma City', 'OK', NULL),
	('OMA', 'Omaha', 'NE', NULL),
	('ORD', 'Chicago', 'IL', 'port_4'),
	('PDX', 'Portland', 'OR', NULL),
	('PHL', 'Philadelphia', 'PA', NULL),
    ('PHX', 'Phoenix', 'AZ', NULL),
	('PVD', 'Providence', 'RI', NULL),
	('PWM', 'Portland', 'ME', NULL),
	('SDF', 'Louisville', 'KY', NULL),
	('SEA', 'Seattle Tacoma', 'WA', 'port_17'),
	('SJU', 'San Juan Carolina', 'PR', NULL),
	('SLC', 'Salt Lake City', 'UT', NULL),
	('STL', 'Saint Louis', 'MO', NULL),
	('STT', 'Charlotte Amalie Saint Thomas', 'VI', NULL);

INSERT INTO Leg VALUES
	('leg_1', 600.0, 'ATL', 'IAD'),
	('leg_10', 800.0, 'DFW', 'ORD'),
	('leg_11', 600, 'IAD', 'ORD'),
	('leg_12', 200, 'IAH', 'DAL'),
	('leg_13', 1400, 'IAH', 'LAX'),
	('leg_14', 2400, 'ISP', 'BFI'),
	('leg_15', 800, 'JFK', 'ATL'),
	('leg_16', 800, 'JFK', 'ORD'),
	('leg_17', 2400, 'JFK', 'SEA'),
	('leg_18', 1200, 'LAX', 'DFW'),
	('leg_19', 1000, 'LAX', 'SEA'),
	('leg_2', 600, 'ATL', 'IAH'),
	('leg_20', 600.0, 'ORD', 'DCA'),
	('leg_21', 800, 'ORD', 'DFW'),
	('leg_22', 800.0, 'ORD', 'LAX'),
	('leg_23', 2400, 'SEA', 'JFK'),
	('leg_24', 1800, 'SEA', 'ORD'),
	('leg_25', 600, 'ORD', 'ATL'),
	('leg_26', 800.0, 'LAX', 'ORD'),
	('leg_27', 1600, 'ATL', 'LAX'),
	('leg_3', 800, 'ATL', 'JFK'),
	('leg_4', 600, 'ATL', 'ORD'),
	('leg_5', 1000, 'BFI', 'LAX'),
	('leg_6', 200.0, 'DAL', 'HOU'),
	('leg_7', 600.0, 'DCA', 'ATL'),
	('leg_8', 200.0, 'DCA', 'JFK'),
	('leg_9', 800.0, 'DFW', 'ATL');	

INSERT INTO Route VALUES
	('circle_east_coast'),
	('circle_west_coast'),
	('eastbound_north_milk_run'),
	('eastbound_north_nonstop'),
	('eastbound_south_milk_run'),
	('hub_xchg_southeast'),
	('hub_xchg_southwest'),
	('local_texas'),
	('northbound_east_coast'),
	('northbound_west_coast'),
	('southbound_midwest'),
	('westbound_north_milk_run'),
	('westbound_north_nonstop'),
	('westbound_south_nonstop');
        
INSERT INTO Contain VALUES
	('circle_east_coast', 'leg_4', 1),
	('circle_east_coast', 'leg_20', 2),
	('circle_east_coast', 'leg_7', 3),
	('circle_west_coast', 'leg_18', 1),
	('circle_west_coast', 'leg_10', 2),
	('circle_west_coast', 'leg_22', 3),
	('eastbound_north_milk_run', 'leg_24', 1),
	('eastbound_north_milk_run', 'leg_20', 2),
	('eastbound_north_milk_run', 'leg_8', 3),
	('eastbound_north_nonstop', 'leg_23', 1),
	('eastbound_south_milk_run', 'leg_18', 1),
	('eastbound_south_milk_run', 'leg_9', 2),
	('eastbound_south_milk_run', 'leg_1', 3),
	('hub_xchg_southeast', 'leg_25', 1),
	('hub_xchg_southeast', 'leg_4', 2),
	('hub_xchg_southwest', 'leg_22', 1),
	('hub_xchg_southwest', 'leg_26', 2),
	('local_texas', 'leg_12', 1),
	('local_texas', 'leg_6', 2),
	('northbound_east_coast', 'leg_3', 1),
	('northbound_west_coast', 'leg_19', 1),
	('southbound_midwest', 'leg_21', 1),
	('westbound_north_milk_run', 'leg_16', 1),
	('westbound_north_milk_run', 'leg_22', 2),
	('westbound_north_milk_run', 'leg_19', 3),
	('westbound_north_nonstop', 'leg_17', 1),
	('westbound_south_nonstop', 'leg_27', 1);

INSERT INTO Airplanes VALUES 
	('American', 'n330ss', 4, 200, 'plane_4', 'jet', NULL, 2),
    ('American', 'n380sd', 5, 400, NULL, 'jet', NULL, 2),
    ('Delta', 'n106js', 4, 200, 'plane_1', 'jet', NULL, 2),
    ('Delta', 'n110jn', 5, 600, 'plane_2', 'jet', NULL, 4),
    ('Delta', 'n127js', 4, 800, NULL, NULL, NULL, NULL),
    ('Delta', 'n156sq', 8, 100, NULL, NULL, NULL, NULL),
    ('JetBlue', 'n161fk', 4, 200, NULL, 'jet', NULL, 2),
    ('JetBlue', 'n337as', 5, 400, NULL, 'jet', NULL, 2),
    ('Southwest', 'n118fm', 4, 100, 'plane_11', 'prop', 1, 1),
    ('Southwest', 'n401fj', 4, 200, 'plane_9', 'jet', NULL, 2),
    ('Southwest', 'n653fk', 6, 400, NULL, 'jet', NULL, 2),
    ('Southwest', 'n815pw', 3, 200, NULL, 'prop', 0, 2),
    ('Spirit', 'n256ap', 4, 400, 'plane_15', 'jet', NULL, 2),
    ('United', 'n451fi', 5, 400, NULL, 'jet', NULL, 4),
    ('United', 'n517ly', 4, 400, 'plane_7', 'jet', NULL, 2),
    ('United', 'n616lt', 7, 400, NULL, 'jet', NULL, 4),
    ('United', 'n620la', 4, 200, 'plane_8', 'prop', 0, 2);

INSERT INTO Flight VALUES
	('AM_1523', 'circle_west_coast', 'American', 'n330ss', 2.0, 'on_ground', '14:30'),
	('DL_1174', 'northbound_east_coast', 'Delta', 'n106js', 0.0, 'on_ground', '8:00'),
	('DL_1243', 'westbound_north_nonstop', 'Delta', 'n110jn', 0.0, 'on_ground', '9:30'),
	('DL_3410', 'circle_east_coast', NULL, NULL, NULL, NULL, NULL),
	('SP_1880', 'circle_east_coast', 'Spirit', 'n256ap', 2.0, 'in_flight', '15:00'),
	('SW_1776', 'hub_xchg_southwest', 'Southwest', 'n401fj', 2.0, 'in_flight', '14:00'),
	('SW_610', 'local_texas', 'Southwest', 'n118fm', 2.0, 'in_flight', '11:30'),
	('UN_1899', 'eastbound_north_milk_run', 'United', 'n517ly', 0.0, 'on_ground', '9:30'),
	('UN_523', 'hub_xchg_southeast', 'United', 'n620la', 1.0, 'in_flight', '11:00'),
	('UN_717', 'circle_west_coast', NULL, NULL, NULL, NULL, NULL);

INSERT INTO Person VALUES
	('p1', 'Jeanne', 'Nelson', 'plane_1'),
	('p10', 'Lawrence', 'Morgan', 'plane_9'),
	('p11', 'Sandra', 'Cruz', 'plane_9'),
	('p12', 'Dan', 'Ball', 'plane_11'),
	('p13', 'Bryant', 'Figueroa', 'plane_2'),
	('p14', 'Dana', 'Perry', 'plane_2'),
	('p15', 'Matt', 'Hunt', 'plane_2'),
	('p16', 'Edna', 'Brown', 'plane_15'),
	('p18', 'Esther', 'Pittman', 'port_2'),
	('p17', 'Ruby', 'Burgess', 'plane_15'),
	('p19', 'Doug', 'Fowler', 'port_4'),
	('p2', 'Roxanne', 'Byrd', 'plane_1'),
	('p20', 'Thomas', 'Olson', 'port_3'),
	('p21', 'Mona', 'Harrison', 'port_4'),
	('p22', 'Arlene', 'Massey', 'port_2'),
	('p23', 'Judith', 'Patrick', 'port_3'),
	('p24', 'Reginald', 'Rhodes', 'plane_1'),
	('p25', 'Vincent', 'Garcia', 'plane_1'),
	('p26', 'Cheryl', 'Moore', 'plane_4'),
	('p27', 'Micheal', 'Rivera', 'plane_7'),
	('p28', 'Luther', 'Matthews', 'plane_8'),
	('p29', 'Moses', 'Parks', 'plane_8'),
	('p3', 'Tanya', 'Nguyen', 'plane_4'),
	('p30', 'Ora', 'Steele', 'plane_9'),
	('p31', 'Antonio', 'Flores', 'plane_9'),
	('p32', 'Glenn', 'Ross', 'plane_11'),
	('p33', 'Tanya', 'Thomas', 'plane_11'),
	('p34', 'Ann', 'Maldonado', 'plane_2'),
	('p35', 'Jeffrey', 'Cruz', 'plane_2'),
	('p36', 'Sonya', 'Price', 'plane_15'),
	('p37', 'Tracy', 'Hale', 'plane_15'),
	('p38', 'Albert', 'Simmons', 'port_1'),
	('p39', 'Karen', 'Terry', 'port_9'),
	('p4', 'Kendra', 'Jacobs', 'plane_4'),
	('p40', 'Glen', 'Kelley', 'plane_4'),
	('p41', 'Brooke', 'Little', 'port_4'),
	('p42', 'Daryl', 'Nguyen', 'port_3'),
	('p43', 'Judy', 'Willis', 'port_1'),
	('p44', 'Marco', 'Klein', 'port_2'),
	('p45', 'Angelica', 'Hampton', 'port_5'),
	('p5', 'Jeff', 'Burton', 'plane_4'),
	('p6', 'Randal', 'Parks', 'plane_7'),
	('p7', 'Sonya', 'Owens', 'plane_7'),
	('p8', 'Bennie', 'Palmer', 'plane_8'),
	('p9', 'Marlene', 'Warner', 'plane_8');

INSERT INTO License VALUES
		('p1', 'jet'),
        ('p10', 'jet'),
        ('p11', 'jet'),
        ('p11', 'prop'),
        ('p12', 'prop'),
        ('p13', 'jet'),
        ('p14', 'jet'),
        ('p15', 'jet'),
        ('p15', 'prop'),
        ('p15', 'testing'),
        ('p16', 'jet'),
        ('p17', 'jet'),
        ('p17', 'prop'),
        ('p18', 'jet'),
        ('p19', 'jet'),
        ('p2', 'jet'),
        ('p2', 'prop'),
        ('p20', 'jet'),
        ('p21', 'jet'),
        ('p21', 'prop'),
        ('p22', 'jet'),
        ('p23', 'jet'),
        ('p24', 'jet'),
        ('p24', 'prop'),
        ('p24', 'testing'),
        ('p25', 'jet'),
        ('p26', 'jet'),
        ('p3', 'jet'),
        ('p4', 'jet'),
        ('p4', 'prop'),
        ('p5', 'jet'),
        ('p6', 'jet'),
        ('p6', 'prop'),
        ('p7', 'jet'),
        ('p8', 'prop'),
        ('p9', 'jet'),
        ('p9', 'prop'),
        ('p9', 'testing');
        
INSERT INTO Passenger VALUES
		('p21', 771.0),
        ('p22', 374.0),
        ('p23', 414.0),
        ('p24', 292.0),
        ('p25', 390.0),
        ('p26', 302.0),
        ('p27', 470.0),
        ('p28', 208.0),
        ('p29', 292.0),
        ('p30', 686.0),
        ('p31', 547.0),
        ('p32', 257.0),
        ('p33', 564.0),
        ('p34', 211.0),
        ('p35', 233.0),
        ('p36', 293.0),
        ('p37', 552.0),
        ('p38', 812.0),
        ('p39', 541.0),
        ('p40', 441.0),
        ('p41', 875.0),
        ('p42', 691.0),
        ('p43', 572.0),
        ('p44', 572.0),
        ('p45', 663.0);

INSERT INTO Pilot VALUES 
	('p1', '330-12-6907', 31, 'Delta', 'n106js'),
    ('p10', '769-60-1266', 15, 'Southwest', 'n401fj'),
    ('p11', '369-22-9505', 22, 'Southwest', 'n401fj'),
    ('p12', '680-92-5329', 24, 'Southwest', 'n118fm'),
    ('p13', '513-40-4168', 24, 'Delta', 'n110jn'),
    ('p14', '454-71-7847', 13, 'Delta', 'n110jn'),
    ('p15', '153-47-8101', 30, 'Delta', 'n110jn'),
    ('p16', '598-47-5172', 28, 'Spirit', 'n256ap'),
    ('p17', '856-71-6800', 36, 'Spirit', 'n256ap'),
    ('p2', '842-88-1257', 9, 'Delta', 'n106js'),
    ('p3', '750-24-7616', 11, 'American', 'n330ss'),
    ('p4', '776-21-8098', 24, 'American', 'n330ss'),
    ('p5', '933-93-2165', 27, 'American', 'n330ss'),
    ('p6', '707-84-4555', 38, 'United', 'n517ly'),
    ('p7', '450-25-5617', 13, 'United', 'n517ly'),
    ('p8', '701-38-2179', 12, 'United', 'n620la'),
	('p9', '936-44-6941', 13, 'United', 'n620la')
    ;


INSERT INTO Ticket VALUES
	('tkt_dl_1', 450, 'JFK', 'p24', 'DL_1174'),
	('tkt_dl_2', 225, 'JFK', 'p25', 'DL_1174'),
	('tkt_am_3', 250, 'LAX', 'p26', 'AM_1523'),
	('tkt_un_4', 175, 'DCA', 'p27', 'UN_1899'),
	('tkt_un_5', 225, 'ATL', 'p28', 'UN_523'),
	('tkt_un_6', 100, 'ORD', 'p29', 'UN_523'),
	('tkt_sw_7', 400, 'ORD', 'p30', 'SW_1776'),
	('tkt_sw_8', 175, 'ORD', 'p31', 'SW_1776'),
	('tkt_sw_9', 125, 'HOU', 'p32', 'SW_610'),
	('tkt_sw_10', 425, 'HOU', 'p33', 'SW_610'),
	('tkt_dl_11', 500, 'LAX', 'p34', 'DL_1243'),
	('tkt_dl_12', 250, 'LAX', 'p35', 'DL_1243'),
	('tkt_sp_13', 225, 'ATL', 'p36', 'SP_1880'),
	('tkt_sp_14', 150, 'DCA', 'p37', 'SP_1880'),
	('tkt_un_15', 150, 'ORD', 'p38', 'UN_523'),
	('tkt_sp_16', 475, 'ATL', 'p39', 'SP_1880'),
	('tkt_am_17', 375, 'ORD', 'p40', 'AM_1523'),
	('tkt_am_18', 275, 'LAX', 'p41', 'AM_1523');
    
INSERT INTO Seat VALUES
	('tkt_dl_1', '1C'),
	('tkt_dl_1', '2F'),
	('tkt_dl_2', '2D'),
	('tkt_am_3', '3B'),
	('tkt_un_4', '2B'),
	('tkt_un_5', '1A'),
	('tkt_un_6', '3B'),
	('tkt_sw_7', '3C'),
	('tkt_sw_8', '3E'),
	('tkt_sw_9', '1C'),
	('tkt_sw_10', '1D'),
	('tkt_dl_11', '1E'),
	('tkt_dl_11', '1B'),
	('tkt_dl_11', '2F'),
	('tkt_dl_12', '2A'),
	('tkt_sp_13', '1A'),
	('tkt_sp_14', '2B'),
	('tkt_un_15', '1B'),
	('tkt_sp_16', '2C'),
	('tkt_sp_16', '2E'),
	('tkt_am_17', '2B'),
	('tkt_am_18', '2A');
