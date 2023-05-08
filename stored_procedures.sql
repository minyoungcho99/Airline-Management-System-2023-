-- Views, Functions & Stored Procedures

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;
set @thisDatabase = 'flight_management';

use flight_management;


-- [1] add_airplane()
drop procedure if exists add_airplane;
delimiter //
create procedure add_airplane (in ip_airlineID varchar(50), in ip_tail_num varchar(50),
	in ip_seat_capacity integer, in ip_speed integer, in ip_locationID varchar(50),
    in ip_plane_type varchar(100), in ip_skids boolean, in ip_propellers integer,
    in ip_jet_engines integer)
sp_main: begin
	DECLARE airplaneID INT;
    
    -- Check if airplane with same tail number exists for the airline
    SELECT COUNT(*) INTO airplaneID FROM airplane WHERE tail_num = ip_tail_num AND airlineID = ip_airlineID;
    
    IF airplaneID = 0 THEN -- If airplane with same tail number doesn't exist for the airline
        -- Insert new airplane into airplanes table
        INSERT INTO airplane(airlineID, tail_num, seat_capacity, speed, locationID, plane_type, skids, propellers, jet_engines)
        VALUES(ip_airlineID, ip_tail_num, ip_seat_capacity, ip_speed, ip_locationID, ip_plane_type, ip_skids, ip_propellers, ip_jet_engines);
        SELECT CONCAT('Airplane ', ip_tail_num, ' has been added to the database.') AS message;
    ELSE
        SELECT CONCAT('Airplane ', ip_tail_num, ' already exists for the airline.') AS message;
    END IF;
end //
delimiter ;

-- [2] add_airport()
drop procedure if exists add_airport;
delimiter //
create procedure add_airport (in ip_airportID char(3), in ip_airport_name varchar(200),
    in ip_city varchar(100), in ip_state char(2), in ip_locationID varchar(50))
sp_main: begin
	-- Check if the airportID already exists in the database
  IF EXISTS (SELECT * FROM airport WHERE airportID = ip_airportID) THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Airport ID already exists';
  END IF;
  
  -- Check if the locationID already exists in the database
  IF EXISTS (SELECT * FROM airport WHERE locationID = ip_locationID) THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Location ID already exists';
  END IF;
  
  -- Insert the new airport into the airports table
  INSERT INTO airport (airportID, airport_name, city, state, locationID)
  VALUES (ip_airportID, ip_airport_name, ip_city, ip_state, ip_locationID);
end //
delimiter ;

-- [3] add_person()
drop procedure if exists add_person;
delimiter //
create procedure add_person (in ip_personID varchar(50), in ip_first_name varchar(100),
    in ip_last_name varchar(100), in ip_locationID varchar(50), in ip_taxID varchar(50),
    in ip_experience integer, in ip_flying_airline varchar(50), in ip_flying_tail varchar(50),
    in ip_miles integer)
sp_main: begin
-- Check if the personID and locationID are unique
IF (SELECT COUNT(*) FROM person WHERE personID = ip_personID) > 0 THEN
    -- If not, halt execution without changing the database state
    LEAVE sp_main;
  END IF;
  IF (SELECT COUNT(*) FROM person WHERE personID = ip_personID and locationID = ip_locationID) > 0 THEN
    -- If not, halt execution without changing the database state
    LEAVE sp_main;
  END IF;

  -- Insert the person into the persons table
  INSERT INTO person (personID, first_name, last_name, locationID) 
  VALUES (ip_personID, ip_first_name, ip_last_name, ip_locationID);

  -- If the person is a pilot, insert them into the pilots table
  IF ip_taxID IS NOT NULL AND ip_experience IS NOT NULL AND (SELECT COUNT(*) FROM pilot WHERE taxID = ip_taxID) THEN 
    INSERT INTO pilot (personID, taxID, experience) VALUES (ip_personID, ip_taxID, ip_experience);

    -- If the person is assigned to an airplane, insert them into the flight_crew table
    IF ip_flying_airline IS NOT NULL AND ip_flying_tail IS NOT NULL THEN
      INSERT INTO flight_crew (personID, airlineID, tail_num) 
      VALUES (ip_personID, ip_flying_airline, ip_flying_tail);
    END IF;
  END IF;

  -- If the person is a passenger, insert them into the passengers table
  IF ip_miles IS NOT NULL THEN
    INSERT INTO passenger (personID, miles) VALUES (ip_personID, ip_miles);
  END IF;

