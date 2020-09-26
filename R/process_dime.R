library(RSQLite)
library(sqldf)
library(data.table)

path <- 'D:/Desktop/work/ddrl_rdata/'

##Connecting to SQLite DB
con <- dbConnect(RSQLite::SQLite(), paste0(path,"dime.sqlite3"))

##list tables
dbListTables(con)

##show variables in candDB
cand.vars <- dbGetQuery(con,"select * from candDB limit 10")
print(cand.vars)


##show variables in contribDB
contrib.vars <- dbGetQuery(con,"select * from contribDB limit 10")
print(contrib.vars)


##show variables in donorDB
disb.vars <- dbGetQuery(con,"select * from donorDB limit 10")
print(disb.vars)



# Pull house candidate data for 2018
# TODO: need to handle .s instead of _s in names
cands <- dbGetQuery(con,"
  SELECT election, cycle, bonica_rid, 
    name, lname, ffname, fname, mname, nname, title, suffix, cand_gender,
    party, state, seat, district, incum_chall,
    recipient_cfscore, dwnom1, recipient_type,
    num_givers, total_disbursements, contribs_from_candidate, 
    non_party_ind_exp_for, ind_exp_for, comm_cost_for, party_coord_exp,
    total_receipts, total_indiv_contrib, total_pac_contribs,
    ran_primary, ran_general, p_elec_stat, gen_elec_stat, gen_elect_pct, winner 
  FROM candDB 
  WHERE cycle == 2018 AND seat == 'federal:house'")

# In addition to total raised, we want sum of contributions in primary only,
# and sum of contributions in first 90 days of campaign.
dbGetQuery(con, "
  SELECT `bonica.rid`, SUM(amount) FROM contribDB 
    WHERE `election.type` = 'P'
    GROUP BY `bonica.rid`")

# First subset to list of candidates
query <- "
  SELECT rid, sum(amount) FROM
    (SELECT * FROM
      (SELECT `bonica.rid` as rid FROM candDB 
        WHERE cycle == 2018 AND seat == 'federal:house') as cands
      LEFT JOIN (select * from contribDB limit 10000) as contribdb
      ON rid == contribDB.`bonica.rid`) as contribs
  GROUP BY rid
  LIMIT 10
  "
dbGetQuery(con, query)

# Try to get first contribution date
query <- "
  CREATE TABLE IF NOT EXISTS campaign_dates AS
    SELECT
      rid,
      sum(amount) as total_primary,
      min(date) as campaign_start,
      date(min(date), '90 days') as campaign_ninety
    FROM
      (
        SELECT * FROM
        (
          SELECT `bonica.rid` as rid FROM candDB
            WHERE cycle == 2018 AND seat == 'federal:house'
        ) as cands
        LEFT JOIN
        (
          select * from contribDB WHERE `election.type` = 'P'
        ) as contribdb
        ON rid == contribDB.`bonica.rid`
      ) as contribs
    GROUP BY rid
  "
dbExecute(con, query)

# Now do it again and aggregate everything within the first ninety days.
query <- "
  SELECT * FROM 
  (
    SELECT
      campaign_dates.*, sum(amount) as total_ninety
    FROM
      (
        campaign_dates
        LEFT JOIN
        (
          select * from contribDB WHERE `election.type` = 'P'
        ) as contribdb
        ON rid == contribDB.`bonica.rid` AND contribDB.date <= campaign_ninety
      ) as contribs
    GROUP BY rid
  ) as contribs
  LEFT JOIN candDB ON candDB.`bonica.rid` == contribs.rid
  "
candsWithTotals <- dbGetQuery(con, query)

save(candsWithTotals, file=paste(path, 'candsWithTotals.rdata'))
write.csv(candsWithTotals, paste(path, 'candsWithTotals.csv'))
