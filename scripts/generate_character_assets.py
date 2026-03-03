import os
import glob

base_dir = "."
sprites_dir = os.path.join(base_dir, "assets/sprites/Character Components")
resources_dir = os.path.join(base_dir, "resources/character_components_animations")

categories = ["body", "hairstyle", "eyes", "outfit", "accessory"]

tres_template = """[gd_resource type="SpriteFrames" format=3]

[ext_resource type="Texture2D" path="{png_path}" id="1_tex"]

{sub_resources}
[resource]
resource_name = "{res_name}"
animations = [{animations_content}]
"""

sub_resource_template = """[sub_resource type="AtlasTexture" id="AtlasTexture_{id}"]
atlas = ExtResource("1_tex")
region = Rect2({x}, {y}, 48, 96)
"""

anim_defs = [
    ("idle_right", 96, 0),
    ("idle_up", 96, 6),
    ("idle_left", 96, 12),
    ("idle_down", 96, 18),
    ("move_right", 192, 0),
    ("move_up", 192, 6),
    ("move_left", 192, 12),
    ("move_down", 192, 18),
]

def generate_tres_for_image(png_path, tres_path, category):
    res_name = os.path.basename(tres_path)
    # Ensure Godot res:// formatting
    if png_path.startswith("./"):
        png_path = png_path[2:]
    res_path_godot = "res://" + png_path.replace("\\", "/")
    
    sub_resources = ""
    animations_content = ""
    
    # default empty anim
    animations_content += """{
"frames": [],
"loop": true,
"name": &"default",
"speed": 5.0
}, """
    
    for anim_name, y_offset, col_start in anim_defs:
        animations_content += "{\n\"frames\": ["
        frames_list = []
        for i in range(6):
            col = col_start + i
            x_offset = col * 48
            tex_id = f"{anim_name}_{i}"
            
            sub_resources += sub_resource_template.format(id=tex_id, x=x_offset, y=y_offset)
            
            frames_list.append(f"""{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_{tex_id}")
}}""")
        animations_content += ",\n".join(frames_list)
        animations_content += f"""],
"loop": true,
"name": &"{anim_name}",
"speed": 5.0
}}, """

    # Remove trailing comma
    animations_content = animations_content.rstrip(", ")

    content = tres_template.format(
        png_path=res_path_godot,
        sub_resources=sub_resources,
        res_name=res_name,
        animations_content=animations_content
    )
    
    os.makedirs(os.path.dirname(tres_path), exist_ok=True)
    
    with open(tres_path, "w") as f:
        f.write(content)

def main():
    preview_textures = {cat.capitalize(): [] for cat in categories}
    animation_paths = {cat.capitalize(): [] for cat in categories}
    
    for cat in categories:
        cat_cap = cat.capitalize()
        # Handle capitalization for searching directory since the folder might be Body, Hairstyle, etc.
        cat_dir = os.path.join(sprites_dir, cat_cap)
        if not os.path.exists(cat_dir):
            # Fallback to lowercase just in case
            cat_dir = os.path.join(sprites_dir, cat)
            if not os.path.exists(cat_dir):
                print(f"Directory not found for {cat}. Skipping.")
                continue
                
        tres_cat_dir = os.path.join(resources_dir, cat)
        
        png_files = sorted(glob.glob(os.path.join(cat_dir, "*.png")))
        for png in png_files:
            basename = os.path.basename(png)
            name_no_ext = os.path.splitext(basename)[0]
            
            tres_path = os.path.join(tres_cat_dir, name_no_ext + ".tres")
            
            godot_png = os.path.relpath(png, base_dir).replace("\\", "/")
            godot_tres = os.path.relpath(tres_path, base_dir).replace("\\", "/")
            
            generate_tres_for_image(godot_png, tres_path, cat)
            
            if godot_png.startswith("./"):
                godot_png = godot_png[2:]
            if godot_tres.startswith("./"):
                godot_tres = godot_tres[2:]
                
            preview_textures[cat_cap].append("res://" + godot_png)
            animation_paths[cat_cap].append("res://" + godot_tres)
            
        print(f"Processed {len(png_files)} files for {cat_cap}.")
            
    # Now generate a GDScript file CharacterAssets.gd
    gdscript_content = "extends Node\n\nconst PREVIEW_TEXTURES = {\n"
    for cat in preview_textures:
        gdscript_content += f'\t"{cat}": [\n'
        for path in preview_textures[cat]:
            gdscript_content += f'\t\t"{path}",\n'
        gdscript_content += "\t],\n"
    gdscript_content += "}\n\nconst COMPONENT_ANIM_PATHS = {\n"
    for cat in animation_paths:
        gdscript_content += f'\t"{cat.lower()}": [\n'
        for path in animation_paths[cat]:
            gdscript_content += f'\t\t"{path}",\n'
        gdscript_content += "\t],\n"
    gdscript_content += "}\n"
    
    out_script = os.path.join(base_dir, "scripts/CharacterAssets.gd")
    with open(out_script, "w") as f:
        f.write(gdscript_content)
    print(f"Generated {out_script}")

if __name__ == "__main__":
    main()
