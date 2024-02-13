#!/usr/bin/env python3
import glob
import os
import json
import pandas as pd
from datetime import datetime

print("Processing CUR data")
# Check pandas version
print(pd.__version__)

csv_files = glob.glob("./data/**/*.csv.gz", recursive=True)

csv_count = len(csv_files)

if csv_count == 0:
    print("No CSV files found")
    exit()

# Initialize an empty list to hold the dataframes
dfs = []

# Load each CSV file and append it to the list of dataframes
for file in csv_files:
    df = pd.read_csv(file, compression='gzip', header=0, sep=',', quotechar='"', low_memory=False)
    dfs.append(df)

# Concatenate all dataframes into one
df = pd.concat(dfs, ignore_index=True)

# Remove unnecessary columns

# reservation_amortized_upfront_cost_for_usage,
# reservation_amortized_upfront_fee_for_billing_period,
# reservation_net_amortized_upfront_cost_for_usage,
# reservation_net_amortized_upfront_fee_for_billing_period,
# reservation_net_unused_amortized_upfront_fee_for_billing_period,
# reservation_unused_amortized_upfront_fee_for_billing_period,
# savings_plan_amortized_upfront_commitment_for_billing_period,
# savings_plan_net_amortized_upfront_commitment_for_billing_period,

columns = ['bill_payer_account_id', 
        'identity_line_item_id', 
        'resource_tags',
        'line_item_unblended_cost',
        'pricing_public_on_demand_cost',
        'savings_plan_amortized_upfront_commitment_for_billing_period',
        'savings_plan_net_amortized_upfront_commitment_for_billing_period']
df = df[columns]

# Remove untagged rows
df = df[df['resource_tags'] != '{}']

# Parse tags
df['resource_tags'] = df['resource_tags'].apply(json.loads)
df[['user_name', 
    'cluster_name',
    'user_cluster_name' ]] = df['resource_tags'].apply(
    lambda x: pd.Series({
        'user_name': x.get('user_name'), 
        'cluster_name': x.get('cluster_name'),
        'user_cluster_name': x.get('user_cluster_name')
    }))

# Cleanup data
df = df[df['user_cluster_name'].notnull()]

# Calculate groupby sum
df = df.groupby('user_cluster_name')[['line_item_unblended_cost', 
                                      'savings_plan_amortized_upfront_commitment_for_billing_period',
                                      'savings_plan_net_amortized_upfront_commitment_for_billing_period']].sum().reset_index()

# save to csv
now = datetime.now()
timestamp = now.strftime("%Y%m%d%H%M%S")
out_dir = f"./.output/cur/cur-{timestamp}"
os.makedirs(out_dir, exist_ok=True)
df.to_csv(out_dir+'/cost-per-cluster.csv', index=False)

print(df)
