#!/bin/bash
prjs=( $(gcloud projects list | tail -n +2 | awk {'print $1'}) )
for i in "${prjs[@]}"
    do
        echo "##########################################################"
        echo "Collecting IAM roles & users for Project: $i"
        gcloud projects get-iam-policy $1 > ./policy.yaml
        cut -d, -f1 ad_mappings.csv | tail -n +2 | while read email; do
            new_value=$(awk -F, -v term="$email" '$1 == term {print $2}'  ad_mappings.csv)
            sed -i -e "s/$email/$new_value/g" ./policy.yaml
        done 
        gcloud projects set-iam-policy $i policy.yaml
        echo "##########################################################"
    done
echo "##########################################################"
echo "Collecting IAM roles & users for the Organization"
gcloud organizations get-iam-policy [OrgID] > ./policy.yaml
cut -d, -f1 ad_mappings.csv | tail -n +2 | while read email; do
    new_value=$(awk -F, -v term="$email" '$1 == term {print $2}'  ad_mappings.csv)
    sed -i -e "s/$email/$new_value/g" ./policy.yaml
done 
gcloud organizations set-iam-policy [OrgID] policy.yaml
echo "##########################################################"