end //
delimiter ;

-- [4] grant_pilot_license()
drop procedure if exists grant_pilot_license;
delimiter //
create procedure grant_pilot_license (in ip_personID varchar(50), in ip_license varchar(100))
sp_main: begin
	  if (ip_personID is NULL or ip_license is NULL) 
		then LEAVE sp_main; END IF;
	  
	  -- Check if the person already has a license of this type
	  set @count = (SELECT COUNT(*) FROM pilot_licenses WHERE personID = ip_personID AND license = ip_license);
	  IF @count > 0 THEN
		-- If person already has this license, halt the execution
		LEAVE sp_main;
	  END IF;
	  
	  -- Insert new pilot license for the person
	  INSERT INTO pilot_licenses (personID, license) VALUES (ip_personID, ip_license);
end //
delimiter ;

-- [5] offer_flight()
drop procedure if exists offer_flight;
delimiter //
create procedure offer_flight (in ip_flightID varchar(50), in ip_routeID varchar(50),
    in ip_support_airline varchar(50), in ip_support_tail varchar(50), in ip_progress integer,
    in ip_airplane_status varchar(100), in ip_next_time time)
sp_main: begin
DECLARE v_count INT;
    
    -- Check if the support airline, airplane, and route exist in the database
    SELECT COUNT(*) INTO v_count FROM airline WHERE airlineID = ip_support_airline;
    IF v_count = 0 THEN
        LEAVE sp_main;
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM airplane WHERE tail_num = ip_support_tail AND airlineID = ip_support_airline;
    IF v_count = 0 THEN
        LEAVE sp_main;
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM route WHERE routeID = ip_routeID;
    IF v_count = 0 THEN
        LEAVE sp_main;
    END IF;
    
    -- Check if the airplane has been assigned to a flight
    SELECT COUNT(*) INTO v_count FROM flight WHERE support_airline = ip_support_airline AND support_tail = ip_support_tail AND progress = 0;
    IF v_count > 0 THEN
        LEAVE sp_main;
    END IF;
    
    -- Insert the new flight
    INSERT INTO flight (flightID, routeID, support_airline, support_tail, progress, airplane_status, next_time) VALUES (ip_flightID, ip_routeID, ip_support_airline, ip_support_tail, ip_progress, ip_airplane_status, ip_next_time);

end //
delimiter ;

-- [6] purchase_ticket_and_seat()
drop procedure if exists purchase_ticket_and_seat;
delimiter //
create procedure purchase_ticket_and_seat (in ip_ticketID varchar(50), in ip_cost integer,
	in ip_carrier varchar(50), in ip_customer varchar(50), in ip_deplane_at char(3),
    in ip_seat_number varchar(50))
sp_main: begin
DECLARE v_valid_customer INT;
    DECLARE v_valid_seat INT;
    if (ip_ticketID is NULL or ip_carrier is NULL or ip_customer is NULL or ip_deplane_at is NULL or ip_seat_number is NULL)
		then leave sp_main; end if;
    -- Check if the customer exists in the database
    SELECT COUNT(*) INTO v_valid_customer FROM person WHERE personID = ip_customer;
    
    -- Check if the seat is unoccupied
    SELECT COUNT(*) INTO v_valid_seat FROM ticket_seats WHERE seat_number = ip_seat_number;
    
    -- Only create the new ticket if all validations are met
    IF v_valid_customer = 1 AND v_valid_seat = 0 THEN
        INSERT INTO ticket (ticketID, cost, carrier, customer, deplane_at) VALUES (ip_ticketID, ip_cost, ip_carrier, ip_customer, ip_deplane_at);
        INSERT INTO ticket_seats (ticketID, seat_number) VALUES (ip_ticketID, ip_seat_number);
    END IF;
