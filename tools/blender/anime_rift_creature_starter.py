"""
Anime Rift Ascension - Creature Art Starter

Blender 4.x helper for the first three original creature prototypes.
Set ASSET below, run the script in Blender's Scripting workspace, then refine the
result before export. If EXPORT_DIR is set, the selected asset is also exported
as FBX using the exact filename expected by CreatureArtService.

This is intentionally an ORIGINAL anime-inspired blockout, not a copy of any
existing anime/game character.
"""

import bpy
import math
import os
from mathutils import Vector

ASSET = "Enemy_DojoRogue"  # Enemy_DojoRogue | Boss_RiftTyrant | Pet_RiftlingPrime
EXPORT_DIR = ""            # e.g. r"C:\AnimeRift\exports"; empty = do not export


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.materials):
        pass


def make_mat(name, rgba, metallic=0.0, roughness=0.55):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = rgba
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = rgba
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
    return mat


def finish_obj(obj, name, mat, scale=None):
    obj.name = name
    if scale is not None:
        obj.scale = scale
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat:
        obj.data.materials.append(mat)
    return obj


def cube(name, loc, scale, mat, bevel=0.08):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = finish_obj(bpy.context.object, name, mat, scale)
    if bevel > 0:
        modifier = obj.modifiers.new("SoftEdges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    return obj


def sphere(name, loc, scale, mat):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1, location=loc)
    return finish_obj(bpy.context.object, name, mat, scale)


def cylinder(name, loc, radius, depth, mat, rotation=(0, 0, 0), vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    return finish_obj(bpy.context.object, name, mat)


def cone(name, loc, r1, r2, depth, mat, rotation=(0, 0, 0), vertices=10):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rotation)
    return finish_obj(bpy.context.object, name, mat)


def create_humanoid_armature(name, height=4.2):
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm = bpy.context.object
    arm.name = name + "_Rig"
    data = arm.data
    data.name = name + "_Armature"
    default = data.edit_bones[0]
    data.edit_bones.remove(default)

    def bone(bname, head, tail, parent=None):
        b = data.edit_bones.new(bname)
        b.head = head
        b.tail = tail
        if parent:
            b.parent = data.edit_bones[parent]
        return b

    bone("Root", (0, 0, 0), (0, 0, 0.35))
    bone("Hips", (0, 0, 0.35), (0, 0, 1.15), "Root")
    bone("Spine", (0, 0, 1.15), (0, 0, 2.15), "Hips")
    bone("Chest", (0, 0, 2.15), (0, 0, 3.05), "Spine")
    bone("Neck", (0, 0, 3.05), (0, 0, 3.35), "Chest")
    bone("Head", (0, 0, 3.35), (0, 0, height), "Neck")
    bone("UpperArm.L", (0, 0, 2.85), (-1.05, 0, 2.55), "Chest")
    bone("LowerArm.L", (-1.05, 0, 2.55), (-1.75, 0, 1.95), "UpperArm.L")
    bone("Hand.L", (-1.75, 0, 1.95), (-2.10, 0, 1.72), "LowerArm.L")
    bone("UpperArm.R", (0, 0, 2.85), (1.05, 0, 2.55), "Chest")
    bone("LowerArm.R", (1.05, 0, 2.55), (1.75, 0, 1.95), "UpperArm.R")
    bone("Hand.R", (1.75, 0, 1.95), (2.10, 0, 1.72), "LowerArm.R")
    bone("UpperLeg.L", (-0.48, 0, 1.0), (-0.52, 0, 0.05), "Hips")
    bone("LowerLeg.L", (-0.52, 0, 0.05), (-0.52, 0, -0.90), "UpperLeg.L")
    bone("Foot.L", (-0.52, 0, -0.90), (-0.52, -0.45, -1.05), "LowerLeg.L")
    bone("UpperLeg.R", (0.48, 0, 1.0), (0.52, 0, 0.05), "Hips")
    bone("LowerLeg.R", (0.52, 0, 0.05), (0.52, 0, -0.90), "UpperLeg.R")
    bone("Foot.R", (0.52, 0, -0.90), (0.52, -0.45, -1.05), "LowerLeg.R")

    bpy.ops.object.mode_set(mode="OBJECT")
    arm.show_in_front = True
    return arm


def rigid_bind(obj, armature, bone_name):
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = armature
    obj.parent = armature
    obj.matrix_parent_inverse = armature.matrix_world.inverted()


