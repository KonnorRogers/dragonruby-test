module App
  module UI
    class HealthBar < SpriteKit::Sprite
      include AnimationMixin
      include ReactiveMixin

      reactive :state

      SPRITES = {
        outline: {
          source_x: 0,
          source_y: 256,
          source_h: 16,
          source_w: 32,
          path: SPRITESHEET_PATH
        },
        friendly: {
          source_x: 32,
          source_y: 256,
          source_h: 16,
          source_w: 32,
          path: SPRITESHEET_PATH
        },
        enemy: {
          source_x: 64,
          source_y: 256,
          source_h: 16,
          source_w: 32,
          path: SPRITESHEET_PATH
        },
        neutral: {
          source_x: 96,
          source_y: 256,
          source_h: 16,
          source_w: 32,
          path: SPRITESHEET_PATH
        }
      }

      def initialize(state:, **kwargs)
        super(**kwargs)
        on_change { update_sprite }
        @state = state
      end
    end
  end
end
