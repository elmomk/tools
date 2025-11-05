#!/bin/bash

# ---
# A script to compare the DIRECT project-level IAM roles of two users.
#
# Usage: ./compare-iam.sh <PROJECT_ID> <USER1_EMAIL> <USER2_EMAIL>
#
# Example:
# ./compare-iam.sh my-gke-project user-a@example.com user-b@example.com
# ---

# 1. Check for the correct number of arguments
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <PROJECT_ID> <USER1_EMAIL> <USER2_EMAIL>"
  exit 1
fi

# 2. Assign arguments to variables
PROJECT_ID=$1
USER1=$2
USER2=$3

# 3. Define a function to get sorted, unique, direct roles for a user
# This function filters the project's IAM policy for a specific user
# and outputs only the role names, sorted.
get_user_roles() {
  local project=$1
  local user_email=$2

  echo gcloud projects get-iam-policy "$project" --flatten="bindings[].members" --format="value(bindings.role)" --filter="bindings.members:user:$user_email"
  gcloud projects get-iam-policy "$project" \
    --flatten="bindings[].members" \
    --format="value(bindings.role)" \
    --filter="bindings.members:user:$user_email" | sort -u
}

# 4. Main comparison logic
echo "Fetching roles for $USER1 and $USER2 in project $PROJECT_ID..."
echo "--------------------------------------------------------"

# We use process substitution (<(...)) to feed the output of our
# function directly into the `comm` command without needing temp files.

echo
echo "--- Roles unique to $USER1 ---"
comm -23 <(get_user_roles "$PROJECT_ID" "$USER1") <(get_user_roles "$PROJECT_ID" "$USER2")

echo
echo "--- Roles unique to $USER2 ---"
comm -13 <(get_user_roles "$PROJECT_ID" "$USER1") <(get_user_roles "$PROJECT_ID" "$USER2")

echo
echo "--- Roles common to both ---"
comm -12 <(get_user_roles "$PROJECT_ID" "$USER1") <(get_user_roles "$PROJECT_ID" "$USER2")

echo "--------------------------------------------------------"