def build_dojo_rogue():
    skin = make_mat("Skin", (0.34, 0.24, 0.20, 1))
    cloth = make_mat("RogueCloth", (0.10, 0.16, 0.12, 1), roughness=0.8)
    cloth2 = make_mat("RogueClothLight", (0.24, 0.34, 0.23, 1), roughness=0.75)
    metal = make_mat("RogueMetal", (0.16, 0.18, 0.17, 1), metallic=0.55, roughness=0.32)
    accent = make_mat("RogueAccent", (0.33, 0.52, 0.28, 1), roughness=0.48)
    wrap = make_mat("HandWrap", (0.58, 0.53, 0.43, 1), roughness=0.9)
    arm = create_humanoid_armature("Enemy_DojoRogue")

    pieces = []
    pieces += [(cube("Torso", (0, 0, 2.15), (0.82, 0.48, 0.92), cloth), "Chest")]
    pieces += [(cube("Waist", (0, 0, 1.15), (0.67, 0.43, 0.34), cloth2), "Hips")]
    pieces += [(sphere("Head", (0, 0, 3.65), (0.63, 0.58, 0.68), skin), "Head")]
    pieces += [(cube("Headband", (0, -0.56, 3.78), (0.72, 0.08, 0.11), accent), "Head")]
    pieces += [(cone("TopKnot", (0, 0.10, 4.34), 0.22, 0.07, 0.62, cloth), "Head")]

    for side, sx in (("L", -1), ("R", 1)):
        pieces += [(cylinder(f"UpperArm.{side}", (0.77*sx, 0, 2.55), 0.25, 1.35, skin, rotation=(0, math.radians(62*sx), 0)), f"UpperArm.{side}")]
        pieces += [(cylinder(f"Forearm.{side}", (1.43*sx, 0, 2.06), 0.23, 1.12, wrap, rotation=(0, math.radians(48*sx), 0)), f"LowerArm.{side}")]
        pieces += [(sphere(f"Fist.{side}", (1.95*sx, -0.02, 1.74), (0.30, 0.32, 0.30), wrap), f"Hand.{side}")]
        pieces += [(cube(f"ShoulderGuard.{side}", (0.88*sx, 0, 2.94), (0.46, 0.57, 0.23), metal), "Chest")]
        pieces += [(cylinder(f"UpperLeg.{side}", (0.50*sx, 0, 0.52), 0.31, 1.20, cloth, rotation=(0, 0, 0)), f"UpperLeg.{side}")]
        pieces += [(cylinder(f"LowerLeg.{side}", (0.52*sx, 0, -0.47), 0.27, 1.10, cloth2), f"LowerLeg.{side}")]
        pieces += [(cube(f"Foot.{side}", (0.52*sx, -0.23, -1.03), (0.32, 0.54, 0.18), metal), f"Foot.{side}")]

    for obj, bone in pieces:
        rigid_bind(obj, arm, bone)
    return arm


def build_rift_tyrant():
    skin = make_mat("TyrantSkin", (0.16, 0.12, 0.17, 1), roughness=0.65)
    armor = make_mat("TyrantArmor", (0.12, 0.11, 0.14, 1), metallic=0.72, roughness=0.28)
    armor2 = make_mat("TyrantArmor2", (0.24, 0.20, 0.27, 1), metallic=0.55, roughness=0.34)
    core = make_mat("TyrantCore", (0.55, 0.25, 0.48, 1), metallic=0.15, roughness=0.22)
    horn = make_mat("TyrantHorn", (0.25, 0.23, 0.27, 1), roughness=0.50)
    arm = create_humanoid_armature("Boss_RiftTyrant", height=4.5)
    arm.scale = (1.45, 1.45, 1.45)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    pieces = []
    pieces += [(cube("Torso", (0, 0, 2.20), (1.18, 0.68, 1.08), armor), "Chest")]
    pieces += [(cube("Waist", (0, 0, 1.10), (0.90, 0.58, 0.38), armor2), "Hips")]
    pieces += [(sphere("Head", (0, 0, 3.82), (0.72, 0.66, 0.76), skin), "Head")]
    pieces += [(sphere("Core_AnimeRiftTint", (0, -0.72, 2.20), (0.40, 0.18, 0.48), core), "Chest")]
    pieces[-1][0]["AnimeRiftTint"] = True
    pieces += [(cube("Mantle", (0, 0.18, 3.10), (1.72, 0.52, 0.30), armor2), "Chest")]

    for side, sx in (("L", -1), ("R", 1)):
        pieces += [(cone(f"Horn.{side}", (0.58*sx, 0.05, 4.55), 0.20, 0.035, 1.40, horn, rotation=(0, math.radians(-24*sx), math.radians(-14*sx))), "Head")]
        pieces += [(cube(f"Pauldron.{side}", (1.20*sx, 0, 3.02), (0.72, 0.78, 0.42), armor), "Chest")]
        pieces += [(cylinder(f"UpperArm.{side}", (0.98*sx, 0, 2.45), 0.36, 1.55, armor2, rotation=(0, math.radians(59*sx), 0)), f"UpperArm.{side}")]
        pieces += [(cylinder(f"Forearm.{side}", (1.72*sx, 0, 1.92), 0.34, 1.28, armor, rotation=(0, math.radians(48*sx), 0)), f"LowerArm.{side}")]
        pieces += [(sphere(f"Claw.{side}", (2.28*sx, -0.02, 1.60), (0.40, 0.42, 0.38), armor), f"Hand.{side}")]
        pieces += [(cylinder(f"UpperLeg.{side}", (0.58*sx, 0, 0.45), 0.40, 1.40, armor2), f"UpperLeg.{side}")]
        pieces += [(cylinder(f"LowerLeg.{side}", (0.60*sx, 0, -0.62), 0.36, 1.30, armor), f"LowerLeg.{side}")]
        pieces += [(cube(f"Foot.{side}", (0.60*sx, -0.28, -1.25), (0.42, 0.64, 0.24), armor), f"Foot.{side}")]

    for obj, bone in pieces:
        rigid_bind(obj, arm, bone)
    return arm


