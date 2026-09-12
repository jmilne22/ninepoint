"""Small Blender vocabulary shared by the room and character render sources."""
import math
import bpy
from mathutils import Vector


def reset(width=384, height=216):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.data.orphans_purge(do_recursive=True)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = width, height
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.world.color = (.22, .22, .22)
    scene.view_settings.view_transform = 'Standard'
    return scene


def material(name, colour, texture=0, emission=0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*colour, 1)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    shader = nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*colour, 1)
    shader.inputs['Roughness'].default_value = .9
    if emission:
        shader.inputs['Emission Color'].default_value = (*colour, 1)
        shader.inputs['Emission Strength'].default_value = emission
    if texture:
        noise = nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = texture
        noise.inputs['Detail'].default_value = 3
        ramp = nodes.new('ShaderNodeValToRGB')
        ramp.color_ramp.elements[0].color = (*(c * .48 for c in colour), 1)
        ramp.color_ramp.elements[1].color = (*(min(c * 1.25, 1) for c in colour), 1)
        links.new(noise.outputs['Fac'], ramp.inputs[0])
        links.new(ramp.outputs[0], shader.inputs['Base Color'])
    return mat


def box(name, loc, size, mat, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new('worn edges', 'BEVEL')
        mod.width, mod.segments = bevel, 1
        obj.modifiers.new('weighted normals', 'WEIGHTED_NORMAL')
    return obj


def sphere(name, loc, size, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=1, location=loc)
    obj = bpy.context.object
    obj.name, obj.scale = name, size
    obj.data.materials.append(mat)
    return obj


def cylinder(name, loc, radius, depth, mat, vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def limb(name, a, b, radius, mat):
    middle = (Vector(a) + Vector(b)) / 2
    obj = cylinder(name, middle, radius, (Vector(b) - Vector(a)).length, mat, 8)
    obj.rotation_euler = (Vector(b) - Vector(a)).to_track_quat('Z', 'Y').to_euler()
    return obj


def camera(loc, target, scale):
    bpy.ops.object.camera_add(location=loc)
    obj = bpy.context.object
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat('-Z', 'Y').to_euler()
    obj.data.type, obj.data.ortho_scale = 'ORTHO', scale
    bpy.context.scene.camera = obj
    return obj


def light(name, loc, colour, energy, size=3):
    bpy.ops.object.light_add(type='AREA', location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.color, obj.data.energy, obj.data.shape, obj.data.size = colour, energy, 'DISK', size
    obj.rotation_euler = (Vector((0, 0, 0)) - obj.location).to_track_quat('-Z', 'Y').to_euler()
    return obj


def render(path):
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
