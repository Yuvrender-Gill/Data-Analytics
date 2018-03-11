SET SEARCH_PATH TO parlgov;
drop table if exists q3 cascade;

-- You must not change this table definition.

create table q3(
country VARCHAR(50), 
num_dissolutions INT,
most_recent_dissolution DATE, 
num_on_cycle INT,
most_recent_on_cycle DATE
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
drop view if exists election_year cascade;
drop view if exists compare_election cascade;
drop view if exists compare_election_cycle cascade;
drop view if exists elections_per_country cascade;
drop view if exists election_oncycle_count cascade;
drop view if exists election_offcycle_count cascade;
drop view if exists recent_oncycle cascade;
drop view if exists recent_offcycle cascade;
drop view if exists recent_oncycle_election cascade;
drop view if exists recent_oncycle_year cascade;
drop view if exists recent_offcycle_election cascade;
drop view if exists recent_offcycle_year cascade;
drop view if exists join_cycle cascade;
drop view if exists final cascade;

-- Define views for your intermediate steps here.

create view election_year as
	select e.country_id, e.id, extract(year from e.e_date) as election_year, c.election_cycle, c.name
	from country c join election e on c.id = e.country_id
	order by c.id, extract(year from e.e_date) ;

--
create view compare_election as
	select e.id, e.previous_parliament_election_id, f.id as fid, extract(year from e.e_date) - extract(year from f.e_date) as time_diff, e.country_id, extract(year from e.e_date) as election_year, e.e_date as election_date
        from election e join election f on f.id = e.previous_parliament_election_id
	where e.e_type = 'Parliamentary election' and f.e_type = 'Parliamentary election'

        UNION 
	select e.id, e.previous_parliament_election_id, null, null, e.country_id, extract(year from e.e_date) as election_year, e.e_date as election_date
	from election e
	where e_type = 'Parliamentary election' and previous_parliament_election_id is null     
 	;
--
create view compare_election_cycle as
	select e.id as election_id, e.previous_parliament_election_id, fid, time_diff, country_id, c.election_cycle, e.election_year, e.election_date
	from compare_election e join country c on e.country_id = c.id
        order by country_id, e.election_year
	;

--
create view elections_per_country as
	SELECT c.id, c.name, c.election_cycle, count(e.id) as total_count   
	FROM country c join compare_election e on c.id = e.country_id
      	group by c.id;

--
create view election_oncycle as
	select country_id, election_year, election_id, election_date
	from compare_election_cycle
	where time_diff is NULL or time_diff  = election_cycle;

--
create view election_offcycle as
	select country_id, election_year, election_id, election_date
	from compare_election_cycle
	where time_diff is not NULL and time_diff  <> election_cycle;

--
create view recent_oncycle_year as
	select country_id, max(election_year) as election_year
	from election_oncycle
	group by country_id;

--
create view recent_oncycle_election as
	select r.country_id, e.election_id, e.election_date  
	from recent_oncycle_year r join election_oncycle e on r.country_id = e.country_id
	where r.election_year = e.election_year;

--
create view recent_offcycle_year as
	select country_id, max(election_year) as election_year
	from election_offcycle
	group by country_id; 

--
create view recent_offcycle_election as
	select r.country_id, e.election_id, e.election_date  
	from recent_offcycle_year r join election_offcycle e on r.country_id = e.country_id
        where r.election_year = e.election_year  ;



--
create view election_oncycle_count as
	select c.country_id, count(c.election_id) as on_cycle
	from compare_election_cycle c
	where c.time_diff is NULL or c.time_diff = c.election_cycle
	group by c.country_id; 

--
create view election_offcycle_count as 
	select eoc.country_id, epc.total_count - eoc.on_cycle as off_cycle
        from election_oncycle_count eoc join elections_per_country epc on epc.id = eoc.country_id;    

--
create view join_cycle as
	select e.country_id,c.name as country, e.on_cycle as num_on_cycle, f.off_cycle as num_dissolutions,ron.election_date as most_recent_on_cycle, roff.election_date as most_recent_dissolution   
	from election_oncycle_count e join election_offcycle_count f on e.country_id = f.country_id
             join country c on e.country_id = c.id join recent_offcycle_election roff on roff.country_id = e.country_id join recent_oncycle_election ron on ron.country_id = e.country_id  ;  

CREATE VIEW final AS 
	SELECT country, num_dissolutions, most_recent_dissolution, num_on_cycle, most_recent_on_cycle
	FROM join_cycle;
-- the answer to the query 
insert into q3(SELECT * from final); 

