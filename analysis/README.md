Time to do the analysis!
The first track of this will be just with the CSV files. I may want
to do more work in R, but this is a first step.

Inputs:

- Parsed candidate financial disclosure data, keyed by DocID (pfd_final.csv)
- PFD candidate lists (map from DocID to candidate name/district) (ipython/2017FD.txt, ipython/2018FD.txt)
- Candidate fundraising data from DIME (candsWithTotals.csv)

Goal:

1.  Construct a crosswalk from PFD DocIDs to DIME RIDs
2.  Merge the data sets
3.  Do some plots and analysis
4.  Validate the data
5.  Throw in some controls
6.  Clean up and explain the code