end //
delimiter ;

-- [7] add_update_leg()
drop procedure if exists add_update_leg;
delimiter //
create procedure add_update_leg (in ip_legID varchar(50), in ip_distance integer,
    in ip_departure char(3), in ip_arrival char(3))
sp_main: begin
	if (ip_legID is NULL or ip_departure is NULL or ip_arrival is NULL or ip_distance is NULL) 
		then leave sp_main; end if;
	if (select count(*) from leg where departure = ip_arrival && arrival = ip_departure) = 1
		then update leg set distance = ip_distance where departure = ip_arrival && arrival = ip_departure; end if;
	if (select count(*) from leg where legID = ip_legID) > 1 
		then leave sp_main;
	elseif (select count(*) from leg where legID = ip_legID) = 1
		then update leg set distance = ip_distance where legId = ip_legID;
    else 
		insert into leg values (ip_legID, ip_distance, ip_departure, ip_arrival); end if;
end //
delimiter ;

-- [8] start_route()
drop procedure if exists start_route;
delimiter //
create procedure start_route (in ip_routeID varchar(50), in ip_legID varchar(50))
sp_main: begin
	if (ip_routeId is NULL or ip_legID is NULL) 
		then leave sp_main; end if;
	if (select count(*) from leg where legID = ip_legID) = 0
		then leave sp_main; end if;
	insert into route values (ip_routeID);
    insert into route_path values (ip_routeID, ip_legID, 1);
end //
delimiter ;

-- [9] extend_route()
drop procedure if exists extend_route;
delimiter //
create procedure extend_route (in ip_routeID varchar(50), in ip_legID varchar(50))
sp_main: begin
	if (ip_routeId is NULL or ip_legID is NULL) 
			then leave sp_main; end if;
	if (select count(*) from route where routeID = ip_routeID) = 0
		then leave sp_main; end if;
	if (select count(*) from leg where legID = ip_legID) = 0
		then leave sp_main; end if;
	set @leg_numb = (select count(*) from route_path where routeID = ip_routeID); 
    set @prev_arrival = (select arrival from route_path natural join leg as temp1 where @leg_num = sequence and routeID = ip_routeID);
    set @departure = (select departure from leg where legID = ip_legID);
	if (@departure = @prev_arrival)
			then leave sp_main; end if;
	insert into route_path values (ip_routeID, ip_legID, @leg_numb + 1);
end //
delimiter ;

-- [10] flight_landing()
drop procedure if exists flight_landing;
delimiter //
create procedure flight_landing (in ip_flightID varchar(50))
sp_main: begin
	if (ip_flightID is NULL) 
		then leave sp_main; end if;
	if (select count(*) from flight where flightID = ip_flightID) = 0
		then leave sp_main; end if;
	if (select count(*) from flight where flightID = ip_flightID and airplane_status is NULL) 
		then leave sp_main; end if;
	if (select count(*) from flight where flightID = ip_flightID and airplane_status = 'on_ground') 
		then leave sp_main; end if;
	update flight set next_time = addtime(next_time, '1:00:00.000'), airplane_status = 'on_ground' where flightID = ip_flightID;
    update pilot set experience = experience + '1' where pilot.personID in 
		(select personID from person natural join flight as temp1 where flightID = ip_flightID);
	set @distance = (select distance from leg natural join (select * from route_path natural join flight where sequence = progress) as temp2 where flightID = ip_flightID);
    update passenger set miles = miles + @distance
			where passenger.personID in (select person.personID from person where person.locationID in
				(select locationID from flight natural join airplane  as temp2 where flightID = ip_flightID));
end //
delimiter ;

