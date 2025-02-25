"""Tools for comparing output component table results"""

from argparse import ArgumentParser
import pandas as pd
import numpy as np
import os

TAG = 'classification_tags'
KUNDU_TAGS = ('Accept borderline', 'No provisional accept')
RATIONALE_TABLE = {
    'I001': 'Manual classification',
    'I002': 'Rho > Kappa',
    'I003': 'More significant voxels S0 vs. R2',
    'I004': 'S0 Dice > R2 Dice AND high varex',
    'I005': 'Noise F-value > Signal F-value AND high varex',
    'I006': 'No good components found',
    'I007': 'Mid-Kappa',
    'I008': 'Low variance',
    'I009': 'Mid-Kappa type A',
    'I010': 'Mid-Kappa type B',
    'I011': 'ign_add0',
    'I012': 'ign_add1',
    'N/A':  'N/A',
}

def get_classification(row: pd.Series) -> str:
    return "R" if row["classification"] == "rejected" else "A"

def save_summary(change_list, filename):
    if change_list:
        df_summary = pd.DataFrame(change_list)
        df_summary = df_summary.groupby(["Session", "Change"]).agg({
            "NumComponents": "sum",
            "ComponentIndex": list,
            "VarianceExplained": sum
        }).reset_index()
        df_summary["Percentage"] = (df_summary["NumComponents"] / total_components) * 100
        df_summary.rename(columns={"ComponentIndex": "ComponentIndices", "VarianceExplained": "Varex"}, inplace=True)

        if os.path.exists(filename):
            df_summary.to_csv(filename, mode='a', header=False, index=False)
        else:
            df_summary.to_csv(filename, index=False)

def main():
    parser = ArgumentParser(description='Prints the number of component classification changes.')
    parser.add_argument('--verbose', '-v', help='Verbose mode; prints all component IDs for each change type', required=False, action='store_true')
    parser.add_argument('session', help='Session identifier')
    parser.add_argument('left', help='The left component table')
    parser.add_argument('right', help='The right component table')
    args = parser.parse_args()

    ltable = pd.read_csv(args.left, delimiter='\t')
    rtable = pd.read_csv(args.right, delimiter='\t')

    assert "classification" in ltable.columns
    assert "classification" in rtable.columns

    if len(ltable) != len(rtable):
        raise ValueError(f"{args.left} has {len(ltable)} components, but {args.right} has {len(rtable)} components.")

    global total_components
    total_components = len(ltable)
    changes_RtoA = []
    changes_AtoR = []

    for (i, lrow), (_, rrow) in zip(ltable.iterrows(), rtable.iterrows()):
        lclass = get_classification(lrow)
        rclass = get_classification(rrow)
        
        if lclass != rclass:
            change_entry = {
                "Session": args.session,
                "Change": f"{lclass} -> {rclass}",
                "NumComponents": 1,
                "VarianceExplained": lrow['variance explained'],
                "ComponentIndex": i
            }
            if lclass == "R" and rclass == "A":
                changes_RtoA.append(change_entry)
            elif lclass == "A" and rclass == "R":
                changes_AtoR.append(change_entry)
    
    save_summary(changes_RtoA, "classification_changes_RtoA.csv")
    save_summary(changes_AtoR, "classification_changes_AtoR.csv")

    if changes_RtoA or changes_AtoR:
        df_both = pd.concat([pd.DataFrame(changes_RtoA), pd.DataFrame(changes_AtoR)], ignore_index=True)
        df_both = df_both.groupby(["Session"]).agg({
            "NumComponents": "sum",
            "ComponentIndex": list,
            "VarianceExplained": sum
        }).reset_index()
        df_both["Change"] = "Both"
        df_both["Percentage"] = (df_both["NumComponents"] / total_components) * 100
        
        filename_both = "classification_changes_Both.csv"
        if os.path.exists(filename_both):
            df_both.to_csv(filename_both, mode='a', header=False, index=False)
        else:
            df_both.to_csv(filename_both, index=False)
    
    print("Classification changes appended to files.")

if __name__ == '__main__':
    main()
