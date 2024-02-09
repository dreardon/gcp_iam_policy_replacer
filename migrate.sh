#!/bin/bash
while getopts o:f: opt; do
    case $opt in
        o) ORGANIZATION_ID=$OPTARG ;;
        f) FILE=$OPTARG ;;
        *)
            echo 'Error in command line parsing' >&2
            exit 1
    esac
done

shift "$(( OPTIND - 1 ))"

if [ -z "$ORGANIZATION_ID" ]; then
    echo 'Missing -o organization flag' >&2
    exit 1
fi
if [ -z "$FILE" ]; then
    echo 'Missing -f file flag' >&2
    exit 1
fi

prjs=( $(gcloud asset search-all-resources --scope=organizations/$ORGANIZATION_ID --asset-types='cloudresourcemanager.googleapis.com/Project' --format="value(additionalAttributes.projectId)") )
for p in "${prjs[@]}"
    do
        echo "##########################################################"
        echo "Collecting IAM roles & users for Project: $p"
        gcloud projects get-iam-policy $p > ${p}_old_policy.yaml
        cp ${p}_old_policy.yaml ${p}_updated_policy.yaml
        cut -d, -f1 ${FILE} | tail -n +2 | while read email; do
            new_value=$(awk -F, -v term="$email" '$1 == term {print $2}' ${FILE})
            sed -i '' -e "s/$email/$new_value/g" ${p}_updated_policy.yaml
        done 
        if cmp -s ${p}_old_policy.yaml ${p}_updated_policy.yaml; then
            echo "Files are identical"
            rm ${p}_old_policy.yaml ${p}_updated_policy.yaml
        else
            echo "${p}_updated_policy.yaml is different"
            gcloud projects set-iam-policy $p ${p}_updated_policy.yaml
        fi
        echo "##########################################################"
    done
fldrs=( $(gcloud asset search-all-resources --scope=organizations/$ORGANIZATION_ID --asset-types='cloudresourcemanager.googleapis.com/Folder' --format="value(name)") )
for f in "${fldrs[@]}"
    do
        echo "##########################################################"
        echo "Collecting IAM roles & users for Folder: ${f##*/}"
        gcloud resource-manager folders get-iam-policy ${f##*/} > folder_${f##*/}_old_policy.yaml
        cp folder_${f##*/}_old_policy.yaml folder_${f##*/}_updated_policy.yaml
        cut -d, -f1 ${FILE} | tail -n +2 | while read email; do
            new_value=$(awk -F, -v term="$email" '$1 == term {print $2}' ${FILE})
            sed -i '' -e "s/$email/$new_value/g" folder_${f##*/}_updated_policy.yaml
        done 
        if cmp -s folder_${f##*/}_old_policy.yaml folder_${f##*/}_updated_policy.yaml; then
            echo "Files are identical"
            rm folder_${f##*/}_old_policy.yaml folder_${f##*/}_updated_policy.yaml
        else
            echo "folder_${f##*/}_updated_policy.yaml is different"
            gcloud resource-manager folders set-iam-policy ${f##*/} folder_${f##*/}_updated_policy.yaml
        fi
        echo "##########################################################"
    done
echo "##########################################################"
echo "Collecting IAM roles & users for the Organization"
gcloud organizations get-iam-policy $ORGANIZATION_ID > ${ORGANIZATION_ID}_old_policy.yaml
cp ${ORGANIZATION_ID}_old_policy.yaml ${ORGANIZATION_ID}_updated_policy.yaml
cut -d, -f1 ${FILE} | tail -n +2 | while read email; do
    new_value=$(awk -F, -v term="$email" '$1 == term {print $2}' ${FILE})
    sed -i '' -e "s/$email/$new_value/g" ${ORGANIZATION_ID}_updated_policy.yaml
done
if cmp -s ${ORGANIZATION_ID}_old_policy.yaml ${ORGANIZATION_ID}_updated_policy.yaml; then
    echo "Files are identical"
    rm ${ORGANIZATION_ID}_old_policy.yaml ${ORGANIZATION_ID}_updated_policy.yaml
else
    echo "${ORGANIZATION_ID}_updated_policy.yaml is different"
    gcloud organizations set-iam-policy $ORGANIZATION_ID ${ORGANIZATION_ID}_updated_policy.yaml
fi
echo "##########################################################"