# Task 1. Enable the Cloud Document AI API and copy lab source files
gcloud services enable documentai.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable geocoding-backend.googleapis.com
gcloud services enable eventarc.googleapis.com
gcloud services enable run.googleapis.com

mkdir ./document-ai-challenge
gsutil -m cp -r gs://spls/gsp367/* ~/document-ai-challenge/

# Task 2. Create a form processor
export ACCESS_TOKEN=$(gcloud auth application-default print-access-token)
export PROJECT_ID=$(gcloud config get-value core/project)
export PROCESSOR_NAME="form-processor"
export REGION="us-east4"

curl -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "'"${PROCESSOR_NAME}"'",
    "type": "FORM_PARSER_PROCESSOR"
  }' \
  "https://documentai.googleapis.com/v1/projects/${PROJECT_ID}/locations/us/processors"

# Task 3. Create Google Cloud resources
gsutil mb -c standard -l ${REGION} -b on gs://{$PROJECT_ID}-input-invoices
gsutil mb -c standard -l ${REGION} -b on gs://{$PROJECT_ID}-output-invoices
gsutil mb -c standard -l ${REGION} -b on gs://{$PROJECT_ID}-archived-invoices

bq --location="US" mk  -d --description "Form Parser Results" ${PROJECT_ID}:invoice_parser_results

cd ~/document-ai-challenge/scripts/table-schema/
bq mk --table invoice_parser_results.doc_ai_extracted_entities doc_ai_extracted_entities.json
bq mk --table invoice_parser_results.geocode_details geocode_details.json

# Task 4. 
cd ~/document-ai-challenge/scripts

export PROJECT_NUMBER=$(gcloud projects list --filter="project_id:${PROJECT_ID}" --format='value(project_number)')
export SERVICE_ACCOUNT=$(gcloud storage service-agent --project=${PROJECT_ID})

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${SERVICE_ACCOUNT} \
  --role roles/pubsub.publisher

gcloud functions deploy process-invoices \
  --gen2 \
  --region=${REGION} \
  --entry-point=process_invoice \
  --runtime=python39 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/process-invoices \
  --timeout=400 \
  --env-vars-file=cloud-functions/process-invoices/.env.yaml \
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize\
  --service-account ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --allow-unauthenticated

# Run the curl command and use grep and sed to extract the processor ID
export PROCESSOR_ID=$(curl -X GET \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://documentai.googleapis.com/v1/projects/${PROJECT_ID}/locations/us/processors" | \
  grep '"name":' | \
  sed -E 's/.*"name": "projects\/[0-9]+\/locations\/us\/processors\/([^"]+)".*/\1/')

gcloud functions deploy process-invoices \
  --gen2 \
  --region=${REGION} \
  --entry-point=process_invoice \
  --runtime=python39 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/process-invoices \
  --timeout=400 \
  --update-env-vars=PROCESSOR_ID=5d4c098d5b404a52,PARSER_LOCATION=us,PROJECT_ID=${PROJECT_ID} \
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize\
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize \
  --service-account ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --allow-unauthenticated

# Task 5. Test and validate the end-to-end solution
gsutil -m cp -r ~/document-ai-challenge/invoices gs://${PROJECT_ID}-input-invoices/