def create_pet_armature(name):
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm = bpy.context.object
    arm.name = name + "_Rig"
    data = arm.data
    data.name = name + "_Armature"
    data.edit_bones.remove(data.edit_bones[0])

    def bone(bname, head, tail, parent=None):
        b = data.edit_bones.new(bname)
        b.head, b.tail = head, tail
        if parent:
            b.parent = data.edit_bones[parent]
        return b

    bone("Root", (0, 0, 0), (0, 0, 0.3))
    bone("Body", (0, 0, 0.3), (0, 0, 1.2), "Root")
    bone("Head", (0, -0.65, 1.0), (0, -1.35, 1.45), "Body")
    bone("Wing.L", (-0.4, 0, 0.95), (-1.35, 0.15, 1.05), "Body")
    bone("Wing.R", (0.4, 0, 0.95), (1.35, 0.15, 1.05), "Body")
    bone("Tail", (0, 0.55, 0.75), (0, 1.55, 0.45), "Body")
    bpy.ops.object.mode_set(mode="OBJECT")
    arm.show_in_front = True
    return arm


def build_riftling_prime():
    body_mat = make_mat("RiftlingBody", (0.16, 0.18, 0.20, 1), roughness=0.72)
    accent = make_mat("RiftlingAccent", (0.80, 0.68, 0.27, 1), metallic=0.18, roughness=0.30)
    pale = make_mat("RiftlingPale", (0.76, 0.72, 0.55, 1), roughness=0.48)
    arm = create_pet_armature("Pet_RiftlingPrime")
    pieces = []
    pieces += [(sphere("Body", (0, 0, 0.75), (0.78, 0.95, 0.66), body_mat), "Body")]
    pieces += [(sphere("Head", (0, -0.82, 1.18), (0.62, 0.60, 0.58), body_mat), "Head")]
    pieces += [(sphere("Core_AnimeRiftTint", (0, -1.34, 1.14), (0.23, 0.12, 0.25), accent), "Head")]
    pieces[-1][0]["AnimeRiftTint"] = True
    pieces += [(cone("Ear.L", (-0.35, -0.86, 1.72), 0.20, 0.03, 0.70, pale, rotation=(math.radians(-12), 0, math.radians(12))), "Head")]
    pieces += [(cone("Ear.R", (0.35, -0.86, 1.72), 0.20, 0.03, 0.70, pale, rotation=(math.radians(-12), 0, math.radians(-12))), "Head")]
    pieces += [(cube("Wing.L", (-0.95, 0.10, 0.94), (0.72, 0.18, 0.45), pale, bevel=0.12), "Wing.L")]
    pieces += [(cube("Wing.R", (0.95, 0.10, 0.94), (0.72, 0.18, 0.45), pale, bevel=0.12), "Wing.R")]
    pieces += [(cone("Tail", (0, 1.05, 0.62), 0.26, 0.08, 1.30, body_mat, rotation=(math.radians(72), 0, 0)), "Tail")]
    for obj, bone in pieces:
        rigid_bind(obj, arm, bone)
    return arm


def export_asset(asset_name, armature):
    if not EXPORT_DIR:
        return
    os.makedirs(EXPORT_DIR, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    for obj in bpy.context.scene.objects:
        if obj.parent == armature:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = armature
    path = os.path.join(EXPORT_DIR, asset_name + ".fbx")
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        object_types={"ARMATURE", "MESH"},
        add_leaf_bones=False,
        bake_anim=False,
        apply_scale_options="FBX_SCALE_UNITS",
        axis_forward="-Z",
        axis_up="Y",
    )
    print("Exported:", path)


def main():
    clear_scene()
    builders = {
        "Enemy_DojoRogue": build_dojo_rogue,
        "Boss_RiftTyrant": build_rift_tyrant,
        "Pet_RiftlingPrime": build_riftling_prime,
    }
    if ASSET not in builders:
        raise ValueError(f"Unknown ASSET: {ASSET}")
    armature = builders[ASSET]()
    export_asset(ASSET, armature)
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    print(f"Anime Rift blockout ready: {ASSET}")


if __name__ == "__main__":
    main()
