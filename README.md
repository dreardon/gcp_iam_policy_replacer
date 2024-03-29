# IAM Policy Replacer

This script is designed to streamline the process of updating Google IAM policies with new email addresses. It's ideal for situations where user email addresses change on a larger scale (e.g., company email domain change). This script works for resource policies bound at the Organization, Folder, or Project level. See a note below for how to determine permissions for resources-level bindings under a project.

## Google Disclaimer
This is not an officially supported Google product

## How it Works

CSV Input:  The script expects a CSV file with the following structure:

```
old_ad,new_ad
dan@old_email.com,dan@new_email.com
test@old_email.com,A12345@new_email.com
manager@old_email.com,Z54321@new_email.com
```

Script Execution:  The script expects an organization id and CSV file name to be passed in:

```
./migrate.sh -o [ORG_ID] -f [FILE_NAME]
./migrate.sh -o 123456 -f ad_mappings.csv
```

## Resource-based Permissions
Google's Cloud Asset Inventory (CAI) feature has a feature which [searches](https://cloud.google.com/sdk/gcloud/reference/asset/search-all-iam-policies) all IAM policies within the specified accessible scope, such as a project, folder or organization. Examples of this binding include BigQuery Datasets or Tables, KMS Keys, Individual Secrets in Secret Manager, Cloud Run Invoker permissions on a single service and many more.

An Example query which will display all permission bindings to resources below a project is as follows:
```
gcloud asset search-all-iam-policies --scope="projects/${PROJECT_ID}"
```


## Migrate Groups

### Existing Cloud Identity: Gather Groups and Generate Update Scripts
```
CUSTOMER_ID=[Cloud Identity ID]
PROJECT_ID=[Project ID]

printf 'y' |  gcloud services enable cloudresourcemanager.googleapis.com
printf 'y' |  gcloud services enable cloudasset.googleapis.com
printf 'y' |  gcloud services enable cloudidentity.googleapis.com

gcloud config set project ${PROJECT_ID}

gcloud identity groups search \
--labels="cloudidentity.googleapis.com/groups.discussion_forum" \
--customer="${CUSTOMER_ID}" \
--view full \
--format json > groups.json

jq -c '.[][]' groups.json | while read i; do
    NAME=$(jq --raw-output '.displayName' <<< "$i")
    DESCRIPTION=$(jq --raw-output '.description' <<< "$i")
    EMAIL=$(jq --raw-output '.groupKey.id' <<< "$i")
    if [ "$DESCRIPTION" = "null" ]; then 
        echo "gcloud identity groups create "${EMAIL}" --customer="${CUSTOMER_ID}" --display-name="${NAME}"" >> create_groups.sh
    else
        echo "gcloud identity groups create "${EMAIL}" --customer="${CUSTOMER_ID}" --display-name="${NAME}" --description="${DESCRIPTION}"" >> create_groups.sh
    fi
    grp_members=( $(gcloud identity groups memberships list --group-email="${EMAIL}" --format="value(preferredMemberKey.id)") )
    for e in "${grp_members[@]}"
        do
            echo "gcloud identity groups memberships add --group-email="${EMAIL}" --member-email="${e}"" >> create_group_${EMAIL}.txt
        done
done
```

### New Cloud Identity: Execute Update Scripts
```

#Run the script to generate groups
./create_groups.sh

#Run all of the update scripts to populate groups with users
./create_group_${EMAIL}.txt

```

## TODO
- Iterate resources under a project which can contain granted permissions (BigQuery Datasets, BigQuery Tables, etc.)
- Replace old group and user emails with updated emails in the "Gather Groups and Generate Update Scripts" section
