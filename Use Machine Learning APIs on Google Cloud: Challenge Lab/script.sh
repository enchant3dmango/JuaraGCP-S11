gcloud iam service-accounts create superman

gcloud projects add-iam-policy-binding ${DEVSHELL_PROJECT_ID} --member=serviceAccount:superman@${DEVSHELL_PROJECT_ID}.iam.gserviceaccount.com --role=roles/bigquery.admin
gcloud projects add-iam-policy-binding ${DEVSHELL_PROJECT_ID} --member=serviceAccount:superman@${DEVSHELL_PROJECT_ID}.iam.gserviceaccount.com --role=roles/storage.objectAdmin
gcloud projects add-iam-policy-binding ${DEVSHELL_PROJECT_ID} --member=serviceAccount:superman@${DEVSHELL_PROJECT_ID}.iam.gserviceaccount.com --role=roles/serviceusage.serviceUsageConsumer

gcloud iam service-accounts keys create superman.json --iam-account superman@${DEVSHELL_PROJECT_ID}.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS=${PWD}/superman.json
gsutil cp gs://${DEVSHELL_PROJECT_ID}/analyze-images-v2.py

sed -i "s/'en'/'${LOCAL}'/g" analyze-images-v2.py

# TODO: Replace the code using main.py first!
python3 analyze-images-v2.py ${DEVSHELL_PROJECT_ID} ${DEVSHELL_PROJECT_ID}

bq query --use_legacy_sql=false "SELECT locale,COUNT(locale) as lcount FROM image_classification_dataset.image_text_detail GROUP BY locale ORDER BY lcount DESC"
