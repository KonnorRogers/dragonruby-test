module App
  module UI
    class AttackCircle < SpriteKit::Sprite
      def to_a
        @primitives
      end

      def initialize(**kwargs)
        super(**kwargs)
        @circle = App::UI::Circle.new(
          type: :large_blue,
          x: @x,
          y: @y,
          w: @w,
          h: @h
        )
        @attack_sprite = {
          source_x: 144,
          source_y: 176,
          source_h: 16,
          source_w: 16,
          path: SPRITESHEET_PATH,
          x: @x + (@w / 2) - @w / 8,
          y: @y + (@y / 2) - @w / 8,
          w: @w / 4,
          h: @w / 4
        }
        @primitives = [
          @circle,
          @attack_sprite
        ]
      end
    end
  end
end
