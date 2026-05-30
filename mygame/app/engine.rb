module App
  class Engine
    attr_accessor :player, :engine, :floating_text, :tick_count, :debug

    # Which chunks should be active? Add a 1-chunk border as buffer.
    CHUNK_LOAD_RADIUS = 2  # chunks around the visible area


    def initialize
      @loaded_chunks = {}
      @initial_chunk_load = Fiber.new { update_loaded_chunks(fiber: true) }
      @initial_chunks_loaded = false
      @debug = true
      @show_grid = false
      @camera = SpriteKit::Camera.new(path: :camera)
      @camera_updated = true
      @floating_text = App::UI::FloatingText.new(engine: self, path: @camera.path)
      @tick_count = 0
      @target = nil
      @target_circle = ::App::UI::Circle.new(type: :target, blendmode_enum: 1)

      @buttons = {

      }

      player_frame = ::App::UI::Frame.new(
        x: 50,
        y: 50.from_top,
        w: 96,
        h: 48
      )

      enemy_frame = ::App::UI::Frame.new(
        x: player_frame.x + player_frame.w,
        y: player_frame.y,
        w: player_frame.w,
        h: player_frame.h
      )

      # x_start = (Grid.w / 2) - 64
      # y_start = (Grid.h / 2) - 64
      # x_end = x_start + 128
      # y_end = y_start + 128
      size = 96
      @attack_button = ::App::UI::AttackCircle.new(w: size, h: size, x: (size * 2).from_right, y: size)


      @save_directory = "data/saves"
      @player_file = "#{@save_directory}/player.dat"

      @map = Map.new(engine: self, save_directory: @save_directory)

      @player = load_player
      @player ||= Player.new(engine: self).tap do |player|
        player.x = @map.w / 2
        player.y = @map.h / 2
        player.target_y = player.y
        player.target_x = player.x
        player.w = 18 * 2
        player.h = 16 * 2
      end


      @reset_button = ::SpriteKit::Primitives.button(x: 50, y: Grid.h - 100, text: "Generate new map", background_color: {
        r: 255,
        b: 255,
        g: 255,
        a: 128,
      })


      @ui = {
        attack_button: @attack_button.to_a,
        # player_frame: player_frame,
        # enemy_frame: enemy_frame,
        reset_button: @reset_button.primitives
      }
      @radial_buttons = UI::RadialMenu.new(anchor: @attack_button, number_of_buttons: 5)
      @max_elapsed_ms = 6
    end

    def loading?
      @map.generating? || !@initial_chunks_loaded
    end

    def tick(args)
      @debug_renderables = []
      @inputs = args.inputs
      @outputs = args.outputs
      @keyboard = @inputs.keyboard
      @world_mouse = @camera.to_world_space(@inputs.mouse)
      @map.outputs = @outputs
      input(args)
      calc(args)
      render(args)
      @camera_updated = false
      @tick_count += 1
    end

    def reset!
      @loaded_chunks = {}
      @initial_chunks_loaded = false
      @map = Map.new(engine: self, force: true)
      @initial_chunk_load = Fiber.new { update_loaded_chunks(fiber: true) }
    end

    def input(args)
      return if loading?

      # Every frame we expect the player to move 1.25px. In total, this is 75px per second.
      speed = (@player.speed / 100) * (FPS / 45) # * 10
      # speed = 1.25

      if @inputs.up
        @player.target_y += speed
        @player.direction = :up
        @player.state = :walking
      end

      if @inputs.down
        @player.target_y -= speed
        @player.direction = :down
        @player.state = :walking
      end

      if @inputs.right
        @player.target_x += speed
        @player.direction = :right
        @player.state = :walking
      end

      if @inputs.left
        @player.target_x -= speed
        @player.direction = :left
        @player.state = :walking
      end

      if @inputs.keyboard.key_down.period
        @debug = !@debug
      end

      if @inputs.keyboard.key_down.g
        @show_grid = !@show_grid
      end

      if !@inputs.down && !@inputs.up && !@inputs.left && !@inputs.right
        @player.state = :idle
      end

      @player.targeting_angle = @world_mouse.angle_from(@player)

      if @inputs.keyboard.key_down.one
        @player.active_spell = @player.spells.one
      end



      args.outputs.debug << "#{@reset_button}"
      if @inputs.mouse.buttons.left.click
        if @inputs.mouse.intersect_rect?(@reset_button)
          reset!
          return
        end

        character = Geometry.find_intersect_rect(@world_mouse, @objects_in_viewport + @entities_in_viewport)
        if @player.active_spell
          @player.active_spell.cast(player: @player)
          @player.active_spell = nil
        else
          @player.target = character
          if !character
            @player.state = :idle
          end
        end
      end

      if @player.target
        character = @player.target
        if character
          @target_circle.x = character.x - 2
          @target_circle.y = character.y - 2
          @target_circle.w = (character.hit_box&.w || character.w) + 4
          @target_circle.h = (character.hit_box&.h || (character.h / 2)) + 4
        end
      end

      handle_camera_zoom
    end

    def calc(args)
      return if loading?

      update_loaded_chunks
      @map.activate_entities_near(@camera)
      # @map.deactivate_distant_entities(@camera)

      @objects_in_viewport = @map.objects_in_viewport(@camera, engine: self)

      @collision_in_viewport = []

      Array.each(@objects_in_viewport) do |obj|
        if obj&.collision
          obj = obj.dup
          obj.w = obj.collision.w
          obj.h = obj.collision.h
          obj.x = obj.x + obj.collision.x
          obj.y = obj.y + obj.collision.y
          @collision_in_viewport << obj
        end
      end

      calc_player
      calc_camera
      args.outputs.debug << "dormant: #{@map.dormant_entities.length} active: #{@map.active_entities.length}"
    end

    def handle_camera_zoom
      # Zoom
      if @inputs.keyboard.key_down.equal_sign || @inputs.keyboard.key_down.plus
        @camera.target_scale += 0.25
        @camera.target_scale = 4 if @camera.target_scale > 4
      elsif @inputs.keyboard.key_down.minus
        @camera.target_scale -= 0.25
        @camera.target_scale = 0.5 if @camera.target_scale < 0.5
      elsif @inputs.keyboard.zero
        @camera.target_scale = 1
      end
    end

    def calc_player
      # this is where we do collision.
      diff_x = @player.x - @player.target_x
      diff_y = @player.y - @player.target_y

      @player.x = @player.target_x

      collision_x = Geometry.find_intersect_rect(@player.collision, @collision_in_viewport)

      if collision_x
        @player.x = @player.x + diff_x
      end

      @player.y = @player.target_y

      collision_y = Geometry.find_intersect_rect(@player.collision, @collision_in_viewport)
      if collision_y
        @player.y = @player.y + diff_y
      end

      @player.target_x = @player.x
      @player.target_y = @player.y
    end

    def calc_camera
      @camera.target_x = @player.x
      @camera.target_y = @player.y

      @camera_updated = (@camera.target_x > 0 || @camera.target_y > 0 || @camera.target_scale > 0)

      @camera.scale += (@camera.target_scale - @camera.scale)
      @camera.x += (@camera.target_x - @camera.x)
      @camera.y += (@camera.target_y - @camera.y)
    end

    def update_loaded_chunks(fiber: false)
      i = 0
      generation_start = App.current_time_ms

      fiber_yield = proc {
        i += 1
        if i >= 500
          i = 0
          if App.current_time_ms - generation_start >= @max_elapsed_ms
            Fiber.yield
            generation_start = App.current_time_ms
          end
        end
      }

      chunk_px = Map::CHUNK_TILES * @map.tile_size
      world = @camera.to_world_space!(@camera.viewport.dup)

      min_cx = (world.x / chunk_px).floor - CHUNK_LOAD_RADIUS
      min_cy = (world.y / chunk_px).floor - CHUNK_LOAD_RADIUS
      max_cx = ((world.x + world.w) / chunk_px).ceil + CHUNK_LOAD_RADIUS
      max_cy = ((world.y + world.h) / chunk_px).ceil + CHUNK_LOAD_RADIUS

      needed = {}
      min_cx.upto(max_cx) do |cx|
        min_cy.upto(max_cy) do |cy|
          key = @map.chunk_key(cx, cy)
          needed[key] = [cx, cy]

          fiber_yield.call if fiber

          if @debug
            @debug_renderables.concat(SpriteKit::Primitives.borders(
              {
                x: cx * chunk_px,
                y: cy * chunk_px,
                w: chunk_px,
                h: chunk_px,
              },
              color: { r: 0, g: 255, b: 255, a: 200 }
            ).values)
          end
        end
      end

      needed.each do |key, (cx, cy)|
        unless @loaded_chunks[key]
          @map.load_chunk(cx, cy)
          @loaded_chunks[key] = true
        end

        fiber_yield.call if fiber
      end

      @loaded_chunks.keys.each do |key|
        unless needed[key]
          cx = @map.chunk_key_to_cx(key)
          cy = @map.chunk_key_to_cy(key)
          @map.unload_chunk(cx, cy)
          @loaded_chunks.delete(key)
        end

        fiber_yield.call if fiber
      end

      if @tick_count % (60 * 5) == 0
        @map.save_dirty_chunks
      end

      if @tick_count % (60 * 1) == 0
        @map.save_active_entities
      end
    end

    def render(args)
      if @map.generating?
        @map.tick_generate

        # Loading bar here
        return
      end

      if !@initial_chunks_loaded
        load_initial_chunks
        return
      end

      camera_rt = args.outputs[@camera_path]
      viewport = @camera.viewport
      camera_rt.w = viewport.w
      camera_rt.h = viewport.h
      camera_rt.background_color = [0,0,0,255]

      # if @camera_updated
      #   @viewport_tiles = @map.tiles_in_viewport(@camera).map do |tile|
      #     @camera.to_screen_space!(tile.dup)
      #   end
      # end

      @player.update

      # args.outputs.debug << "TILES: #{@map.tiles.keys.length}"

      # @entities_in_viewport = @map.entities_in_viewport(@camera)
      @entities_in_viewport = @map.active_entities.values

      screen_renderables = []

      Array.each(@objects_in_viewport + @entities_in_viewport) do |obj|
        obj.update
        screen_renderables.concat(obj.prefab)
      end

      if @player.target
        @target_circle.update
        screen_renderables << @target_circle
      end

      if @player.active_spell
        @player.active_spell.update(player: @player, outputs: args.outputs)
        if @player.active_spell.indicator.is_a?(Array)
          screen_renderables.concat(@player.active_spell.indicator)
        else
          screen_renderables.push(@camera.to_screen_space!(@player.active_spell.indicator.dup))
        end
      end

      if @debug
        @collision_in_viewport.each do |obj|
          obj.path = :solid
          obj.r = 255
          obj.a = 128
          obj.b = 0
          obj.g = 0
          @debug_renderables << obj
        end
        @debug_renderables << @player.collision.merge({ path: :solid, r: 255, b: 0, g: 0, a: 128 })
      end

      screen_renderables = screen_renderables
        .concat(@player.prefab)
        .concat(@debug_renderables)
        .flatten
        .map { |spr| @camera.to_screen_space!(spr.dup) }

      if @show_grid
        screen_renderables.unshift(*render_grid)
      end

      args.outputs[@camera.path].primitives
        .concat(@map.chunks_in_viewport(@camera).map { |spr| @camera.to_screen_space!(spr.dup) })
        .concat(screen_renderables)

      args.outputs.primitives.concat(
        [
          @camera.viewport,
        ]
          .concat(@ui.values.flatten)
          .concat(@radial_buttons.buttons)
          .concat(@floating_text.flush(@camera))
          .concat(
            GTK.framerate_diagnostics_primitives.map do |primitive|
              primitive.x = 500.from_right + primitive.x
              primitive.scale_quality = 2
              primitive
            end
          )
      )


      if @tick_count % 20 == 0
        save_player
      end
    end

    def save_player
      GTK.serialize_state(@player_file, { player: @player.serialize })
    end

    def load_player
      data = GTK.deserialize_state(@player_file)
      Player.new(engine: self, **data.player) if data&.player
    end

    def load_initial_chunks
      if @initial_chunk_load&.alive?
        @initial_chunk_load.resume
      else
        @initial_chunks_loaded = true
      end
    end

    def render_grid
      world = @camera.to_world_space!(@camera.viewport.dup)
      tile_size = 32

      min_x = [(world.x / tile_size).floor * tile_size, 0].max
      min_y = [(world.y / tile_size).floor * tile_size, 0].max
      max_x = world.x + world.w
      max_y = world.y + world.h

      solids = []

      x = min_x
      while x <= max_x
        s = { x: x, y: min_y, w: 1, h: max_y - min_y }
        @camera.to_screen_space!(s)
        solids << { x: s.x, y: s.y, w: 1, h: s.h, r: 255, g: 255, b: 255, a: 255, path: :solid }
        x += tile_size
      end

      y = min_y
      while y <= max_y
        s = { x: min_x, y: y, w: max_x - min_x, h: 1 }
        @camera.to_screen_space!(s)
        solids << { x: s.x, y: s.y, w: s.w, h: 1, r: 255, g: 255, b: 255, a: 255, path: :solid }
        y += tile_size
      end

      solids
    end
  end
end
