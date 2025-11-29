import os
from PIL import Image

def make_square(image_path, output_path, fill_color=(255, 255, 255, 0)):
    try:
        img = Image.open(image_path)
        img = img.convert("RGBA")
        
        width, height = img.size
        new_size = max(width, height)
        
        # Add some padding (e.g., 20%) to ensure it doesn't touch edges in circle crops
        padding = int(new_size * 0.2)
        final_size = new_size + padding * 2
        
        new_img = Image.new("RGBA", (final_size, final_size), fill_color)
        
        # Center the original image
        x = (final_size - width) // 2
        y = (final_size - height) // 2
        
        new_img.paste(img, (x, y), img)
        
        new_img.save(output_path)
        print(f"Created square image at {output_path}")
        
    except Exception as e:
        print(f"Error processing image: {e}")

if __name__ == "__main__":
    # Create square icon with transparent background for launcher
    # Using white background might be safer if the logo has dark text and system is dark
    # But user said "splash screen background should be white".
    
    input_path = "logo-assets/logoonly.png"
    
    if os.path.exists(input_path):
        # For launcher icon - let's use white background to be safe and professional
        make_square(input_path, "logo-assets/icon_square.png", fill_color=(255, 255, 255, 255))
        
        # For splash screen - also use white background or transparent?
        # If splash background is white, transparent icon is fine.
        # But let's use the same square one.
    else:
        print(f"File not found: {input_path}")
