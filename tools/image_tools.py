""" This script contains a collection of functions for various game development tasks, divided into sections where relavent tools are grouped together.
     Uncomment which tool you which to use in the __main__ section at the bottom."""

# Imports 
from PIL import Image
import os
import sys
import argparse
import glob

"""Sprite Sheet Tools"""

def load_image_with_alpha(path):
    """Load image ensuring RGBA mode for alpha channel preservation."""
    if not os.path.exists(path):
        raise FileNotFoundError(f"Input file not found: {path}")
    
    img = Image.open(path)
    # Convert to RGBA to ensure we handle transparency correctly during assembly
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    return img

def extract_sprites_from_grid(img, rows=3, cols=6, margin=0):
    """
    Extract sprites from a grid-layout sprite sheet.
    Returns list of cropped PIL Images (RGBA).
    """
    width, height = img.size
    cell_w = width // cols
    cell_h = height // rows

    print(f"Grid Info: Cell Size={cell_w}x{cell_h}, Margin={margin}")
    
    sprites = []
    for r in range(rows):
        for c in range(cols):
            left = c * cell_w + margin
            top = r * cell_h + margin
            right = (c + 1) * cell_w - margin
            bottom = (r + 1) * cell_h - margin

            # Validate bounds
            if left < 0 or top < 0 or right > width or bottom > height:
                print(f"Warning: Skipping cell ({r},{c}) due to out-of-bounds crop.")
                continue

            sprite = img.crop((left, top, right, bottom))
            
            # Trim transparent borders
            trimmed_sprite = trim_transparent_borders(sprite)
            
            # Validate that trimming didn't remove everything
            if trimmed_sprite.width == 0 or trimmed_sprite.height == 0:
                print(f"Warning: Sprite at ({r},{c}) became empty after trimming. Skipping.")
                continue
                
            sprites.append(trimmed_sprite)
            
    return sprites

def trim_transparent_borders(img):
    """
    Trim fully transparent borders from an RGBA image.
    """
    bbox = img.getbbox()
    if bbox is None:
        # Return a minimal 1x1 transparent image if completely empty
        # This prevents crashes, but we'll filter these out later
        return Image.new('RGBA', (1, 1), (0, 0, 0, 0))
    return img.crop(bbox)

def assemble_horizontal_sprite_sheet(sprites, output_path="output_sprite_sheet.png"):
    """
    Assemble list of sprites into a single-row horizontal sprite sheet.
    """
    if not sprites:
        raise ValueError("No sprites provided to assemble.")

    total_width = sum(s.width for s in sprites)
    max_height = max(s.height for s in sprites)

    result = Image.new('RGBA', (total_width, max_height), (0, 0, 0, 0))

    x_offset = 0
    for sprite in sprites:
        # The third argument 'sprite' acts as the mask, preserving transparency
        result.paste(sprite, (x_offset, 0), sprite)
        x_offset += sprite.width

    # Resolve absolute path for clarity
    abs_output_path = os.path.abspath(output_path)
    result.save(abs_output_path, format='PNG')
    print(f"Sprite sheet saved to: {abs_output_path}")

def save_sprites_individually(sprites, output_dir="individual_sprites"):
    """
    Save each sprite as a separate PNG file.
    """
    if not sprites:
        raise ValueError("No sprites provided to save.")

    # Resolve absolute path
    abs_output_dir = os.path.abspath(output_dir)
    
    try:
        os.makedirs(abs_output_dir, exist_ok=True)
        print(f"Output Directory Created/Verified: {abs_output_dir}")
    except Exception as e:
        print(f"Error creating directory {abs_output_dir}: {e}")
        return

    saved_count = 0
    for i, sprite in enumerate(sprites):
        filename = f"sprite_{i:03d}.png"
        filepath = os.path.join(abs_output_dir, filename)
        
        try:
            sprite.save(filepath, format='PNG')
            saved_count += 1
            # Optional: Print every file, or just summary. 
            # For debugging, let's print the first few and the last one.
            if i < 3 or i == len(sprites) - 1:
                print(f"Saved: {filepath}")
                
        except Exception as e:
            print(f"Error saving {filepath}: {e}")

    print(f"Successfully saved {saved_count} individual sprites to: {abs_output_dir}")

