SET SEARCH_PATH TO parlgov;
drop table if exists q7 cascade;

-- You must not change this table definition.

DROP TABLE IF EXISTS q7 CASCADE;
CREATE TABLE q7(
partyId INT, 
partyFamily VARCHAR(50) 
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS parl_elections CASCADE;
drop view if exists euro_elections cascade;
drop view if exists election_winners cascade;
drop view if exists winner_parties CASCADE;
drop view if exists compare_elections cascade; 
drop view if exists within_range cascade;
drop view if exists before_first_euro cascade;
-- Define views for your intermediate steps here.
CREATE OR REPLACE view parl_elections as
	select id as election_id, e_date as election_date, previous_parliament_election_id, previous_ep_election_id
	from election
	where e_type = 'Parliamentary election'

	order by e_date, id;

CREATE OR REPLACE view euro_elections as
	select id as election_id, e_date as election_date,  previous_parliament_election_id, previous_ep_election_id
	from election
	where e_type = 'European Parliament'
	order by e_date;
-- get all of the winning parties based on the cabinet
create view election_winners as
        select election.id as election_id , cabinet_party . party_id
	from election join cabinet
		on election.id = cabinet.election_id
		join cabinet_party
		on cabinet.id = cabinet_party.cabinet_id
	where cabinet_party.pm = true ;
 
Create view winner_parties as
	SELECT er.election_id, er.party_id, e.e_date, e.e_type, e.previous_parliament_election_id, e.previous_ep_election_id
	FROM election_result er join election_winners ew
		on er.election_id = ew.election_id
		and er.party_id = ew.party_id
		join election e on er.election_id = e.id
	order by e.e_date;  

create view compare_elections as
	select wp.election_id as parl_election, wp.party_id, wp.e_date as parl_date, ee.election_id as euro_election_id, ee.election_date as euro_date, ee2.election_date as prev_euro_date
	from winner_parties wp, euro_elections ee join euro_elections ee2
		on ee.previous_ep_election_id = ee2.election_id
	order by wp.party_id, wp.e_date, ee.election_date;

create view within_range as
	select party_id as pid, count(distinct parl_date)  as times
	from compare_elections    
	where parl_date >= prev_euro_date and parl_date < euro_date
	group by party_id;

create view before_first_euro as
	select distinct party_id, 1 as occur 
	from compare_elections 
	where parl_date < (select min(election_date) from euro_elections)
	;
create view in_every_election as
	select wr.pid as partyID, family partyFamily
	from within_range wr join before_first_euro bfe
		on wr.pid = bfe.party_id
		join party_family pf 
		on pf.party_id = wr.pid
	where times + occur >= (select count(distinct election_date) from euro_elections) 
	order by pid; 

--create view before_first_euro_elections as
--	select party_id, parl_date
--	from compare_elections
	
	-- the answer to the query 
insert into q7(select * from in_every_election); 
