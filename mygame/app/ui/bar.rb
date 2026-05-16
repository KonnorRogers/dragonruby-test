module App
  module UI
    class Bar < SpriteKit::Sprite
      include AnimationMixin

      SPRITES = {
        outline: {
          source_x: 0,
          source_y: 256 + 32,
          source_h: 16,
          source_w: 32,
          path: SPRITESHEET_PATH,
          nine_slice: {
            top_left: {
              source_x: 0,
              source_y: 265,
              source_h: 3,
              source_w: 3,
            },
            top_center: {
              source_x: 3,
              source_y: 265,
              source_h: 3,
              source_w: 26,
            },
            top_right: {
              source_x: 29,
              source_y: 265,
              source_h: 3,
              source_w: 3,
            },
            center_left: {
              source_x: 0,
              source_y: 263,
              source_h: 2,
              source_w: 3,
            },
            center: {
              source_x: 3,
              source_y: 263,
              source_h: 2,
              source_w: 26,
            },
            center_right: {
              source_x: 29,
              source_y: 263,
              source_h: 2,
              source_w: 3,
            },
            bottom_left: {
              source_x: 0,
              source_y: 260,
              source_h: 3,
              source_w: 3,
            },
            bottom_center: {
              source_x: 2,
              source_y: 260,
              source_h: 3,
              source_w: 28,
            },
            bottom_right: {
              source_x: 29,
              source_y: 260,
              source_h: 3,
              source_w: 3,
            }
          }
        },
        friendly: {
          source_x: 32,
          source_y: 256 + 32,
          source_h: 16,
          source_w: 32,
          path: SPRITESHEET_PATH
        },
        enemy: {
          source_x: 64,
          source_y: 256 + 32,
          source_h: 16,
          source_w: 32,
          path: SPRITESHEET_PATH
        },
        neutral: {
          source_x: 96,
          source_y: 256 + 32,
          source_h: 16,
          source_w: 32,
          path: SPRITESHEET_PATH
        }
      }

      def initialize(type:, **kwargs)
        super(**kwargs)
        @type = type
        update

        # @corners = {
        #   top_left: {},
        #   top_right: {},
        #   bottom_left: {},
        #   bottom_right: {},
        # }
        # @edges = {
        #   top: {},
        #   bottom: {}
        # }
        # @center = {}
      end

      # def calc_nine_slice!
      #   @edges = {
      #     top:
      #   }
      # end

      def prefab
        # if @sprite.nine_slice
        #   render_nine_slice(@sprite.nine_slice)
        # else
        self
        # end
      end

      def render_nine_slice(nine_slice)
        x = @x
        y = @y
        w = @w
        h = @h
        nine_slice = nine_slice.transform_values(&:dup)
        nine_slice.each_value { |spr| spr.path = SPRITESHEET_PATH }

        tl = nine_slice[:top_left]
        tr = nine_slice[:top_right]
        bl = nine_slice[:bottom_left]
        br = nine_slice[:bottom_right]
        tc = nine_slice[:top_center]
        bc = nine_slice[:bottom_center]
        cl = nine_slice[:center_left]
        cr = nine_slice[:center_right]
        c  = nine_slice[:center]

        inner_x = x + tl.source_w
        inner_y = y + bl.source_h
        inner_w = w - tl.source_w - tr.source_w
        inner_h = h - tl.source_h - bl.source_h

        # Corners — fixed size, anchored to each corner
        tl.merge!(x: x,                    y: y + h - tl.source_h, w: tl.source_w, h: tl.source_h)
        tr.merge!(x: x + w - tr.source_w,  y: y + h - tr.source_h, w: tr.source_w, h: tr.source_h)
        bl.merge!(x: x,                    y: y,                   w: bl.source_w, h: bl.source_h)
        br.merge!(x: x + w - br.source_w,  y: y,                   w: br.source_w, h: br.source_h)

        # Top / bottom edges — stretch horizontally
        tc.merge!(x: inner_x, y: y + h - tc.source_h, w: inner_w, h: tc.source_h)
        bc.merge!(x: inner_x, y: y,                   w: inner_w, h: bc.source_h) if bc

        # Left / right edges — stretch vertically
        cl.merge!(x: x,                   y: inner_y, w: cl.source_w, h: inner_h) if cl
        cr.merge!(x: x + w - cr.source_w, y: inner_y, w: cr.source_w, h: inner_h) if cr

        # Center — stretches both ways
        c.merge!(x: inner_x, y: inner_y, w: inner_w, h: inner_h)

        [tl, tr, bl, br, tc, bc, cl, cr, c].compact
      end

      def update
        update_sprite
      end

      def update_sprite(sprite = SPRITES[@type])
        super(sprite)
      end
    end
  end
end
