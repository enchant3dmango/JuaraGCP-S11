# Task 1. Use cURL to test a prompt with the API

# Just follow the instructions in the lab

# Task 2. Write Streamlit framework and prompt Python code to complete chef.py
git clone https://github.com/GoogleCloudPlatform/generative-ai.git

cd generative-ai/gemini/sample-apps/gemini-streamlit-cloudrun

rm -f Dockerfile chef.py
rm -f chef.py

gsutil cp gs://spls/gsp517/chef.py .

wget https://raw.githubusercontent.com/enchant3dmango/JuaraGCP-S11/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit:%20Challenge%20Lab/chef.py

gcloud storage cp chef.py gs://${DEVSHELL_PROJECT_ID}-generative-ai/

# Task 3. Test the application
python3 -m venv gemini-streamlit
source gemini-streamlit/bin/activate
python3 -m  pip install -r requirements.txt

streamlit run chef.py \
  --browser.serverAddress=localhost \
  --server.enableCORS=false \
  --server.enableXsrfProtection=false \
  --server.port 8080

# Task 4. Modify the Dockerfile and push image to the Artifact Registry
export AR_REPO='chef-repo'
export SERVICE_NAME='chef-streamlit-app' 
export PROJECT=${DEVSHELL_PROJECT_ID}
export REGION='us-east4'

gcloud services enable run.googleapis.com

wget https://raw.githubusercontent.com/enchant3dmango/JuaraGCP-S11/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit:%20Challenge%20Lab/Dockerfile

gcloud artifacts repositories create "${AR_REPO}" --location="${REGION}" --project="${PROJECT}" --repository-format=Docker
gcloud builds submit --tag "${REGION}-docker.pkg.dev/${DEVSHELL_PROJECT_ID}/${AR_REPO}/${SERVICE_NAME}" 

# Task 5. Deploy the application to Cloud Run and test
gcloud run deploy "${SERVICE_NAME}" \
  --port=8080 \
  --image="${REGION}-docker.pkg.dev/${PROJECT}/${AR_REPO}/${SERVICE_NAME}" \
  --allow-unauthenticated \
  --region=${REGION} \
  --platform=managed  \
  --project=${DEVSHELL_PROJECT_ID} \
  --set-env-vars=GCP_PROJECT=${DEVSHELL_PROJECT_ID},GCP_REGION=${REGION}
