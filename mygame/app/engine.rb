module App
  class Engine
    attr_accessor :player, :engine, :characters, :floating_text, :tick_count

    def initialize
      @camera = SpriteKit::Camera.new(path: :camera)
      @floating_text = App::UI::FloatingText.new(engine: self, path: @camera.path)
      @player = Player.new(engine: self).tap do |player|
        player.x = Grid.w / 2
        player.y = Grid.h / 2
        player.target_y = player.y
        player.target_x = player.x
      end
      @tick_count = 0
      @target = nil
      @target_circle = ::App::UI::Circle.new(type: :target)
      @characters = [
        Enemy.new(
          engine: self,
          **App::ENEMIES[:hyena],
          x: 300,
          y: 300,
          w: 32,
          h: 32,
        )
      ]

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
      @ui = {
        attack_button: @attack_button.to_a,
        player_frame: player_frame,
        enemy_frame: enemy_frame,
      }

      @radial_buttons = UI::RadialMenu.new(anchor: @attack_button, number_of_buttons: 5)
    end


    def debug_triangle(triangle)
      [
        { x: triangle.x, y: triangle.y, text: "x: #{triangle.x}, y: #{triangle.y}" },
        { x: triangle.x2, y: triangle.y2, text: "x2: #{triangle.x2}, y2: #{triangle.y2}" },
        { x: triangle.x3, y: triangle.y3, text: "x3: #{triangle.x3}, y3: #{triangle.y3}" },
      ]
    end

    def tick(args)
      @inputs = args.inputs
      @outputs = args.outputs
      @keyboard = @inputs.keyboard
      @world_mouse = @camera.to_world_space(@inputs.mouse)
      input(args)
      calc(args)
      render(args)
      @tick_count += 1
    end

    def input(args)
      # Every frame we expect the player to move 1.25px. In total, this is 75px per second.
      # speed = (@player.speed / 100) * (FPS / 45)
      speed = 1.25

      if @inputs.up
        @player.target_y += speed
        @player.direction = :up
      elsif @inputs.down
        @player.target_y -= speed
        @player.direction = :down
      elsif @inputs.right
        @player.target_x += speed
        @player.direction = :right
      elsif @inputs.left
        @player.target_x -= speed
        @player.direction = :left
      end

      if @inputs.keyboard.key_down.one
        @player.active_spell = @player.spells[:one]
      end

      @player.targeting_angle = @world_mouse.angle_from(@player)
      # @outputs.debug << "angle: #{@player.angle}"

      if @inputs.mouse.buttons.left.click
        if @player.active_spell
          @player.active_spell.cast(player: @player)
          @player.active_spell = nil
        else
          character = Geometry.find_intersect_rect(@world_mouse, @characters)
          @player.target = character
          if character
            @target_circle.x = character.x - 2
            @target_circle.y = character.y - 2
            @target_circle.w = character.hit_box.w + 4
            @target_circle.h = character.hit_box.h + 4
          else
            @player.state = :idle
          end
        end
      elsif @inputs.mouse.buttons.right.click
        character = Geometry.find_intersect_rect(@world_mouse, @characters)
        if character
          @player.state = :attacking
          @player.target = character
          @target_circle.x = character.x - 2
          @target_circle.y = character.y - 2
          @target_circle.w = character.hit_box.w + 4
          @target_circle.h = character.hit_box.h + 4
        end

      end

      handle_camera_zoom
    end

    def calc(args)
      calc_player
      calc_camera
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
      @player.x = @player.target_x
      @player.y = @player.target_y

      if @player.target
        @outputs.debug << @player.distance_from(@player.target).to_s
        @outputs.debug << "OUT OF RANGE: #{@player.out_of_range?(@player.target)}"
      end

      if @player.target && @player.state == :attacking
        @player.attack(@player.target)
      end
    end

    def calc_camera
      @camera.target_x = @player.target_x
      @camera.target_y = @player.target_y

      @camera.scale += (@camera.target_scale - @camera.scale)
      @camera.x += (@camera.target_x - @camera.x)
      @camera.y += (@camera.target_y - @camera.y)
    end

    def render(args)
      camera_rt = args.outputs[@camera_path]
      viewport = @camera.viewport
      camera_rt.w = viewport.w
      camera_rt.h = viewport.h
      camera_rt.background_color = [0,0,0,255]

      # args.outputs.debug << @player.to_s
      args.outputs.debug << @camera.viewport.to_s
      @player.update
      @player.active_spell&.update(player: @player, outputs: @outputs)

      screen_renderables = []
          .concat(@characters.map(&:prefab))
          .concat(@player.prefab)
          .flatten
          .map { |spr| @camera.to_screen_space!(spr.dup) }

      if @player.target
        screen_renderables.unshift(@camera.to_screen_space!(@target_circle.dup))
      end

      if @player.active_spell
        if @player.active_spell.indicator.is_a?(Array)
          screen_renderables.unshift(*@player.active_spell.indicator.map { |spr| @camera.to_screen_space!(spr.dup) })
        else
          screen_renderables.unshift(@camera.to_screen_space!(@player.active_spell.indicator.dup))
        end
      end

      args.outputs[@camera.path].primitives.concat(screen_renderables)

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
    end
  end
end