-- [11] flight_takeoff()
drop procedure if exists flight_takeoff;
delimiter //
create procedure flight_takeoff (in ip_flightID varchar(50))
sp_main: begin
	if (ip_flightID is NULL) 
		then leave sp_main; end if;
	if (select count(*) from flight where flightID = ip_flightID) = 0
		then leave sp_main; end if;
	if (select plane_type from flight join airplane on tail_num = support_tail && flightID = ip_flightID) is NULL
		then leave sp_main; end if;
	if (select plane_type from flight join airplane on tail_num = support_tail && flightID = ip_flightID) = 'prop'
		then if (select count(*) from person where person.personID in 
			(select pilot.personID from pilot join flight on support_tail = flying_tail where flightID = ip_flightID)) < 1
			then update flight set next_time = addtime(next_time, '0:30:0') where flightID = ip_flightID; 
            leave sp_main; end if; end if;
	if (select plane_type from flight join airplane on tail_num = support_tail && flightID = ip_flightID) = 'jet'
		then if (select count(*) from person where person.personID in 
			(select pilot.personID from pilot join flight on support_tail = flying_tail where flightID = ip_flightID)) < 2
			then update flight set next_time = addtime(next_time, '0:30:0') where flightID = ip_flightID; 
            leave sp_main; end if; end if;
	set @distance = (select distance from leg natural join (select * from route_path natural join flight where sequence = progress) as temp2 where flightID = ip_flightID);
    set @time_taken = (@distance / (select speed from airplane natural join flight as temp1 where flightID = ip_flightID));
	update flight set airplane_status = 'in_flight', next_time = addtime(next_time, @time_taken) where flightID = ip_flightID;
    if (select progress from flight where flightID = ip_flightID) is NULL or (select progress from flight where flightID = ip_flightID) = 0
		then update flight set progress = 1 where flightID = ip_flightID;
     else
		update flight set progress = progress + 1 where flightID = ip_flightID; end if;
end //
delimiter ;

-- [12] passengers_board()
drop procedure if exists passengers_board;
delimiter //
create procedure passengers_board (in ip_flightID varchar(50))
sp_main: begin
	if (ip_flightID is NULL) 
		then leave sp_main; end if;
	if (select count(*) from flight where flightID = ip_flightID) = 0
		then leave sp_main; end if;
	set @plane_airport = (select locationID from airport natural join 
		(select arrival,departure from leg natural join 
			(select * from route_path natural join flight as temp1 where sequence = progress) 
				as temp2 where flightID = ip_flightID) 
					as temp3 where airportID = departure);
	if (@plane_airport is NULL)
		then leave sp_main; end if;
	update person set locationID = (select locationID from airplane natural join flight as temp1 where flightID = ip_flightID)
		where personID in (select customer from ticket where carrier = ip_flightID) && (select personID from passenger where locationID = @plane_airport);
end //
delimiter ;

-- [13] passengers_disembark()
drop procedure if exists passengers_disembark;
delimiter //
create procedure passengers_disembark (in ip_flightID varchar(50))
sp_main: begin
	update person 
	set locationID = (select distinct locationID from airport join ticket on deplane_at = airportID where carrier = ip_flightID and airportID like 
		(select arrival from leg where legID like (select legID from flight join route_path on flight.routeID = route_path.routeID where sequence = progress and flightID = ip_flightID)))
	where personID in (select customer from ticket where deplane_at = 
		(select arrival from leg where legID like (select legID from flight join route_path on flight.routeID = route_path.routeID where sequence = progress and flightID = ip_flightID))
	and carrier = ip_flightID);
end //
delimiter ;

-- [14] assign_pilot()
drop procedure if exists assign_pilot;
delimiter //
create procedure assign_pilot (in ip_flightID varchar(50), ip_personID varchar(50))
sp_main: begin
	# Check that person exists
	if ip_personID not in (select personID from person)
	then leave sp_main; end if;

	# Check that flight exists
	if ip_flightID not in (select flightID from flight)
	then leave sp_main; end if;

	# Handle pilots that are not assigned to any plane
	if ip_personID in (select personID from pilot where flying_tail is null) then
		
		# If the licenses match
		if (select license from pilot join pilot_licenses on pilot.personID = pilot_licenses.personID where pilot.personID = ip_personID) =
		(select plane_type from flight join airplane on (airplane.airlineID, airplane.tail_num) = (flight.support_airline, flight.support_tail) where flightID = ip_flightID) then
		   
		   # If the pilot is at the same location as the assigned flight, and they're in an airport currently
			if (select airportID from airport join person on airport.locationID = person.locationID where person.personID = ip_personID) =
				(select arrival from leg where legID like (select legID from flight join route_path on flight.routeID = route_path.routeID where sequence = progress and flightID = ip_flightID))
			then 
				update pilot set flying_airline = (select support_airline from flight where flightID = ip_flightID), flying_tail = (select support_tail from flight where flightID = ip_flightID) where personID = ip_personID;
				update person set locationID = (select locationID from airplane where tail_num = (select support_tail from flight where flightID = 'AM_1523')) where personID = ip_personID;
			end if;
		end if;
	end if;
