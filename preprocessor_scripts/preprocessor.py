from PIL import Image
import os
from torchvision import transforms

preprocess = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.48145466, 0.4578275, 0.40821073],
        std=[0.26862954, 0.26130258, 0.27577711]
    )
])

input_dir = "D:\\projects\\digiGuide\\digiguide\\dataset"
output_dir = "D:\\projects\\digiGuide\\digiguide\\processed_dataset"

for folder in os.listdir(input_dir):
    class_path = os.path.join(input_dir, folder)
    out_class_path = os.path.join(output_dir, folder)
    os.makedirs(out_class_path, exist_ok=True)

    for file in os.listdir(class_path):
        img_path = os.path.join(class_path, file)
        print(img_path)
        img = Image.open(img_path).convert("RGB")

        processed = preprocess(img)
        save_path = os.path.join(out_class_path, file)
        transforms.ToPILImage()(processed).save(save_path)
