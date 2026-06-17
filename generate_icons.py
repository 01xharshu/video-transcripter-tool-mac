from PIL import Image, ImageDraw
import sys, os

input_path = sys.argv[1]
assets_path = sys.argv[2]

# Open the image
img = Image.open(input_path).convert("RGBA")

# Crop 10% from the AI image
width, height = img.size
crop_amount = int(width * 0.11)
cropped = img.crop((crop_amount, crop_amount, width - crop_amount, height - crop_amount))

# Squircle mask generator
def get_squircle_mask(size):
    mask = Image.new('L', (size, size), 0)
    pixels = mask.load()
    for x in range(size):
        for y in range(size):
            nx = (x - size/2) / (size/2)
            ny = (y - size/2) / (size/2)
            if abs(nx)**4.5 + abs(ny)**4.5 <= 1.0:
                pixels[x, y] = 255
    return mask

# Generate all sizes
sizes = {
    "16x16": 16,
    "16x16@2x": 32,
    "32x32": 32,
    "32x32@2x": 64,
    "128x128": 128,
    "128x128@2x": 256,
    "256x256": 256,
    "256x256@2x": 512,
    "512x512": 512,
    "512x512@2x": 1024
}

for name, size in sizes.items():
    resized = cropped.resize((size, size), Image.Resampling.LANCZOS)
    mask = get_squircle_mask(size)
    final_img = Image.new("RGBA", (size, size), (0,0,0,0))
    final_img.paste(resized, (0, 0), mask)
    final_img.save(os.path.join(assets_path, f"icon_{name}.png"))

print("All icons generated!")