def sprite_sheet_main():
    parser = argparse.ArgumentParser(description="Reorganize sprite sheets.")
    parser.add_argument("input", help="Path to input sprite sheet")
    parser.add_argument("--rows", type=int, default=3, help="Rows in grid")
    parser.add_argument("--cols", type=int, default=6, help="Columns in grid")
    parser.add_argument("--margin", type=int, default=0, help="Margin between cells")
    parser.add_argument("--output-sheet", type=str, default="reorganized_smoke_sprite_sheet.png", help="Output sheet path")
    parser.add_argument("--output-dir", type=str, default="individual_sprites", help="Output directory for individual files")
    parser.add_argument("--separate", action="store_true", help="Save as individual files")

    args = parser.parse_args()

    try:
        print(f"Loading: {os.path.abspath(args.input)}")
        img = load_image_with_alpha(args.input)
        print(f"Image Size: {img.size}")

        sprites = extract_sprites_from_grid(img, rows=args.rows, cols=args.cols, margin=args.margin)
        print(f"Extracted {len(sprites)} valid sprites.")

        if not sprites:
            print("ERROR: No sprites were extracted. Check your --rows, --cols, and --margin values.")
            sys.exit(1)

        if args.separate:
            save_sprites_individually(sprites, output_dir=args.output_dir)
        else:
            assemble_horizontal_sprite_sheet(sprites, output_path=args.output_sheet)

        print("Process Complete.")

    except Exception as e:
        print(f"FATAL ERROR: {e}")
        sys.exit(1)


""" Folder to Sprite Sheet Tools """

def create_sprite_sheet_from_folder(folder_path, output_path="folder_sprite_sheet.png", sort_by_name=True):
    """
    Takes all images in a folder, loads them with alpha, and assembles them 
    into a single horizontal sprite sheet.
    
    Args:
        folder_path (str): Path to the folder containing images.
        output_path (str): Path for the output sprite sheet PNG.
        sort_by_name (bool): If True, sorts files alphabetically. If False, uses OS order.
    """
    if not os.path.isdir(folder_path):
        raise NotADirectoryError(f"Folder not found: {folder_path}")

    # Supported image extensions
    valid_extensions = ('.png', '.jpg', '.jpeg', '.bmp', '.tga')
    
    # Gather files
    files = [f for f in os.listdir(folder_path) if f.lower().endswith(valid_extensions)]
    
    if not files:
        print(f"No valid image files found in: {folder_path}")
        return

    # Sort files
    if sort_by_name:
        files.sort()
        print(f"Found {len(files)} images. Sorting by name...")
    else:
        print(f"Found {len(files)} images. Using default order...")

    sprites = []
    for filename in files:
        filepath = os.path.join(folder_path, filename)
        try:
            # Use existing helper to ensure RGBA
            img = load_image_with_alpha(filepath)
            # Optional: You might want to trim transparent borders here too?
            # For a sprite sheet from separate files, usually you want to keep 
            # the original canvas size unless specified otherwise. 
            # If you want to trim whitespace/transparent padding from individual 
            # source images, uncomment the next line:
            # img = trim_transparent_borders(img)
            
            sprites.append(img)
            print(f"Loaded: {filename}")
        except Exception as e:
            print(f"Failed to load {filename}: {e}")

    if not sprites:
        print("ERROR: No sprites could be loaded.")
        return

    # Assemble
    assemble_horizontal_sprite_sheet(sprites, output_path=output_path)
    print("Folder to Sprite Sheet process complete.")


""" Bulk File Handling Tools"""
def rename_files(directory, base_name, start_index=0, zero_pad=3):
	# Allowed extensions
	valid_exts = {".png", ".jpg", ".ogg", ".mp3", ".wav"}

	files = sorted(os.listdir(directory))
	index = start_index

	for filename in files:
		old_path = os.path.join(directory, filename)

		# Skip directories
		if not os.path.isfile(old_path):
			continue

		# Get extension (lowercase for safety)
		_, ext = os.path.splitext(filename)
		ext = ext.lower()

		# Skip unwanted file types (.import, etc.)
		if ext not in valid_exts:
			continue

		# Build new filename
		new_name = f"{base_name}_{str(index).zfill(zero_pad)}{ext}"
		new_path = os.path.join(directory, new_name)

		# Rename
		os.rename(old_path, new_path)

		print(f"{filename} -> {new_name}")

		index += 1


if __name__ == "__main__":
    
    ## 1. Sprite Sheet Reorganization (Existing Tool)
    # Usage: python script.py input_sheet.png --rows 4 --cols 4
    # sprite_sheet_main()

    ## 2. Folder to Sprite Sheet (New Tool)
    # Uncomment below to run this tool
    
    target_folder = r"C:\Users\Raven\Documents\War-Engine_v0.4\Assets\vfx_textures\brackeys_vfx_bundle\particles\spritesheet"
    output_file = r"C:\Users\Raven\Documents\War-Engine_v0.4\Assets\vfx_textures\brackeys_vfx_bundle\particles\spritesheet\smoke_sprite_sheet.png"
    create_sprite_sheet_from_folder(target_folder, output_file)
    
    ## 3. File Handling (Renaming)
    # target_directory = r"C:\Users\Raven\Documents\War-Engine_v0.4\Assets\audio\footsteps\wood"
    # base_name = "wood_footstep"
    # rename_files(target_directory, base_name)
    
    ## More to come...