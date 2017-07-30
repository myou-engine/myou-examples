
MyouEngine = require 'myou-engine'
{vec3, quat} = require 'gl-matrix'

{GLSLDebugger} = require '../../myou-glsl-debugger'
window.GLSLDebugger = GLSLDebugger

# Configure and create the engine instance
canvas = MyouEngine.create_full_window_canvas()
myou = new MyouEngine.Myou canvas,
    # data_dir is the path to the exported scenes,
    # relative to the HTML file.
    data_dir: 'data',
    # If we don't need physics, we can save in loading time
    disable_physics: true,

# Load the scene called "Scene", its objects and enable it
myou.load_scene('Scene').then (scene) ->
    # At this point, the scene has loaded but not the objects.
    # There are several functions for loading objects,
    # This one just loads the objects with visibility set to true
    Promise.all [
        scene.load_visible_objects({texture_size_ratio: 1})
        scene.world_material.load()
    ]
.then ([scene]) ->
    # This part will only run after objects have loaded

    # Don't forget this or all you see will be black
    scene.enable_render()
    # TODO: The engine should do this
    scene.background_probe.render()
    for ob in scene.children
        ob.instance_probe()


    # To enable physics, remove the line "disable_physics" above
    # and uncomment the following line
    # scene.enable_physics()

    myou.render_manager.use_frustum_culling = false

    HPI = Math.PI/2

    empty = new myou.GameObject
    scene.add_object empty, 'empty'
    {Camera, Cube} = scene.objects
    scene.make_parent empty, Camera
    empty.rotation_order = 'Q'
    Camera.get_world_rotation empty.rotation
    quat.rotateX empty.rotation, empty.rotation, -HPI
    empty.set_rotation_order 'XYZ'
    vec3.set Camera.position, 0, -vec3.len(Camera.position), 0
    vec3.set Camera.rotation, HPI, 0, 0
    last_rotate_event = null

    # if Cube?
    #     initial_cube_pos = vec3.clone Cube.position

    scene.pre_draw_callbacks.push ->
        {mouse, touch} = myou.events
        rotate_event = touch.first_touch_event
        if mouse.left
            rotate_event = mouse
        if mouse.right
            pan_event = mouse
        if rotate_event
            empty.rotation[0] = clamp empty.rotation[0] - rotate_event.rel_y * 0.01, -HPI, HPI
            empty.rotation[2] -= rotate_event.rel_x * 0.01
        else if pan_event
            {width,height} = myou.render_manager
            dist = vec3.len(Camera.position)
            x = pan_event.rel_x/(width*Camera.projection_matrix[0])*dist*-2
            y = pan_event.rel_y/(height*Camera.projection_matrix[5])*dist*2
            empty.translate [x, y, 0], Camera
        # else if last_rotate_event? and mouse.movement_since_mousedown < 10
        #     if Cube?
        #         myou.physics.apply_force(Cube.body, [0,0,1000],
        #             [Math.random()-.5,Math.random()-.5,Math.random()-.5])
        #         Cube.body.activate()
        Camera.position[1] -= mouse.wheel * 0.5
        last_rotate_event = rotate_event
        # if Cube and Cube.position[2] < 3
        #     vec3.copy Cube.position, initial_cube_pos

    # dbg_opts =
    #     functions: ['bsdf_glossy_ggx_sun_light']
    # requestAnimationFrame ->
    #     window.dbg = scene.objects.roorh.materials[0].last_shader.set_debugger(new GLSLDebugger dbg_opts)

    # window.requestAnimationFrame = (x) -> setTimeout x, 200


    # Convenience variables for console access
    # They have $ in the name to avoid using them by mistake elsewhere
    window.$scene = scene
window.$myou = myou
window.$MyouEngine = MyouEngine
