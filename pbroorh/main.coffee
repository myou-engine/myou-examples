MyouEngine = require 'myou-engine'
{vec3, vec4, quat, mat3, mat4, clamp} = MyouEngine.vmath

# patch_vec = (vec) ->
#     vec._x = vec.x
#     Object.defineProperty vec, 'x',
#         get: -> @_x
#         set: (v) ->
#             debugger if not v? or v!=v
#             @_x = v
#     vec
#
# for m in [vec3, quat]
#     for k,f of m when typeof f == "function"
#         if k in ['create', 'new', 'clone']
#             m[k] = do(f) -> (args...) ->
#                 patch_vec f(args...)
#
# patch_mat = (mat) ->
#     for i in [0...9]
#         mat['_'+i] = mat['m0'+i]
#         Object.defineProperty mat, 'm0'+i,
#             get: new Function('return this._'+i)
#             set: new Function('v', "
#                 if ((v == null) || v !== v) {debugger}
#                 this._#{i} = v;")
#     mat
#
# for m in [mat3, mat4]
#     for k,f of m when typeof f == "function"
#         if k in ['create', 'new', 'clone']
#             m[k] = do(f) -> (args...) ->
#                 patch_mat f(args...)



{GLSLDebugger} = require '../../myou-glsl-debugger/main.coffee'
window.GLSLDebugger = GLSLDebugger

# Configure and create the engine instance
canvas = MyouEngine.create_full_window_canvas()
myou = new MyouEngine.Myou canvas,
    # data_dir is the path to the exported scenes,
    # relative to the HTML file.
    data_dir: 'data',
    gl_options: {antialias:false}

HPI = Math.PI/2

class DebugCamera extends MyouEngine.Behaviour
    on_init: ->
        @debug_camera = @viewports[0].camera
        @scene.clear_parent @debug_camera
        @debug_camera.set_rotation_order 'XYZ'
        @debug_camera.far_plane *= 10
        @debug_camera.cam_type = 'PERSP'
        @debug_camera.update_projection()
        @pivot = new @context.GameObject
        @scene.add_object @pivot
        @pivot.set_rotation_order 'XYZ'
        # we use @active instead of enabling/disabling the behaviour,
        # to be able to re-enable with a key
        @active = false
        @rotating = false
        @panning = false
        @distance = @pan_distance = 5
        @pivot_vis = {}
        # @debug = @scene.get_debug_draw()
        # @pivot_vis = new @debug.Point
        @pivot_vis.position = @pivot.position
        @disable_context_menu()
        this.enable_object_picking()
        @activate()

    on_tick: ->
        return if not @active
        if not @rotating
            # Change pivot and distance
            {width, height} = @viewports[0]
            {point} = @pick_object width*.5, height*.5, @viewports[0]
            if point?
                @distance = vec3.dist @debug_camera.position, point
                vec3.copy @pivot.position, point
            else
                vec3.set @pivot.position, 0, 0, -@distance
                wm = @debug_camera.get_world_matrix()
                vec3.transformMat4 @pivot.position, @pivot.position, wm

    on_pointer_down: (event) ->
        return if not @active
        if event.button == 0 and not @rotating
            @rotating = true
            vec4.copy @pivot.rotation, @debug_camera.rotation
            @pivot.rotate_x_deg -90, @pivot
            @debug_camera.parent_to @pivot

        if event.button == 2
            @pan_distance = @distance
            @panning = true

    on_pointer_move: (event) ->
        return if not @active
        if @rotating
            {rotation} = @pivot
            HPI = Math.PI * .5
            rotation.z -= event.delta_x * 0.01
            rotation.x -= event.delta_y * 0.01
            rotation.x = clamp rotation.x, -HPI, HPI
        else if @panning
            ratio = event.viewport.pixels_to_units * @pan_distance * 2
            x = -event.delta_x * ratio
            y = event.delta_y * ratio
            @debug_camera.translate vec3.new(x, y, 0), @debug_camera

    on_pointer_up: (event) ->
        # for some reason you can't trust that the button will be detected
        # (e.g. left down, right down, left up, right up: left not detected)
        # so we reset all buttons here
        if @rotating
            @rotating = false
            @debug_camera.clear_parent()
        @panning = false

    on_wheel: (event) ->
        return if not @active
        # zoom with wheel, but avoid going through objects
        # 54 is the approximate amount of pixels of one scroll step
        delta = @distance * (4/5) ** (-event.delta_y/54) - @distance
        delta = Math.max delta, -(@distance - @debug_camera.near_plane*1.2)
        @debug_camera.translate_z delta, @debug_camera
        @distance = vec3.dist @debug_camera.position, @pivot.position

    activate: ->
        if not @active
            [viewport] = @viewports
            viewport.debug_camera = @debug_camera
            viewport.recalc_aspect()
            for behaviour in @context.behaviours when behaviour != this
                if viewport in behaviour._real_viewports
                    behaviour._real_viewports = behaviour._real_viewports[...]
                    behaviour._real_viewports.splice(
                        behaviour._real_viewports.indexOf(viewport), 1)
            @active = true

    deactivate: ->
        if @active
            [viewport] = @viewports
            viewport.debug_camera = null
            for behaviour in @context.behaviours when behaviour != this
                if viewport in behaviour.viewports
                    behaviour._real_viewports = rv = []
                    for v in behaviour.viewports when not v.debug_camera?
                        rv.push v
            @active = false

    on_key_down: (event) ->
        switch event.key.toLowerCase()
            when 'q'
                if @active
                    @deactivate()
                else
                    @activate()


