module App
  module UI
    module Indicators
      module ArcIndicator
        def self.render(outputs:, length:, spread:, anchor:, path:, angle: nil)
          angle ||= anchor.angle

          # add a small amount of padding for the render target, and then multiply by 2 so it can render in any direction.
          w = (length + 4) * 2
          h = (length + 4) * 2

          # if anchor.direction == :right
          #   angle = 0
          # elsif anchor.direction == :left
          #   angle = 180
          # elsif anchor.direction == :up
          #   angle = 90
          # elsif anchor.direction == :down
          #   angle = 270
          # end

          hash = center_offset_from_angle({w: w / 2, h: h / 2}, anchor, angle, length)

          cone = build_cone_indicator(0, h / 2, length, spread, 0)

          rt = outputs[path]

          rt.w = w
          rt.h = h
          rt.background_color = [
            0,
            0,
            0,
            0,
            # 255
          ]
          rt.transient!

          rt.primitives.concat(
            cone[:border_triangles]
              .concat(
                cone[:fill_triangles].map { |t| t.merge(blendmode_enum: 0, a: 0) }
              ).concat(
                cone[:fill_triangles]
              )
          )

          [
            {
              x: hash.x,
              y: hash.y,
              w: w / 2,
              h: h / 2,
              # anchor_x: 1,
              # anchor_y: 0.5,
              a: 128,
              angle: angle,
              blendmode_enum: 0,
              path: path,
            }
          ]
        end

        def self.center_offset_from_angle(sprite, anchor, angle_degrees, distance)
          rad = angle_degrees * Math::PI / 180
          cx = anchor.x + (anchor&.hit_box || anchor).w / 2
          cy = anchor.y + (anchor&.hit_box || anchor).h / 2
          x = cx + Math.cos(rad) * (distance / 2) - sprite.w / 2
          y = cy + Math.sin(rad) * (distance / 2) - sprite.h / 2
          {x: x, y: y}
        end

        def self.calc_cone_indicator(x, y, length, apex_angle_degrees, rotation_degrees, steps: 20)
          half = apex_angle_degrees / 2.0
          step_size = apex_angle_degrees.to_f / steps

          triangles = steps.times.map do |i|
            left_angle  = rotation_degrees - half + (i * step_size)
            right_angle = left_angle + step_size
            calc_isosceles_triangle(x, y, length, step_size, (left_angle + right_angle) / 2.0)
          end


          triangles
        end

        def self.build_cone_indicator(x, y, length, apex_angle_degrees, rotation_degrees)
          border_thickness = 8
          side_border = 0  # extra degrees on each side

          # Full border: wider angle AND longer length
          border_triangles = calc_cone_indicator(
            x, y,
            length + border_thickness,
            apex_angle_degrees + (side_border * 2),
            rotation_degrees,
            steps: 20
          )

          fill_triangles = calc_cone_indicator(x, y, length, apex_angle_degrees, rotation_degrees, steps: 20)

          border_triangles.each { |spr| spr.merge!({ r: 0, b: 255, g: 200, a: 255 }) }
          fill_triangles.each { |spr| spr.merge!({ r: 80, b: 250, g: 80, a: 255 }) }

          {
            border_triangles: border_triangles,
            fill_triangles: fill_triangles
          }
        end

        # Example:
        # "tip" is at 360, 400, and then specify how long the 2 sides are, and the angle.
        #  isosceles_triangle(360, 400,
        def self.calc_isosceles_triangle(x, y, leg_length, apex_angle_degrees, rotation_degrees = 90)
          # apex_angle_degrees: the angle at the tip between the two equal legs
          # rotation_degrees: direction the triangle "points" (90 = pointing down)

          half_angle = apex_angle_degrees / 2.0 * Math::PI / 180.0
          base_dir   = rotation_degrees * Math::PI / 180.0

          # Left and right base corners
          angle_left  = base_dir - half_angle
          angle_right = base_dir + half_angle

          {
            x:  x,
            y:  y,
            x2: x + Math.cos(angle_left)  * leg_length,
            y2: y + Math.sin(angle_left)  * leg_length,
            x3: x + Math.cos(angle_right) * leg_length,
            y3: y + Math.sin(angle_right) * leg_length
          }
        end
      end
    end
  end
end