end //
delimiter ;

-- [15] recycle_crew()
drop procedure if exists recycle_crew;
delimiter //
create procedure recycle_crew (in ip_flightID varchar(50))
sp_main: begin
	# Flight must be ended, that is, its current progress must equal the maximum sequence for it's route, and the plane must be on the ground
	if ip_flightID in (select flightID from flight where (routeID, progress) in
		(select routeID, max(sequence) from route_path group by routeID) and airplane_status = 'on_ground') then

		# Ensure that there are no passengers on board, that is, the count of locationIDs in the person table matching the plane's locationID is not greater than 0
		if (select count(locationID) from passenger join person on person.personID = passenger.personID group by locationID having locationID in 
			(select locationID from flight join airplane on (flight.support_airline, flight.support_tail) = (airplane.airlineID, airplane.tail_num) where flightID = ip_flightID)) > 0
		then 
			leave sp_main;
			
		# Otherwise, update info for correct pilots
		else
			update person set locationID = 
				(select locationID from airport where airportID in 
				(select arrival from leg where legID in
				(select legID from flight join route_path on flight.routeID = route_path.routeID where (route_path.routeID, progress) in 
				(select routeID, max(sequence) from route_path group by routeID) and progress = sequence and flightID = ip_flightID)))
				where personID in 
				(select personID from pilot where (flying_airline, flying_tail) = 
				(select flight.support_airline, flight.support_tail from flight join airplane on (flight.support_airline, flight.support_tail) = (airplane.airlineID, airplane.tail_num) where flightID = ip_flightID));
		
			update pilot set flying_tail = null, flying_airline = null where (flying_airline, flying_tail) in 
				(select flight.support_airline, flight.support_tail from flight join airplane on (flight.support_airline, flight.support_tail) = (airplane.airlineID, airplane.tail_num) where flightID = ip_flightID);
	end if;
	end if;
end //
delimiter ;

-- [16] retire_flight()
drop procedure if exists retire_flight;
delimiter //
create procedure retire_flight (in ip_flightID varchar(50))
sp_main: begin
	# Ensure flight exists
	if ip_flightID not in (select flightID from flight)
		then leave sp_main; end if;

	# Flight at beginning or end of route, and on the ground
	if ip_flightID in (select flightID from flight where (routeID, progress) in
		(select routeID, max(sequence) from route_path group by routeID) and airplane_status = 'on_ground')
		or (select progress from flight where flightID = ip_flightID) = 0
	then
		delete from flight where flightID = ip_flightID;
	end if;
end //
delimiter ;

-- [17] remove_passenger_role()
drop procedure if exists remove_passenger_role;
delimiter //
create procedure remove_passenger_role (in ip_personID varchar(50))
sp_main: begin
	# First, ensure the passenger exists
	if ip_personID not in (select personID from person)
		then leave sp_main; end if;

	# Check that the passenger is on the ground, otherwise leave
	if ip_personID not in (select personID from person where locationID in 
		(select * from location where locationID like 'port%' 
		union 
		select locationID from airplane join flight on (airplane.airlineID, airplane.tail_num) = (flight.support_airline, flight.support_tail) where airplane_status = 'on_ground')) 
	then leave sp_main; end if;

	# Check if the passenger is a pilot
	if ip_personID in (select personID from pilot)
		then delete from passenger where personID = ip_personID;
	else 
		delete from passenger where personID = ip_personID;
		delete from person where personID = ip_personID;
	end if;
