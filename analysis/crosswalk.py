import numpy as np
import pandas as pd

# Input: 2017/2018 candidate PFD manifest
# Input: DIME candidates list

# Output: m:1 mapping of DocID to rid

# Should really be doing this separately from parsing the other files, but...


def main():
    # Read in financial disclosure form manifest
    df_disclosures_2018 = pd.read_csv("../ipython/2018FD.txt", delimiter="\t")
    df_disclosures_2017 = pd.read_csv("../ipython/2017FD.txt", delimiter="\t")
    df_disclosures = pd.concat([df_disclosures_2018, df_disclosures_2017])
    df_disclosures = df_disclosures.astype({"DocID": np.int32})
    # We only want initial filings (probably)
    df_disclosures = df_disclosures[df_disclosures["FilingType"] == "C"]

    # Lowercase the names:
    df_disclosures["Last"] = df_disclosures["Last"].str.lower()

    # Read in candidates list from DIME
    df_dime = pd.read_csv("../candsWithTotals.csv")
    # Extract only the fields we care about for the crosswalk:
    df_dime = df_dime[
        [
            "rid",
            "name",
            "lname",
            "ffname",
            "fname",
            "mname",
            "nname",
            "title",
            "suffix",
            "district",
        ]
    ]

    # Fingers crossed for the one-shot:
    df_crosswalk = pd.merge(
        df_dime,
        df_disclosures,
        how="inner",
        left_on=["district", "lname"],
        right_on=["StateDst", "Last"],
    )
    print(
        df_crosswalk[
            ["district", "name", "lname", "ffname", "Last", "First", "Prefix", "DocID"]
        ].head(30)
    )

    # Not quite... there's people with identical last names and districts.
    # And the first-name matching isn't great


if __name__ == "__main__":
    main()
