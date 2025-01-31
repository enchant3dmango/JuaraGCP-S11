# Set API key
export API_KEY=AIzaSyCKsmIAeCw3iHZxpTyDkuIEhoTLTqrql6I
# Get the current GCP project ID 
export PROJECT_ID=$(gcloud config get-value project)

task_2_file="synthesize-text.txt"
task_3_request_file="speech_request.json"
task_3_response_file="speech_response.json"
task_4_sentence="これは日本語です。"
task_4_file="translated_response.txt"
task_5_sentence="Este%é%japonês."
task_5_file="detection_response.txt"

# Activate the Python virtual environment
source venv/bin/activate

# Task 2. Create synthetic speech from text using the Text-to-Speech API
# Create JSON request for Text-to-Speech API
cat > synthesize-text.json <<EOF
{
    'input':{
        'text':'Cloud Text-to-Speech API allows developers to include
           natural-sounding, synthetic human speech as playable audio in
           their applications. The Text-to-Speech API converts text or
           Speech Synthesis Markup Language (SSML) input into audio data
           like MP3 or LINEAR16 (the encoding used in WAV files).'
    },
    'voice':{
        'languageCode':'en-gb',
        'name':'en-GB-Standard-A',
        'ssmlGender':'FEMALE'
    },
    'audioConfig':{
        'audioEncoding':'MP3'
    }
}
EOF

# Call Google Cloud Text-to-Speech API and save the response
curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @synthesize-text.json "https://texttospeech.googleapis.com/v1/text:synthesize" \
  > $task_2_file

# Create Python script to decode Text-to-Speech API response into an MP3 file
cat > tts_decode.py <<EOF
import argparse
from base64 import decodebytes
import json

"""
Usage:
        python tts_decode.py --input "synthesize-text.txt" \
        --output "synthesize-text-audio.mp3"

"""

def decode_tts_output(input_file, output_file):
    """ Decode output from Cloud Text-to-Speech.

    input_file: the response from Cloud Text-to-Speech
    output_file: the name of the audio file to create

    """

    with open(input_file) as input:
        response = json.load(input)
        audio_data = response['audioContent']

        with open(output_file, "wb") as new_file:
            new_file.write(decodebytes(audio_data.encode('utf-8')))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Decode output from Cloud Text-to-Speech",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--input',
                       help='The response from the Text-to-Speech API.',
                       required=True)
    parser.add_argument('--output',
                       help='The name of the audio file to create',
                       required=True)

    args = parser.parse_args()
    decode_tts_output(args.input, args.output)
EOF

# Run the Python script to generate an MP3 file
python tts_decode.py --input "synthesize-text.txt" --output "synthesize-text-audio.mp3"

# Task 3. Perform speech to text transcription with the Cloud Speech API
# Define audio file for Speech-to-Text transcription
audio_uri="gs://cloud-samples-data/speech/corbeau_renard.flac"

# Create JSON request for Speech-to-Text API
cat > "$task_3_request_file" <<EOF
{
  "config": {
    "encoding": "FLAC",
    "sampleRateHertz": 44100,
    "languageCode": "fr-FR"
  },
  "audio": {
    "uri": "$audio_uri"
  }
}
EOF

# Make API call for French transcription
curl -s -X POST -H "Content-Type: application/json" \
    --data-binary @"$task_3_request_file" \
    "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
    -o "$task_3_response_file"

# Task 4. Translate text with the Cloud Translation API
# Update package lists and install jq for JSON parsing
sudo apt-get update
sudo apt-get install -y jq

# Translate Japanese text to English using Cloud Translation API
curl "https://translation.googleapis.com/language/translate/v2?target=en&key=${API_KEY}&q=${task_4_sentence}" > $task_4_file

# Translate Japanese text using an authenticated API request
response=$(curl -s -X POST \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d "{\"q\": \"$task_4_sentence\"}" \
"https://translation.googleapis.com/language/translate/v2?key=${API_KEY}&source=ja&target=en")
echo "$response" > "$task_4_file"

# Task 5. Detect a language with the Cloud Translation API
# URL-decode the sentence
decoded_sentence=$(python -c "import urllib.parse; print(urllib.parse.unquote('$task_5_sentence'))")

# Call Language Detection API using curl and save the output to $task_5_file
curl -s -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d "{\"q\": [\"$decoded_sentence\"]}" \
  "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
  -o "$task_5_file"