end //
delimiter ;

-- [18] remove_pilot_role()
drop procedure if exists remove_pilot_role;
delimiter //
create procedure remove_pilot_role (in ip_personID varchar(50))
sp_main: begin		
	# Ensure the person exists
	if ip_personID not in (select personID from person)
	then leave sp_main; end if;

	# Handle pilots not assigned to flight that may or may not be passengers
	if ip_personID in (select personID from pilot where flying_tail is null) then
		if ip_personID in (select personID from passenger) then 
			delete from pilot_licenses where personID = ip_personID;
			delete from pilot where personID = ip_personID;
		else 
			delete from pilot_licenses where personID = ip_personID;
			delete from pilot where personID = ip_personID;
			delete from person where personID = ip_personID;
		end if;
	end if;

	# Handle pilots currently on a flight that may or may not be passengers
	if ip_personID in (select personID from pilot join flight on flying_tail = support_tail where progress = 0 or progress = (select progress from flight where (routeID, progress) in
	(select routeID, max(sequence) from route_path group by routeID) and airplane_status = 'on_ground')) then
		if ip_personID in (select personID from passenger) then 
			delete from pilot_licenses where personID = ip_personID;
			delete from pilot where personID = ip_personID;
		else 
			delete from pilot_licenses where personID = ip_personID;
			delete from pilot where personID = ip_personID;
			delete from person where personID = ip_personID;
		end if;
	end if;
end //
delimiter ;

