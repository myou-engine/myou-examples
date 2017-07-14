
MyouEngine = require 'myou-engine'

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
    scene.load_visible_objects()
.then (scene) ->
    # This part will only run after objects have loaded

    # Don't forget this or all you see will be black
    scene.enable_render()

    # To enable physics, remove the line "disable_physics" above
    # and uncomment the following line
    #scene.enable_physics()

# Convenience variables for console access
# They have $ in the name to avoid using them by mistake elsewhere
window.$myou = myou
window.$MyouEngine = MyouEngine
