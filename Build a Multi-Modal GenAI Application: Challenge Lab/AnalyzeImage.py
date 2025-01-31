import vertexai
from vertexai.generative_models import GenerativeModel, Part

PROJECT_ID = "qwiklabs-gcp-04-aa48cc539a53"
REGION = "us-central1"
IMAGE_PATH = Part.from_uri(
    "gs://generativeai-downloads/images/scones.jpg", mime_type="image/jpeg"
)


def analyze_bouquet_image(project_id: str, location: str, image_path: str) -> str:
    # Initialize Vertex AI
    vertexai.init(project=project_id, location=location)
    # Load the model
    multimodal_model = GenerativeModel("gemini-pro-vision")
    # Query the model
    response = multimodal_model.generate_content(
        [
            image_path,
            "What is shown in this image?",
        ]
    )

    return response.text


response = analyze_bouquet_image(PROJECT_ID, REGION, IMAGE_PATH)
print(response)
