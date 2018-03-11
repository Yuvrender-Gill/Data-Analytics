SET SEARCH_PATH TO parlgov;
drop table if exists q6 cascade;

-- You must not change this table definition.

CREATE TABLE q6(
countryId INT,
partyName VARCHAR(10),
number INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS elections_by_date CASCADE;
DROP VIEW IF EXISTS election_year CASCADE;
DROP VIEW IF EXISTS compare_election CASCADE;
DROP VIEW IF EXISTS get_party_id CASCADE;
DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS winner_parties CASCADE;

-- get  all of the  winning  parties  based on the  cabinet for parliamentary elections 
create  view  election_winners  as
	select  election.id as  election_id , cabinet_party.party_id
	from  election  join  cabinet
		on  election.id = cabinet.election_id
	join  cabinet_party
		on  cabinet.id = cabinet_party.cabinet_id
	where  cabinet_party.pm = true and e_type='Parliamentary election'; 

create view election_winner_parties as
	SELECT e.id as election_result_id, e.election_id, e.party_id, e.alliance_id
	from election_result e join election_winners ew 
					on e.election_id = ew.election_id 
	where e.party_id = ew.party_id;
 
create view election_year as
	select e.country_id, e.id, extract(year from e.e_date) as election_year
	from country c join election e on c.id = e.country_id
	order by c.id, extract(year from e.e_date) ;

--
create view compare_election as
	select e.id, e.previous_parliament_election_id, f.id as fid, e.country_id, e.e_date as election_date
        from election e join election f on f.id = e.previous_parliament_election_id
	where e.e_type = 'Parliamentary election' and f.e_type = 'Parliamentary election'

        UNION 
	select e.id, e.previous_parliament_election_id, null,  e.country_id, e.e_date as election_date
	from election e
	where e_type = 'Parliamentary election' and previous_parliament_election_id is null     
 	;

create view opt_compare as
	select distinct c.id, c.previous_parliament_election_id, c.fid, c.country_id, c.election_date
	from compare_election c join election_winner_parties e on c.id = e.election_id
	where c.
	order by country_id, election_date;

-- Define views for your intermediate steps here.
CREATE VIEW elections_by_date AS
	SELECT election.id AS election_id, country_id, e_date, previous_parliament_election_id AS ppeid
	FROM election
	WHERE e_type='Parliamentary election'
	ORDER BY e_date;

--Election and party id of winners
CREATE VIEW get_party_id AS
	SELECT e.election_id AS election_id, e.country_id AS country_id, e.e_date AS e_date, er.party_id AS party_id, e.ppeid
	FROM elections_by_date e join election_result er
		ON e.election_id = er.election_id;

--Election ids and party ids in chronological order for the winners
CREATE VIEW winner_parties AS
	SELECT DISTINCT *
	FROM (
	SELECT e.election_id AS election_id, e.country_id AS country_id, e.e_date AS e_date, e.party_id AS party_id, e.ppeid
	FROM get_party_id e join election_winners ew
		ON e.election_id = ew.election_id
	WHERE e.party_id = ew.party_id) wps
	ORDER BY wps.party_id, wps.e_date;

-- Winner parties grouped by the elections 
CREATE VIEW match_prev AS
	SELECT DISTINCT * FROM (
	SELECT e.election_id AS election_id, e.country_id AS country_id, e.e_date AS e_date, e.party_id AS party_id, e.ppeid, wps2.ppeid AS wppeid, wps2.election_id as elecid
	FROM winner_parties e, winner_parties wps2
	WHERE e.election_id = wps2.election_id )wps
	ORDER BY wps.election_id, wps.ppeid, wps.party_id;

--Count the elections 
CREATE VIEW counter AS
	SELECT party_id, count(election_id)
	FROM match_prev
	GROUP BY party_id;
-- the answer to the query 
--insert into q6 
