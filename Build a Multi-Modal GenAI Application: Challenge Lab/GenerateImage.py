import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

PROJECT_ID = "qwiklabs-gcp-04-aa48cc539a53"
REGION = "us-central1"


def generate_bouquet_image(
    project_id: str, location: str, output_file: str, prompt: str
) -> vertexai.preview.vision_models.ImageGenerationResponse:
    vertexai.init(project=project_id, location=location)

    model = ImageGenerationModel.from_pretrained("imagegeneration@002")

    images = model.generate_images(
        prompt=prompt,
        number_of_images=1,
        seed=1,
        add_watermark=False,
    )

    images[0].save(location=output_file)

    return images


generate_bouquet_image(
    project_id=PROJECT_ID,
    location=REGION,
    output_file="image.jpeg",
    prompt="Create an image containing a bouquet of 2 sunflowers and 3 roses",
)
