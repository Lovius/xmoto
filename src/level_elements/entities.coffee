b2FixtureDef = Box2D.Dynamics.b2FixtureDef

class Entities

  constructor: (level) ->
    @level        = level
    @assets       = level.assets
    @list         = []
    @strawberries = []

  parse: (xml) ->
    xml_entities = $(xml).find('entity')

    # parse entity xml
    for xml_entity in xml_entities
      entity =
        id:      $(xml_entity).attr('id')
        type_id: $(xml_entity).attr('typeid')
        size:
          r:      parseFloat($(xml_entity).find('size').attr('r'))
          width:  parseFloat($(xml_entity).find('size').attr('width'))
          height: parseFloat($(xml_entity).find('size').attr('height'))
        position:
          x:     parseFloat($(xml_entity).find('position').attr('x'))
          y:     parseFloat($(xml_entity).find('position').attr('y'))
          angle: parseFloat($(xml_entity).find('position').attr('angle'))
        params: []

      # parse params xml
      xml_params = $(xml_entity).find('param')
      for xml_param in xml_params
        param =
          name:  $(xml_param).attr('name')
          value: $(xml_param).attr('value').toLowerCase()
        entity.params.push(param)

      # Get default values for sprite from theme
      texture_name = Entities.texture_name(entity)
      if texture_name
        sprite = @assets.theme.sprite_params(texture_name)

        entity.size.width  = sprite.size.width  if not entity.size.width
        entity.size.height = sprite.size.height if not entity.size.height
        entity.center =
          x: sprite.center.x
          y: sprite.center.y
        entity.center.x = entity.size.width/2  if not entity.center.x
        entity.center.y = entity.size.height/2 if not entity.center.y
        entity.delay    = sprite.delay
        entity.frames   = sprite.frames
        entity.display  = true

      @list.push(entity)

    return this

  init: ->
    for entity in @list

      texture_name = Entities.texture_name(entity)

      if texture_name
        if entity.frames == 0
          @assets.anims.push(texture_name)
        else
          for i in [0..entity.frames-1]
            @assets.anims.push(Entities.frame_name(texture_name, i))

      # End of level
      if entity.type_id == 'EndOfLevel'
        @create_entity(entity, 'end_of_level')
        @end_of_level = entity

      # Strawberries
      else if entity.type_id == 'Strawberry'
        @create_entity(entity, 'strawberry')
        @strawberries.push(entity)

      # Player start
      else if entity.type_id == 'PlayerStart'
        @player_start =
          x: entity.position.x
          y: entity.position.y

  create_entity: (entity, name) ->
    # Create fixture
    fixDef = new b2FixtureDef()
    fixDef.shape = new b2CircleShape(entity.size.r)
    fixDef.isSensor = true

    # Create body
    bodyDef = new b2BodyDef()

    # Assign body position
    bodyDef.position.x = entity.position.x
    bodyDef.position.y = entity.position.y

    bodyDef.userData =
      name:   name
      entity: entity

    bodyDef.type = b2Body.b2_staticBody

    # Assign fixture to body and add body to 2D world
    body = @level.world.CreateBody(bodyDef)
    body.CreateFixture(fixDef)

    body

  display_sprites: (ctx) ->
    for entity in @list
      if entity.type_id == 'Sprite'
        @display_entity(ctx, entity)

  display_items: (ctx) ->
    for entity in @list
      if entity.type_id == 'EndOfLevel' or entity.type_id == "Strawberry"
        @display_entity(ctx, entity)

  display_entity: (ctx, entity) ->
    if entity.display
      texture_name = Entities.texture_name(entity)
      if entity.frames
        i = @level.current_time % (entity.frames * entity.delay * 1000)
        i = Math.floor(i / (entity.delay * 1000))
        texture_name = Entities.frame_name(texture_name, i) if entity.frames

      ctx.save()
      ctx.translate(entity.position.x, entity.position.y)
      ctx.scale(1, -1)
      ctx.drawImage(@assets.get(texture_name),
                    -entity.size.width  + entity.center.x,
                    -entity.size.height + entity.center.y,
                    entity.size.width,
                    entity.size.height)
      ctx.restore()

  @texture_name = (entity) ->
    if entity.type_id == 'Sprite'
      for param in entity.params
        if param.name == 'name'
          return param.value
    else if entity.type_id == 'EndOfLevel'
      return 'checkball'
    else if entity.type_id == 'Strawberry'
      return 'cog2'

  @frame_name = (texture_name, frame_number) ->
    "#{texture_name}_" + (frame_number/100.0).toFixed(2).toString().substring(2)
