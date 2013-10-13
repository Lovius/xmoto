play_level = (name) ->
  level = new Level()
  level.load_from_file(name)

  # Load assets for this level before doing anything else
  level.assets.load( ->
    update = ->
      level.input.move_moto()
      level.world.Step(1.0 / 60.0, 10, 10)
      level.world.ClearForces()
      level.display(false)

    # Render 2D environment
    window.game_loop = setInterval(update, 1000 / 60)
  )

$ ->
  play_level($("#levels option:selected").val())

  $("#levels").on('change', ->
    clearInterval(window.game_loop)
    play_level($(this).val())
  )