-- [19] flights_in_the_air()
create or replace view flights_in_the_air (departing_from, arriving_at, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as
select 
	subquery.departing_from,
    subquery.arriving_at,
    count(subquery.flightID) as num_flights,
    group_concat(subquery.flightID) as flight_list,
    min(subquery.next_time) as earliest_arrival,
    max(subquery.next_time) as latest_arrival,
    group_concat(subquery.locationID) as airplane_list
from 
	(select 
		f.flightID,
		l.departure as departing_from,
		l.arrival as arriving_at,
		f.next_time,
		a.locationID
	from 
		flight f
        join route_path rp on (f.routeID, f.progress) = (rp.routeID,  rp.sequence)
        join leg l on rp.legID = l.legID
        join airplane a on (f.support_airline, f.support_tail) = (a.airlineID, a.tail_num)
	where 
		f.airplane_status = 'in_flight'
    ) as subquery
group by
    subquery.departing_from, subquery.arriving_at;

-- [20] flights_on_the_ground()
create or replace view flights_on_the_ground (departing_from, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as 
select 
	subquery.departing_from,
    count(subquery.flightID) as num_flights,
    group_concat(subquery.flightID) as flight_list,
    min(subquery.next_time) as earliest_arrival,
    max(subquery.next_time) as latest_arrival,
    group_concat(subquery.locationID) as airplane_list
from 
	(select 
		f.flightID,
		l.departure as departing_from,
		l.arrival as arriving_at,
		f.next_time,
		a.locationID
	from 
		flight f
		join route_path rp on f.routeID = rp.routeID and f.progress + 1 = rp.sequence
		join leg l on rp.legID = l.legID
		join airplane a on (f.support_airline, f.support_tail) = (a.airlineID, a.tail_num)
	where 
		f.airplane_status = 'on_ground'
    ) as subquery
group by
    subquery.departing_from;

-- [21] people_in_the_air()
create or replace view people_in_the_air (departing_from, arriving_at, num_airplanes,
	airplane_list, flight_list, earliest_arrival, latest_arrival, num_pilots,
	num_passengers, joint_pilots_passengers, person_list) as
select
	l.departure as departing_from,
	l.arrival as arriving_at,
	count(distinct f.flightID) as num_airplanes,
	group_concat(distinct a.locationID) as airplane_list,
    group_concat(distinct f.flightID) as flight_list,
	min(f.next_time) as earliest_arrival,
	max(f.next_time) as latest_arrival,
	sum(case when p.personID is not null then 1 else 0 end) as num_pilots,
	count(*) - sum(case when p.personID is not null then 1 else 0 end) as num_passengers,
	count(*) as joint_pilots_passengers,
	group_concat(pr.personID) as person_list
from
	flight f
	join route_path rp on f.routeID = rp.routeID and f.progress = rp.sequence
	join leg l on rp.legID = l.legID
	join airplane a on (f.support_airline, f.support_tail) = (a.airlineID, a.tail_num)
	join person pr on a.locationID = pr.locationID
	left join pilot p on pr.personID = p.personID
where
	f.airplane_status = 'in_flight'
group by
	l.departure, l.arrival; 

-- [22] people_on_the_ground()
create or replace view people_on_the_ground (departing_from, airport, airport_name,
	city, state, num_pilots, num_passengers, joint_pilots_passengers, person_list) as
select 
    ap.airportID as departing_from,
    ap.locationID as airport,
    ap.airport_name as airport_name,
    ap.city as city,
    ap.state as state,
    sum(case when p.personID is not null then 1 else 0 end) as num_pilots,
    sum(case when ps.personID is not null then 1 else 0 end) as num_passengers,
    count(*) as joint_pilots_passengers,
    group_concat(pr.personID) as person_list
from 
    person pr
    join airport ap on pr.locationID = ap.locationID
    left join pilot p on pr.personID = p.personID
    left join passenger ps on pr.personID = ps.personID
where
    pr.locationID like 'port_%'
group by
    ap.airportID;


-- [23] route_summary()
create or replace view route_summary (route, num_legs, leg_sequence, route_length,
	num_flights, flight_list, airport_sequence) as
select
    rp.routeID as route,
    count(distinct rp.legID) as num_legs,
    group_concat(rp.legID order by rp.sequence) as leg_sequence,
    sum(leg_details.distance) as route_length,
    ifnull(flight_summary.num_flights,0) as num_flights,
    flight_summary.flight_list as flight_list,
    group_concat(concat(leg_details.departure, '->', leg_details.arrival) order by rp.sequence) as airport_sequence
from
	route_path rp
    join (select
			l.legID,
            l.distance,
            l.departure,
            l.arrival
        from 
			leg l
        group by
            l.legID
    ) as leg_details on rp.legID = leg_details.legID
    left join (
        select
            routeID,
            count(distinct flightID) as num_flights,
            group_concat(distinct flightID) as flight_list
        from
            flight
        group by
            routeID
    ) as flight_summary on rp.routeID = flight_summary.routeID
group by
    rp.routeID;

-- [24] alternative_airports()
create or replace view alternative_airports (city, state, num_airports,
	airport_code_list, airport_name_list) as
select 
	city,
    state,
    count(*) as num_airports,
    group_concat(distinct airportID order by airportID) as airport_code_list,
    group_concat(distinct airport_name order by airportID) as airport_name_list
from 
	airport
group by
	city, state
having 
	num_airports > 1;

-- [25] simulation_cycle()
drop procedure if exists simulation_cycle;
delimiter //
create procedure simulation_cycle ()
sp_main: begin

	if (select count(flightID) from (select * from flight where next_time = (select min(next_time) from flight) order by flightID) as nexttimeflights) > 1 then
		set @min_plane = (select flightID from flight where next_time = (select min(next_time) from flight) order by airplane_status, flightID limit 1);
	else set @min_plane = (select flightID from flight where next_time = (select min(next_time) from flight) order by flightID);
    end if;
	if (select airplane_status from flight where flightID = @min_plane) = 'in_flight'
		then call flight_landing(@min_plane); 
        call passengers_disembark(@min_plane); end if;
	if @min_plane in (select flightID from flight where airplane_status = 'on_ground' and (routeID, progress) in
		(select routeID, max(sequence) from route_path group by routeID))
        then call recycle_crew(@min_plane);
        call retire_flight(@min_plane); 
        leave sp_main; end if;
	if (select airplane_status from flight where flightID = @min_plane) = 'on_ground'
		then call passengers_board(@min_plane);
        call flight_landing(@min_plane); end if;
	
end //
delimiter ;
