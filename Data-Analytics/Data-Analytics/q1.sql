SET SEARCH_PATH TO parlgov;
drop table if exists q1 cascade;

-- You must not change this table definition.

create table q1(
century VARCHAR(2),
country VARCHAR(50), 
left_right REAL, 
state_market REAL, 
liberty_authority REAL
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS test CASCADE;

-- get  all of the  winning  parties  based on the  cabinet
create  view  election_winners  as
	select  election.id as  election_id , cabinet_party.party_id
	from  election  join  cabinet
		on  election.id = cabinet.election_id
	join  cabinet_party
		on  cabinet.id = cabinet_party.cabinet_id
	where  cabinet_party.pm = true;

-- Define views for your intermediate steps here.
CREATE VIEW winner_parties AS
	SELECT election_result.party_id
	FROM election_winners join election_result 
		on election_result.election_id = election_winners.election_id
        where election_result.party_id = election_winners.party_id;

-- Define views for your intermediate steps here.
CREATE VIEW winner_alliance AS
	SELECT election_result.alliance_id
	FROM election_winners join election_result 
		on election_result.election_id = election_winners.election_id
	where election_result.party_id = election_winners.party_id;

-- Define views for your intermediate steps here.
CREATE VIEW test AS
	SELECT election_result.election_id AS election_id, DISTINCT election.e_date
	FROM election_result join election
		on election_result.election_id = election.id
	where election.e_type='Parliamentary election'
	ORDER BY election.e_date, election_result.election_id;
-- the answer to the query 
--insert into q1 (SELECT * FROM election_winners);

