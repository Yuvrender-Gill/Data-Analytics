SET SEARCH_PATH TO parlgov;
drop table if exists q5 cascade;

-- You must not change this table definition.

CREATE TABLE q5(
electionId INT, 
countryName VARCHAR(50),
winningParty VARCHAR(100),
closeRunnerUp VARCHAR(100)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS alliances CASCADE;
DROP VIEW IF EXISTS party_vote_count CASCADE;
DROP VIEW IF EXISTS alliance_vote_count CASCADE;
DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS parliamentary_elections CASCADE;
DROP VIEW IF EXISTS parliament_winners CASCADE; 
DROP VIEW IF EXISTS winner_alliance_votes CASCADE;
DROP VIEW IF EXISTS losers CASCADE;
DROP VIEW IF EXISTS losers_votes CASCADE;
DROP VIEW IF EXISTS comparision_table CASCADE;
DROP VIEW IF EXISTS winner_alliance_head_names CASCADE;
DROP VIEW IF EXISTS join_all CASCADE;

-- Make a new table with all the alliances and  replace the null values with correct alliance ids
CREATE VIEW alliances AS
	SELECT election_id, party_id, CASE WHEN alliance_id IS NULL THEN id ELSE alliance_id END AS alliance_id, votes
	FROM election_result;

-- UPdate the alliances by padding vote count to 0 if vote count is null
CREATE VIEW party_vote_count AS
	SELECT election_id, party_id, alliance_id, CASE WHEN votes IS NULL THEN 0 ELSE votes END
	FROM alliances;

-- Get the vote count for every alliance per elections
CREATE VIEW alliance_vote_count AS
	SELECT election_id, alliance_id, sum(votes) as votes
	FROM party_vote_count
	GROUP BY election_id, alliance_id;

-- get all of the winning parties based on the cabinet
CREATE VIEW election_winners AS
	select election.id as election_id, cabinet_party.party_id
	from election 
		join cabinet
			on election.id = cabinet.election_id
		join cabinet_party
			on cabinet.id = cabinet_party.cabinet_id
	where cabinet_party.pm = true;

-- Get the country names for all the parliamentary elections with corresponding election ids  
CREATE VIEW parliamentary_elections AS
	SELECT e.id AS election_id, c.name as countryName
	FROM election e JOIN country c 
			ON e.country_id = c.id 
	WHERE e_type = 'Parliamentary election';

-- Get all the parliamentary winners along with their countries
CREATE VIEW parliament_winners AS
	SELECT * 
	FROM parliamentary_elections 
			NATURAL LEFT JOIN election_winners;

-- Get all winner alliances with their votes
CREATE VIEW winner_alliance_votes AS
	SELECT election_id, countryName, party_id, alliance_id, votes
	FROM parliament_winners
		NATURAL LEFT JOIN (SELECT election_id, party_id, alliance_id FROM party_vote_count) ls
		NATURAL LEFT JOIN alliance_vote_count;

-- Get all the loosing parties
CREATE VIEW losers as 
	SELECT pvc.election_id, pvc.party_id, pvc.alliance_id 
	FROM party_vote_count pvc 
		JOIN (SELECT distinct * FROM winner_alliance_votes) as  wav
			ON pvc.election_id = wav.election_id
			AND pvc.alliance_id <> wav.alliance_id
			AND pvc.party_id <> wav.party_id ;


-- Get all losers (parties that were not in cabinet) with their votes
CREATE VIEW losers_votes AS
	SELECT * 
	FROM losers NATURAL LEFT JOIN alliance_vote_count;

-- Compare all the winners and losers to get the close runner ups
CREATE VIEW comparision_table AS
	SELECT distinct wav.election_id, countryName, wav.party_id AS winning_party_id, wav.votes AS wvotes, lv.alliance_id AS cru_alliance_id, lv.votes AS lvotes
	FROM winner_alliance_votes wav
		JOIN losers_votes lv 
			ON lv.election_id = wav.election_id
	where lv.votes < wav.votes AND lv.votes > (wav.votes * 0.9);

CREATE VIEW maximum as	
	SELECT election_id, countryName, winning_party_id, wvotes, max(lvotes) AS lvotes
	FROM comparision_table
	GROUP BY election_id, countryName, winning_party_id, wvotes;

-- Get winners with Max runner ups
CREATE OR REPLACE VIEW max_runner AS
	SELECT *
	FROM
		(SELECT election_id, countryName, winning_party_id AS party_id, wvotes, cru_alliance_id, lvotes
		FROM maximum NATURAL LEFT JOIN comparision_table) 
		NATURAL LEFT JOIN parliament_winners;

-- Get all the winner party and alliance names
CREATE VIEW winner_party_names AS 
	SELECT election_id, countryName, name as winningParty, cru_alliance_id AS alliance_id
	FROM max_runner NATURAL LEFT JOIN
		 (SELECT id as party_id, name FROM party) AS party_names;

-- Get all the alliance head names
CREATE VIEW winner_alliance_head_names AS	
	SELECT alliance_id, name AS closeRunnerUp
	FROM (SELECT id AS alliance_id, party_id as id FROM election_result) alliance_parties
			NATURAL LEFT JOIN
			party;

-- FINALLY JOIN ALL THE SUB VIEW TO GET THE FINAL ANSWER 
CREATE OR REPLACE VIEW join_all AS
	SELECT election_id AS electionId, countryName, winningParty, closeRunnerUp
	FROM winner_party_names
		 NATURAL LEFT JOIN
		 winner_alliance_head_names;


-- the answer to the query 
insert into q5 (SELECT * FROM join_all);
