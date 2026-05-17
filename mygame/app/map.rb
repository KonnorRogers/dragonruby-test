module App
  class Map
    # Pack
    def chunk_key(cx, cy)
      (cy << 16) | (cx & 0xFFFF)
    end

    # Unpack (if you ever need to go back)
    def chunk_key_to_cx(key)  (key & 0xFFFF).then { |v| v > 32767 ? v - 65536 : v }  end
    def chunk_key_to_cy(key)  key >> 16  end

    SPRITESHEET_PATH = "sprites/sunny_world/tileset/spr_tileset_sunnysideworld_16px.png"
    TILES = {
      grass: {
        source_x: 16,
        source_y: 960,
        source_h: 16,
        source_w: 16,
        path: SPRITESHEET_PATH
      }
    }

    attr_accessor :tiles

    def initialize(
      w: 16 * 400,
      h: 16 * 400,
      tile_size: 16
    )
      rows = w.idiv(tile_size)
      columns = h.idiv(tile_size)

      @tiles = []

      rows.times do |x|
        columns.times do |y|
          @tiles << TILES.grass.merge({
            x: x * tile_size,
            y: y * tile_size,
            w: tile_size,
            h: tile_size,
          })
        end
      end
    end
  end
end
