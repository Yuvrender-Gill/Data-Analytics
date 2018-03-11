SET SEARCH_PATH TO parlgov;
drop table if exists q2 cascade;

-- You must not change this table definition.

create table q2(
country VARCHAR(50),
electoral_system VARCHAR(100),
single_party INT,
two_to_three INT,
four_to_five INT,
six_or_more INT
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS winner_countries CASCADE;
DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS agger_alliance CASCADE;
DROP VIEW IF EXISTS winner_countries_count CASCADE;
DROP VIEW IF EXISTS single CASCADE;
DROP VIEW IF EXISTS two_three CASCADE;
DROP VIEW IF EXISTS four_five CASCADE;
DROP VIEW IF EXISTS more_than_six CASCADE;
DROP VIEW IF EXISTS join_all CASCADE;

-- get all of the winning parties based on the cabinet
create view election_winners as
	select election.id as election_id , cabinet_party.party_id
	from election 
			join cabinet
				on election.id = cabinet.election_id
			join cabinet_party
				on cabinet.id = cabinet_party.cabinet_id
	where cabinet_party.pm = true ;

-- get the parties election ids for parliamentary elections
CREATE VIEW winner_countries AS
	SELECT er.election_id, er.party_id, CASE WHEN er.alliance_id is NULL THEN er.id ELSE er.alliance_id END AS alliance_id, e.country_id, er.id as erid
	FROM election_result er 
		join election e
			on e.id = er.election_id  
	where e.e_type = 'Parliamentary election'
	order by e.country_id;

-- get the party count per alliance
CREATE VIEW agger_alliance AS
	SELECT alliance_id AS all_id, count(*) as party_count
	FROM winner_countries
	GROUP BY alliance_id;

-- get the count of the parties which won the election
CREATE VIEW winner_countries_count AS
	SELECT wc.election_id, wc.party_id, alliance_id, country_id, erid, party_count
	FROM winner_countries wc 
		join agger_alliance aa
			on wc.alliance_id = aa.all_id
		join election_winners ew
			on wc.election_id = ew.election_id
			and wc.party_id = ew.party_id
	ORDER BY country_id;

-- get the single party count
CREATE VIEW single AS 
	SELECT country_id as id, COUNT(*)  as single_party
	from winner_countries_count
	where party_count = 1
	GROUP BY country_id;

-- get the four or five party count governments
CREATE VIEW four_five AS 
	SELECT country_id as id, COUNT(*)  as four_to_five
	from winner_countries_count
	where party_count = 4 or party_count = 5
	GROUP BY country_id;

-- get the govenrments with two or three parties
CREATE VIEW two_three AS 
	SELECT country_id as id, COUNT(*)  as two_to_three
	from winner_countries_count
	where party_count = 2 or party_count = 3
	GROUP BY country_id;

-- get the goventments with six or more parties
CREATE VIEW more_than_six AS 
	SELECT country_id as id, COUNT(*)  as six_or_more
	from winner_countries_count
	where party_count >= 6
	GROUP BY country_id;

-- join all the sub view to get the final format
CREATE VIEW join_all AS
	SELECT c.name AS country, c.electoral_system, 
		CASE when single_party is null then 0 else single_party end as single_party, 
		CASE when two_to_three is null then 0 else two_to_three end as two_to_three, 
		CASE when four_to_five is null then 0 else four_to_five end as four_to_five, 
		CASE when six_or_more is null then 0 else six_or_more end as six_or_more
	FROM country c natural left join single s  
		      natural left join two_three tt
		      natural left join four_five ff 
		      natural left join more_than_six mts 
		      ;		


--============================================================================================================

insert into q2(select * from join_all); 


