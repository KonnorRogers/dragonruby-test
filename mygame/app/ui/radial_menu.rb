module App
  module UI
    class RadialMenu < SpriteKit::Sprite
      attr_accessor :anchor, :buttons, :radius

      BUTTON_CIRCLE = {
        source_x: 128,
        source_y: 112,
        source_h: 48,
        source_w: 48,
        path: "sprites/32rogues/ui-sheet.png"
      }

      def initialize(anchor:, radius: nil, number_of_buttons:, **kwargs)
        super(**kwargs)

        @radius = radius || (anchor.w * 2)

        cx = anchor.x + anchor.w
        cy = anchor.y - (anchor.h / 4)
        # Quarter circle: top-left arc = 180° to 270° (in standard math coords)
        # DragonRuby uses bottom-left origin, Y goes up, angles in degrees
        # Arc from 180° to 270° sweeps counter-clockwise from left to down
        start_angle = 180
        end_angle   = 90
        num_buttons = 5
        button_size = 48

        @buttons = [
        ]

        # Distribute buttons evenly across the arc
        num_buttons = number_of_buttons
        num_buttons.times do |i|
          # Interpolate angle from start to end
          # Using i / (num_buttons - 1) gives first and last exactly on the edges
          # Using (i + 0.5) / num_buttons centers them within equal slices
          t = (i + 0.5) / num_buttons.to_f
          angle_deg = start_angle + t * (end_angle - start_angle)
          angle_rad = angle_deg * Math::PI / 180

          bx = cx + Math.cos(angle_rad) * @radius - button_size / 2
          by = cy + Math.sin(angle_rad) * @radius - button_size / 2

          @buttons << {
            x: bx, y: by,
            w: button_size, h: button_size,
            **BUTTON_CIRCLE,
            primitive_marker: :sprite,
          }
          @buttons << {
            x: bx + button_size / 4, y: by - 10,
            w: 20,
            h: 20,
            r: 255,
            g: 0,
            b: 0,
            a: 255,
            primitive_marker: :sprite,
            path: :solid
          }

          @buttons << {
            x: bx + button_size / 4 + 6, y: by - 10,
            size_px: 16,
            text: "#{i + 1}",
            # anchor_x: 0.5,
            anchor_y: 0,
            primitive_marker: :label,
          }
        end
      end
    end
  end
end
