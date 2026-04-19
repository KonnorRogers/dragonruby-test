module App
  module UI
    class FloatingText
      def initialize(engine:, path:)
        @path = path
        @queue = {}
        @engine = engine

        @animation_delay = 0
        @animation_duration = 60 * 5 # 5 seconds
        @y_shift = 10_000
      end

      def build_label(text, anchor:, color: {r: 255, b: 255, g: 255, a: 255}, **kwargs)
        # how much above the anchor to show text.
        x = anchor.x + (anchor.w / 2)
        size_px = kwargs[:size_px] || 32
        y = anchor.y + anchor.h # + (size_px / 2)
        key = @engine.tick_count
        label = {
          **color,
          tick_count: key,
          x: x,
          y: y,
          text: text,
          primitive_marker: :label,
          # scale_quality: 2,
          size_px: size_px,
          **kwargs,
          anchor_x: 0.5,
          path: @path,
          anchor: anchor
          # anchor_y: 0.5,
        }

        final_label = yield label if block_given?
        final_label ||= label
        final_label
      end

      def add(...)
        label = build_label(...)
        @queue[label.tick_count] ||= []
        @queue[label.tick_count] << label
        label
      end

      def update(label, camera)
        anchor = label.anchor
        size_px = 16
        if anchor && size_px
          size_px = size_px * camera.scale
          anchor = camera.to_screen_space!(anchor.dup)
          x = anchor.x + (anchor.w / 2)
          y = anchor.y + anchor.h + size_px
          label.size_px = size_px
          label.x = x
          label.y = y
        end
      end

      # We have a draw to delay until the end to render after entities so it appears above.
      def flush(camera)
        render_ary = []

        @queue.delete_if { |key, _value| @engine.tick_count > (key + @animation_duration)  }
        @queue.each do |key, value|
          ary = @queue[key]
          perc = Easing.smooth_start(start_at: key,
                                    end_at: key + @animation_duration,
                                    tick_count: @engine.tick_count
                                    )

          ary.each do |hash|
            update(hash, camera)
            y_shift = ((hash.size_px / 4) * perc * 100)
            y = hash.y + y_shift
            hash.a = hash.a - (hash.a * perc)
            hash.y = hash.y - (hash.size_px / 2) + y_shift
          end

          render_ary.concat(ary)
        end

        render_ary
      end
    end
  end
end

