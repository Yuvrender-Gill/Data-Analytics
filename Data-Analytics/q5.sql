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
DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS winner_vote_count CASCADE;
DROP VIEW IF EXISTS parties_in_alliance CASCADE;
DROP VIEW IF EXISTS winner_elections CASCADE;
DROP VIEW IF EXISTS alliance_votes_helper CASCADE;
drop view if exists alliance_vote_count cascade;
drop view if exists party_cote_count cascade;
drop view if exists alliance_head cascade;
DROP VIEW IF EXISTS winner_alliance CASCADE;

-- get  all of the  winning  parties  based on the  cabinet
create  view  election_winners  as
	select  election.id as  election_id , cabinet_party.party_id
	from  election  join  cabinet
		on  election.id = cabinet.election_id
	join  cabinet_party
		on  cabinet.id = cabinet_party.cabinet_id
	where  cabinet_party.pm = true; 

--Define a view to get the vote count of the winner parties
CREATE VIEW winner_vote_count as 
	SELECT er.election_id AS election_id, er.party_id AS party_id, case when er.votes is not null then er.votes else 0 end as votes, er.alliance_id, er.id as election_result_id 
        FROM election_result er join election_winners 
		on er.election_id = election_winners.election_id
        	and er.party_id = election_winners.party_id;

create view alliance_vote_count as
	select * 
	from winner_vote_count
	where alliance_id is not null 
	 ; 

create view party_vote_count as 
	select *
	from winner_vote_count 
	where alliance_id is null;

create view alliance_head as
	select p.party_id, p.election_id, p.votes, p.alliance_id, p.election_result_id  
	from alliance_vote_count a join party_vote_count p  on a.alliance_id = p.election_result_id
	;

create view alliance_total_vote as
	select alliance_id, sum(votes) as alliance_votes
	from alliance_vote_count
	group by alliance_id;  

create view alliance_head_vote_count as
	select ah.party_id, ah.election_id, ah.votes + atv.alliance_votes  as votes, ah.alliance_id, ah.election_result_id  
	from alliance_head ah join alliance_total_vote atv on ah.election_result_id  = atv.alliance_id

	; 

create view winner_vote_final as
	select wvc.election_id, wvc.party_id, case when ah.alliance_id = wvc.election_result_id then ah.votes else wvc.votes end as votes, wvc.election_result_id
 	from winner_vote_count wvc, alliance_head ah;
--A comparision table for the election id and votes count and party id 
CREATE VIEW comparision_table as
	SELECT wc.election_id AS Welection, er.election_id AS Eelection,
	       wc.votes AS Wvotes, er.votes AS Evotes,
               wc.party_id AS winner_party, er.party_id AS looser_party
	FROM winner_vote_count wc join election_result er
		on wc.election_id =  er.election_id
        WHERE wc.party_id <> er.party_id; 
	
--Get the pids of the table with less than 10% 
CREATE VIEW percent as
	SELECT DISTINCT *
	FROM comparision_table ct
	WHERE (ct.wvotes - ct.evotes) < (ct.wvotes * 0.1) 
               AND (ct.wvotes - ct.evotes) >= 0;
	
--Alliance votes
CREATE VIEW alliance_votes_helper as
	SELECT alliance_id,CASE WHEN SUM(CASE WHEN votes is NULL THEN 1 ELSE 0 END) >= 1 THEN 1 ELSE SUM(votes) END as votes
	FROM election_result
	GROUP BY alliance_id;
-- This query aggrigates all the alliances and their vote counts and accounts 
-- for the null values
CREATE VIEW alliance_votes as 
	SELECT election_id, party_id, id AS alliance_id, CASE WHEN election_result.votes is NOT NULL 
							 THEN(election_result.votes+ alliance_votes_helper.votes) 
                                                         ELSE 0 END AS votes 
	FROM election_result join alliance_votes_helper
		on election_result.id = alliance_votes_helper.alliance_id;

CREATE VIEW alliance_winner_party as
	SELECT ew.party_id, ew.election_id, av.alliance_id, av.votes
	FROM election_winners ew join alliance_votes av 
		on  ew.party_id = av.party_id
	WHERE ew.election_id = av.election_id;
--================================================================================
-- Define views for your intermediate steps here.
create view parties_in_alliance as 
	select election_result.alliance_id AS a_id, election_result.party_id AS p_id
	FROM election_result
	WHERE election_result.alliance_id IS NOT NULL
	ORDER BY election_result.alliance_id;



-- election_result entries with winners
create  view  winner_elections  as
	SELECT election_result.party_id, election_result.election_id, election_result.votes, election_result.alliance_id
	FROM election_result, election_winners
	WHERE election_result.election_id = election_winners.election_id
		AND election_result.party_id = election_winners.party_id;

-- Alliance ids of the winner alliances
create view winner_alliance as
	SELECT a_id, parties_in_alliance.p_id
	FROM parties_in_alliance join election_winners
		on parties_in_alliance.p_id = election_winners.party_id
	ORDER BY a_id;
-- entries with no winners
create view loosers as 
	SELECT party_id, election_id
	FROM election_result
	
	
	EXCEPT

	SELECT party_id, election_id
	FROM winner_elections;
	
	
 
-- the answer to the query 
--insert into q5 
