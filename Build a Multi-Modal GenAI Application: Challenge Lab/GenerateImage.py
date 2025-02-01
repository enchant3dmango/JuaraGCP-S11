import os

import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

REGION = "us-central1"


def generate_bouquet_image(
    project_id: str, location: str, output_file: str, prompt: str
) -> vertexai.preview.vision_models.ImageGenerationResponse:
    # Initialize Vertex AI
    vertexai.init(project=project_id, location=location)
    # Load the model
    model = ImageGenerationModel.from_pretrained("imagegeneration@002")
    # Generate the image(s)
    images = model.generate_images(
        prompt=prompt,
        number_of_images=1,
        seed=1,
        add_watermark=False,
    )

    images[0].save(location=output_file)

    return images


generate_bouquet_image(
    project_id=os.environ["DEVSHELL_PROJECT_ID"],
    location=REGION,
    output_file="image.jpeg",
    prompt="Create an image containing a bouquet of 2 sunflowers and 3 roses",
)
