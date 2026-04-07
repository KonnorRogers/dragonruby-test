module App
  module Scenes
    class PlayScene
      def initialize
        @player = Player.new.tap do |player|
          player.x = Grid.w / 2
          player.y = Grid.h / 2
          player.target_y = player.y
          player.target_x = player.x
        end
        @camera = SpriteKit::Camera.new(path: :camera)
        @target = nil
        @target_circle = ::App::UI::Circle.new(type: :target)
        @characters = [
          {
              **App::ENEMIES[:hyena][:idle],
              x: 300,
              y: 300,
              w: 32,
              h: 32,
          }
        ]
        @ui = {
          attack_button: ::App::UI::AttackCircle.new(w: 96, h: 96, x: (96 * 2).from_right, y: 96).to_a
        }
      end

      def tick(args)
        @inputs = args.inputs
        @keyboard = @inputs.keyboard
        @world_mouse = @camera.to_world_space(@inputs.mouse)
        input(args)
        calc(args)
        render(args)
      end

      def input(args)
        # Every frame we expect the player to move 1.25px. In total, this is 75px per second.
        # speed = (@player.speed / 100) * (FPS / 45)
        speed = 1.25

        if @inputs.up
          @player.target_y += speed
        elsif @inputs.down
          @player.target_y -= speed
        elsif @inputs.right
          @player.target_x += speed
          @player.direction = :right
        elsif @inputs.left
          @player.target_x -= speed
          @player.direction = :left
        end

        if @inputs.mouse.click
          character = Geometry.find_intersect_rect(@world_mouse, @characters)
          if character
            @target = character
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

        args.outputs.debug << @player.to_s
        args.outputs.debug << @camera.viewport.to_s
        @player.update_sprite

        args.outputs.primitives.concat(
          [
            @camera.viewport,
            *@ui[:attack_button]
          ]
        )

        screen_renderables = [
          @camera.to_screen_space!(@player.dup),
        ].concat(@characters.map { |spr| @camera.to_screen_space!(spr.dup) })

        if @target
          screen_renderables.unshift(@camera.to_screen_space!(@target_circle.dup))
        end

        args.outputs[@camera.path].primitives.concat(screen_renderables)
      end
    end
  end
end
