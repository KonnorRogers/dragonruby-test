module App
  module UI
    class Circle < SpriteKit::Sprite
      SOLID = {
        source_x: 0,
        source_y: 0,
        source_h: 512,
        source_w: 512,
        path: "sprites/circle/solid.png"
      }

      SPRITES = {
        medium_gray: {
          source_x: 0,
          source_y: 208,
          source_h: 32,
          source_w: 32,
          path: SPRITESHEET_PATH
        },
        medium_blue: {
          source_x: 80,
          source_y: 208,
          source_h: 32,
          source_w: 32,
          path: SPRITESHEET_PATH
        },
        large_blue: {
          source_x: 128,
          source_y: 112,
          source_h: 48,
          source_w: 48,
          path: SPRITESHEET_PATH
        },
        target: {
          source_x: 0,
          source_y: 64,
          source_h: 48,
          source_w: 48,
          path: SPRITESHEET_PATH
        }
      }

      include App::AnimationMixin
      include App::ReactiveMixin

      reactive :type

      def initialize(type:, **kwargs)
        super(**kwargs)
        on_change { update_sprite }
        @type = type
        update_sprite
      end

      def update_sprite(sprite = SPRITES[@type])
        super(sprite)
      end
    end
  end
end