# Load the scene called "Scene", its objects and enable it
myou.load_scene('Scene').then (scene) ->
    # At this point, the scene has loaded but not the objects.
    # There are several functions for loading objects,
    # This one just loads the objects with visibility set to true
    Promise.all [
        # scene.load('visible', 'physics', {texture_size_ratio: .01})
        scene.load('visible', {texture_size_ratio: .01})
        scene.world_material?.load() or Promise.resolve()
    ]
.then ([scene]) ->
    # This part will only run after objects have loaded

    # Don't forget this or all you see will be black
    # scene.enable 'render', 'physics'
    scene.enable 'render'
    # TODO: The engine should do this
    scene.background_probe?.render()
    for ob in scene.children
        ob.instance_probe?()
        ob.instance_probes?()

    # myou.enable_debug_camera()
    new DebugCamera scene

    viewport = myou.canvas_screen.viewports[0]
    effects = [myou.SSAOEffect, myou.FXAAEffect, myou.BloomEffect]
    clicks = effects.length+1
    window.addEventListener 'keydown', (event) ->
        if event.key == 'e'
            viewport.clear_effects()
            clicks = ++clicks % (effects.length + 2)
            switch clicks
                when 0
                    null
                    console.log 'none'
                when effects.length+1
                    console.log 'all'
                    for effect in effects
                        viewport.add_effect new effect
                else
                    console.log effects[clicks-1]
                    viewport.add_effect new effects[clicks-1]
    for effect in effects
        viewport.add_effect new effect

    dbg_opts =
        functions: ['parallax_correct_ray']
    requestAnimationFrame ->
        # window.dbg = scene.objects['Plane.006']?.materials[0].last_shader.set_debugger(new GLSLDebugger dbg_opts)

    setTimeout ->
        $myou.objects.probe.probe_cube.render()
        $myou.objects.probe.probe_cube.render()
        $myou.objects.probe.probe_cube.render()
        $myou.objects.Sun.render_shadow=false
    , 1000

    # window.requestAnimationFrame = (x) -> setTimeout x, 200


    # Convenience variables for console access
    # They have $ in the name to avoid using them by mistake elsewhere
    window.$scene = scene
window.$myou = myou
window.$MyouEngine = MyouEngine
window.$vmath = require 'vmath'
