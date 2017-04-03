
MyouEngine = require 'myou-engine'

# Configure and create the engine instance
canvas = MyouEngine.create_full_window_canvas()
myou = new MyouEngine.Myou canvas,
    # data_dir is the path to the exported scenes,
    # relative to the HTML file.
    data_dir: 'data',
    # If we don't need physics, we can save in loading time
    disable_physics: true,

class VertexModifierExample
    constructor: (scene)->
        scene.pre_draw_callbacks.push => @update_data()

    get_code: ->
        [uniform_code, body_code] = require("!!raw-loader!./vertex_modifier_code.glsl").split('//BODY')
        uniform_lines = uniform_code.split('\n')
        body_lines = body_code.split('\n')

        return {uniform_lines, body_lines}

    get_data_store: (gl, prog)->
        gl.getUniformLocation prog, "time"

    update_uniforms: (gl, store)->
        gl.uniform1f store, @time

    update_data: ->
        @time = performance.now()/10000
        # @time = 0


# Load the scene called "Scene", its objects and enable it
myou.load_scene('Scene').then (scene) ->
    # At this point, the scene has loaded but not the objects.
    # There are several functions for loading objects,
    # This one just loads the objects with visibility set to true
    scene.load_visible_objects()
.then (scene) ->
    # This part will only run after objects have loaded

    # Don't forget this or all you see will be black
    scene.enable_render()

    # To enable physics, remove the line "disable_physics" above
    # and uncomment the following line
    #scene.enable_physics()

    vme = new VertexModifierExample scene
    scene.objects.grid.vertex_modifiers.push vme


# Convenience variables for console access
# They have $ in the name to avoid using them by mistake elsewhere
window.$myou = myou
window.$MyouEngine = MyouEngine
