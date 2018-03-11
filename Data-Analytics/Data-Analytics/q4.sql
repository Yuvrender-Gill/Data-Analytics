SET SEARCH_PATH TO parlgov;
drop table if exists q4 cascade;

-- You must not change this table definition.


CREATE TABLE q4(
country VARCHAR(50),
num_elections INT,
num_repeat_party INT,
num_repeat_pm INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS num_parl_elections CASCADE;
DROP VIEW IF EXISTS winners_per_country CASCADE;
DROP VIEW IF EXISTS winners_per_country_order CASCADE;
DROP VIEW IF EXISTS consecutive_parties CASCADE;
DROP VIEW IF EXISTS consecutive_party_count CASCADE;
DROP VIEW IF EXISTS prime_minister_name CASCADE;
DROP VIEW IF EXISTS consecutive_party_count CASCADE;
DROP VIEW IF EXISTS pm CASCADE;
DROP VIEW IF EXISTS pm_count CASCADE;
DROP VIEW IF EXISTS pm_count_n CASCADE;
DROP VIEW IF EXISTS join_all CASCADE;


-- get  all of the  winning  parties  based on the  cabinet
create  view  election_winners  as
	select  distinct election.id as  election_id , cabinet_party.party_id
	from  election  join  cabinet
		on  election.id = cabinet.election_id
	join  cabinet_party
		on  cabinet.id = cabinet_party.cabinet_id
	where  cabinet_party.pm = true;

--Get the number of parliamentary elections for the country
CREATE VIEW num_parl_elections as
	select c.name as country, count(*) as num_elections
	from election e join country c 
		on c.id = e.country_id
	where e.e_type = 'Parliamentary election'
	group by c.id;

-- Getting third attribute
-- Get the winner party ids per country
CREATE VIEW winners_per_country as

	(SELECT ew.election_id, ew.party_id, e.country_id, e.e_date, e.previous_parliament_election_id, e2.e_date as prev_date
	from election_result er 
		join election_winners ew 
			on er.election_id = ew.election_id 
			and er.party_id = ew.party_id
		join election e 
			on e.id = er.election_id
		join election e2
			on e2.id = e.previous_parliament_election_id
	
	
	UNION ALL

	SELECT ew.election_id, ew.party_id, e.country_id, e.e_date, e.previous_parliament_election_id, null
	from election_result er
		join election_winners ew 
			on er.election_id = ew.election_id 
			and er.party_id = ew.party_id
		join election e 
			on e.id = er.election_id
	where e.previous_parliament_election_id is null);

-- order the previous table					
CREATE VIEW winners_per_country_order as
	select * 
	from winners_per_country
	order by country_id, e_date;
	
--comapre the parties from the previous and current elections
CREATE VIEW consecutive_parties as 
	select e.election_id, e.party_id, ew.party_id as previous_party, e.country_id, e.e_date, e.previous_parliament_election_id,  e.prev_date as prev_date
	from winners_per_country_order e join election_winners ew 
		on ew.election_id = e.previous_parliament_election_id
	order by e.country_id, e.e_date;

--complete part 2
CREATE VIEW consecutive_party_count as 
	select  c.name as country, count(*) as num_repeat_party
	from consecutive_parties cp
		join country c
			on cp.country_id = c.id
	where previous_party = party_id
	group by c.name; 

--getting fourth attribute
--
CREATE VIEW prime_minister_name as
	select c.id as cabinet_id, c.country_id, regexp_replace(c.name::text, '([A-Za-z]*?)[ IV]+$', '\1') as name , c.start_date
	from cabinet c 
	order by country_id, start_date;

create view pm as
	select country_id, name, start_date
	from prime_minister_name pm join cabinet_party cp
		on pm.cabinet_id = cp.cabinet_id
	where pm = 't'
	order by country_id, start_date;

create view pm_count as
	select distinct p1.country_id, p1.name, p1.start_date
	from pm p1 join pm p2 on p1.country_id = p2.country_id
		and p1.name = p2.name
	where p1.start_date <> p2.start_date
	order by p1.country_id;

create view pm_count_n as
	select c.name as country, count(distinct pc.name) as num_repeat_pm
	from pm_count pc 
		join country c
			on pc.country_id = c.id
	group by c.name;

create view join_all as
	select pc.country, num_elections, num_repeat_party, num_repeat_pm
	from  pm_count_n pc join
		consecutive_party_count cpc on pc.country = cpc.country
		join num_parl_elections npe on  npe.country = pc.country;






--Get the number of for a country the election
-- the answer to the query 
INSERT INTO q4(select * from join_all); 

