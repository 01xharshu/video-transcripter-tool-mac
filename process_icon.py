from PIL import Image, ImageDraw
import sys

input_path = sys.argv[1]
output_path = sys.argv[2]

# Open the image
img = Image.open(input_path).convert("RGBA")

# The image is likely 1024x1024. The AI squircle is slightly inset.
# Let's crop to the inner part. Assuming the squircle is about 80% of the image size.
width, height = img.size

# Find the bounding box of the non-white part to see where the squircle is? 
# Actually, the background is white. The squircle is white with a slight grey inner shadow.
# Let's just crop a fixed amount, e.g., 10% from each side to grab the core image
crop_amount = int(width * 0.11)
cropped = img.crop((crop_amount, crop_amount, width - crop_amount, height - crop_amount))

# Resize to 1024x1024
cropped = cropped.resize((1024, 1024), Image.Resampling.LANCZOS)

# Create a continuous squircle mask (superellipse) for macOS
# formula: |x|^n + |y|^n = 1. For macOS squircle, n is about 4 to 5. Let's use 4.5
mask = Image.new('L', (1024, 1024), 0)
pixels = mask.load()
for x in range(1024):
    for y in range(1024):
        # map to -1 to 1
        nx = (x - 512) / 512.0
        ny = (y - 512) / 512.0
        if abs(nx)**4.5 + abs(ny)**4.5 <= 1.0:
            pixels[x, y] = 255

# Apply mask
final_img = Image.new("RGBA", (1024, 1024), (0,0,0,0))
final_img.paste(cropped, (0, 0), mask)

# Save
final_img.save(output_path)
print("Saved to", output_path)
