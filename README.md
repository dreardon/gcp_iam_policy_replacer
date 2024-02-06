# IAM Policy Replacer

This script is designed to streamline the process of updating Google IAM policies with new email addresses. It's ideal for situations where user email addresses change on a larger scale (e.g., company email domain change).

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