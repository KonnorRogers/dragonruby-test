module App
  class Map
    # Pack individual tile coords into a hash key
    def chunk_key(cx, cy)
      (cy << 16) | (cx & 0xFFFF)
    end

    def chunk_key_to_cx(key)  (key & 0xFFFF).then { |v| v > 32767 ? v - 65536 : v }  end
    def chunk_key_to_cy(key)  key >> 16  end

    SPRITESHEET_PATH = "sprites/sunny_world/tileset/spr_tileset_sunnysideworld_16px.png"
    SPRITES = {
      grass: {
        source_x: 16,
        source_y: 960,
        source_h: 16,
        source_w: 16,
        path: SPRITESHEET_PATH
      },
      rock: {
        source_x: 496,
        source_y: 944,
        source_h: 16,
        source_w: 16,
        path: SPRITESHEET_PATH
      },
      silver: {
        w: 32,
        h: 32,
        source_x: 784,
        source_y: 656,
        source_h: 32,
        source_w: 32,
        path: SPRITESHEET_PATH
      }
    }

    OBJECTS = [
      # { type: nil,   weight: 90 },
      { type: :rock, weight: 0.1, **SPRITES.rock  },
      { type: :silver, weight: 0.05, **SPRITES.silver },
      # { type: :twig, weight: 3  },
    ]

    SCATTER_TOTAL = SCATTER.sum(&:weight)
    EMPTY_WEIGHT  = 100 - SCATTER_TOTAL # 92% chance of nothing

    def roll_scatter
      roll = rand * 100

      return nil if roll < EMPTY_WEIGHT

      roll -= EMPTY_WEIGHT
      SCATTER.each do |e|
        return e.type if roll < e.weight

        roll -= e.weight
      end

      nil
    end

    # How many tiles per chunk side (16 tiles × 16px = 256px chunks)
    CHUNK_TILES = 16

    attr_accessor :tiles, :tile_size

    def initialize(
      w: 16 * 400,
      h: 16 * 400,
      tile_size: 16
    )
      @tile_size = tile_size
      @chunk_px = CHUNK_TILES * tile_size
      rows = w.idiv(tile_size)
      columns = h.idiv(tile_size)

      @tiles = {}
      @objects = {}


      rows.times do |x|
        columns.times do |y|
          hash = {
            x: x * tile_size,
            y: y * tile_size,
            w: tile_size,
            h: tile_size,
          }
          tile = SPRITES.grass.merge(hash)

          sym = roll_scatter

          if sym
            object = SPRITES[sym].merge(hash)
            @objects[chunk_key(tile.x, tile.y)] = object
          end
          @tiles[chunk_key(tile.x, tile.y)] = tile
        end
      end

      @chunks_baked = false
    end

    # Call once from the render loop (needs args to write render textures).
    # Safe to call every frame — bakes only on the first call.
    def bake_chunks(args)
      return if @chunks_baked

      # Group tiles by chunk coordinate
      by_chunk = Hash.new { |h, k| h[k] = [] }
      @tiles.each_value do |tile|
        cx = tile.x.idiv(@chunk_px)
        cy = tile.y.idiv(@chunk_px)
        by_chunk[chunk_key(cx, cy)] << tile
      end

      by_chunk.each do |key, chunk_tiles|
        cx = chunk_key_to_cx(key)
        cy = chunk_key_to_cy(key)
        origin_x = cx * @chunk_px
        origin_y = cy * @chunk_px

        rt = args.outputs["map_chunk_#{cx}_#{cy}"]
        rt.w = @chunk_px
        rt.h = @chunk_px
        rt.sprites << chunk_tiles.map do |t|
          t.merge(x: t.x - origin_x, y: t.y - origin_y)
        end
      end

      @chunks_baked = true
    end

    # Returns one sprite per visible chunk instead of one per tile.
    # ~44x fewer draw calls at zoom-out compared to tiles_in_viewport.
    def chunks_in_viewport(camera)
      world = camera.to_world_space!(camera.viewport.dup)

      min_cx = (world.x / @chunk_px).floor
      min_cy = (world.y / @chunk_px).floor
      max_cx = ((world.x + world.w) / @chunk_px).ceil
      max_cy = ((world.y + world.h) / @chunk_px).ceil

      result = []
      cx = min_cx
      while cx <= max_cx
        cy = min_cy
        while cy <= max_cy
          result << {
            x: cx * @chunk_px,
            y: cy * @chunk_px,
            w: @chunk_px,
            h: @chunk_px,
            path: "map_chunk_#{cx}_#{cy}"
          }
          cy += 1
        end
        cx += 1
      end
      result
    end

    def __in_viewport__(camera, hash:)
      world = camera.to_world_space!(camera.viewport.dup)

      min_x = (world.x / @tile_size).floor * @tile_size
      min_y = (world.y / @tile_size).floor * @tile_size
      max_x = min_x + world.w.ceil + @tile_size
      max_y = min_y + world.h.ceil + @tile_size

      result = []
      x = min_x
      while x <= max_x
        y = min_y
        while y <= max_y
          tile = hash[chunk_key(x, y)]
          result << tile if tile
          y += @tile_size
        end
        x += @tile_size
      end
      result
    end

    def objects_in_viewport(camera)
      __in_viewport__(camera, hash: @objects)
    end

    def tiles_in_viewport(camera)
      __in_viewport__(camera, hash: @tiles)
    end
  end
end
