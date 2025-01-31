# Task 1. Redact sensitive data from text content
gcloud config set project ${DEVSHELL_PROJECT_ID}

cat > redact-request.json <<EOF
{
	"item": {
		"value": "Please update my records with the following information:\n Email address: foo@example.com,\nNational Provider Identifier: 1245319599"
	},
	"deidentifyConfig": {
		"infoTypeTransformations": {
			"transformations": [{
				"primitiveTransformation": {
					"replaceWithInfoTypeConfig": {}
				}
			}]
		}
	},
	"inspectConfig": {
		"infoTypes": [{
				"name": "EMAIL_ADDRESS"
			},
			{
				"name": "US_HEALTHCARE_NPI"
			}
		]
	}
}
EOF

curl -s \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://dlp.googleapis.com/v2/projects/${DEVSHELL_PROJECT_ID}/content:deidentify \
  -d @redact-request.json -o redact-response.txt

gsutil cp redact-response.txt gs://${DEVSHELL_PROJECT_ID}-redact

# Task 2. Create DLP inspection templates
cat > template.json <<EOF
{
	"deidentifyTemplate": {
	  "deidentifyConfig": {
		"recordTransformations": {
		  "fieldTransformations": [
			{
			  "fields": [
				{
				  "name": "bank name"
				},
				{
				  "name": "zip code"
				}
			  ],
			  "primitiveTransformation": {
				"characterMaskConfig": {
				  "maskingCharacter": "#"
				}
			  }
			},
            {
                "fields": [
                {
                    "name": "message"
                }
                ],
                "infoTypeTransformations": {
                    "transformations": [
                        {
                            "primitiveTransformation": {
                                "replaceWithInfoTypeConfig": {}
                            }
                        }
                    ]
                }
            }
		  ]
		}
	  },
	  "displayName": "structured_data_template"
	},
	"locationId": "global",
	"templateId": "structured_data_template"
  }
EOF

curl -s \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  https://dlp.googleapis.com/v2/projects/${DEVSHELL_PROJECT_ID}/deidentifyTemplates \
  -d @template.json

cat > template.json <<EOF
{
  "deidentifyTemplate": {
    "deidentifyConfig": {
      "infoTypeTransformations": {
        "transformations": [
          {
            "infoTypes": [
              {
                "name": ""
              }
            ],
            "primitiveTransformation": {
              "replaceConfig": {
                "newValue": {
                  "stringValue": "[redacted]"
                }
              }
            }
          }
        ]
      }
    },
    "displayName": "unstructured_data_template"
  },
  "templateId": "unstructured_data_template",
  "locationId": "global"
}
EOF

curl -s \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  https://dlp.googleapis.com/v2/projects/${DEVSHELL_PROJECT_ID}/deidentifyTemplates \
  -d @template.json


YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
RESET=$(tput sgr0)

echo "${YELLOW}${BOLD}[https://console.cloud.google.com/security/sensitive-data-protection/projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates/structured_data_template/edit?project=$DEVSHELL_PROJECT_ID]${RESET}"
echo "${YELLOW}${BOLD}[https://console.cloud.google.com/security/sensitive-data-protection/projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates/unstructured_data_template/edit?project=$DEVSHELL_PROJECT_ID]${RESET}"

# Task 3. Configure a job trigger to run DLP inspection
cat > job-configuration.json << EOF
{
  "triggerId": "dlp_job",
  "jobTrigger": {
    "triggers": [
      {
        "schedule": {
          "recurrencePeriodDuration": "604800s"
        }
      }
    ],
    "inspectJob": {
      "actions": [
        {
          "deidentify": {
            "fileTypesToTransform": [
              "TEXT_FILE",
              "IMAGE",
              "CSV",
              "TSV"
            ],
            "transformationDetailsStorageConfig": {},
            "transformationConfig": {
              "deidentifyTemplate": "projects/${DEVSHELL_PROJECT_ID}/locations/global/deidentifyTemplates/unstructured_data_template",
              "structuredDeidentifyTemplate": "projects/${DEVSHELL_PROJECT_ID}/locations/global/deidentifyTemplates/structured_data_template"
            },
            "cloudStorageOutput": "gs://${DEVSHELL_PROJECT_ID}-output"
          }
        }
      ],
      "inspectConfig": {
        "infoTypes": [
          {
            "name": "EMAIL_ADDRESS"
          },
          {
            "name": "INDIA_AADHAAR_INDIVIDUAL"
          },
          {
            "name": "PHONE_NUMBER"
          },
        ],
        "minLikelihood": "POSSIBLE"
      },
      "storageConfig": {
        "cloudStorageOptions": {
          "filesLimitPercent": 100,
          "fileTypes": [
            "TEXT_FILE",
            "IMAGE",
            "WORD",
            "PDF",
            "AVRO",
            "CSV",
            "TSV",
            "EXCEL",
            "POWERPOINT"
          ],
          "fileSet": {
            "regexFileSet": {
              "bucketName": "${DEVSHELL_PROJECT_ID}-input",
              "includeRegex": [],
              "excludeRegex": []
            }
          }
        }
      }
    },
    "status": "HEALTHY"
  }
}
EOF

curl -s \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  https://dlp.googleapis.com/v2/projects/${DEVSHELL_PROJECT_ID}/locations/global/jobTriggers \
  -d @job-configuration.json

# Check and wait until the output is written to the output bucket
gsutil ls gs://${DEVSHELL_PROJECT_ID}-output
