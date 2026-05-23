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
        scale: 1,
        source_x: 16,
        source_y: 960,
        source_h: 16,
        source_w: 16,
        path: SPRITESHEET_PATH
      },
      rock: {
        scale: 1,
        source_x: 496,
        source_y: 944,
        source_h: 16,
        source_w: 16,
        path: SPRITESHEET_PATH
      },
      silver: {
        scale: 4,
        source_x: 784,
        source_y: 656,
        source_h: 32,
        source_w: 32,
        path: SPRITESHEET_PATH,
        collision: {
          x: 4,
          y: 6,
          h: -10,
          w: -8
        }
      },
      tree: {
        scale: 4,
        source_x: 0,
        source_y: 0,
        source_h: 34,
        source_w: 34,
        path: "sprites/sunny_world/elements/plants/spr_deco_tree_01_strip4.png",
        collision: {
          x: 10,
          y: 6,
          h: -28,
          w: -22
        }
      },
      berry_bush: {
        scale: 4,
        source_x: 784,
        source_y: 944,
        source_h: 32,
        source_w: 32,
        path: "sprites/sunny_world/tileset/spr_tileset_sunnysideworld_16px.png"
      },
      twig: {
        scale: 2,
        source_x: 0,
        source_y: 0,
        source_h: 16,
        source_w: 16,
        path: "sprites/sunny_world/tileset/twig-tree.png"
      },
      bear: {
        scale: 2,
        source_x: 0,
        source_y: 480,
        source_h: 32,
        source_w: 32,
        path: "sprites/32rogues/animals.png"
      }
    }

    SPRITES.each_value do |spr|
      spr.w = spr.source_w * spr.scale
      spr.h = spr.source_h * spr.scale
      if spr.collision
        spr.collision.x *= spr.scale
        spr.collision.w *= spr.scale
        spr.collision.y *= spr.scale
        spr.collision.h *= spr.scale
      end
    end

    OBJECTS = [
      # { type: nil,   weight: 90 },
      { name: :rock, weight: 0.1, **SPRITES.rock },
      { name: :silver, weight: 0.05, **SPRITES.silver },
      { name: :tree, weight: 0.05, **SPRITES.tree },
      { name: :berry_bush, weight: 0.05, **SPRITES.berry_bush },
      { name: :twig, weight: 0.1, **SPRITES.twig  },
      { name: :bear, weight: 0.1, **SPRITES.bear }
    ]

    SCATTER_TOTAL = OBJECTS.sum(&:weight)
    EMPTY_WEIGHT  = 100 - SCATTER_TOTAL # 92% chance of nothing

    SCATTER_TABLE_SIZE = 10_000

    def build_scatter_table
      SCATTER_TABLE_SIZE.times.map do
        roll = @random.rand * 100
        if roll < EMPTY_WEIGHT
          nil
        else
          roll -= EMPTY_WEIGHT
          result = nil
          OBJECTS.each do |e|
            if roll < e.weight
              result = e.name
              break
            end
            roll -= e.weight
          end
          result
        end
      end
    end

    def roll_scatter
      @scatter_table[@random.rand(SCATTER_TABLE_SIZE)]
    end

    def object_overlaps?(obj)
      steps_x = [obj.w.idiv(@tile_size), 1].max
      steps_y = [obj.h.idiv(@tile_size), 1].max
      steps_x.times.any? do |dx|
        steps_y.times.any? do |dy|
          @occupied[chunk_key(obj.x + dx * @tile_size, obj.y + dy * @tile_size)]
        end
      end
    end

    # How many tiles per chunk side (16 tiles × 16px = 256px chunks)
    CHUNK_TILES = 16

    attr_accessor :tiles, :tile_size, :outputs, :w, :h

    def initialize(
      w: 16 * 1000,
      h: 16 * 1000,
      save_directory: "data/saves/chunks",
      tile_size: 16,
      seed: rand(1_000_000_000)
    )
      @w = w
      @h = h
      @save_directory = save_directory
      @tile_size = tile_size
      @chunk_px = CHUNK_TILES * tile_size
      @rows = w.idiv(tile_size)
      @columns = h.idiv(tile_size)
      @tiles = {}
      @objects = {}
      @render_targets = {}
      @outputs = nil
      @largest_obj = OBJECTS.map do |o|
        [o.w || tile_size, o.h || tile_size].max
      end.max
      @occupied = {}
      @dirty_chunks = {}

      # Used for generating the map, max number of milliseconds a method can take when generating
      @max_elapsed_ms = 6

      # existing = $gtk.read_file("#{@save_directory}/complete.dat")

      # if existing
      #   saved = $gtk.deserialize_state("#{@save_directory}/complete.dat")
      #   @seed = saved[:seed]
      #   # World already exists on disk — chunks loaded on demand
      #   @generating = false
      #   @generating_fiber = nil
      # else
        @seed = seed
        @random = Random.new(@seed)
        clear_chunk_saves
        @generating_fiber = Fiber.new { fiber_generate }
        @generating = true
      # end

      @scatter_table = build_scatter_table
    end

    def mark_dirty(cx, cy)
      @dirty_chunks[chunk_key(cx, cy)] = true
    end

    def rebake_chunk(cx, cy)
      key = chunk_key(cx, cy)
      origin_x = cx * @chunk_px
      origin_y = cy * @chunk_px

      tile_keys = []
      CHUNK_TILES.times do |dx|
        CHUNK_TILES.times do |dy|
          k = chunk_key(origin_x + dx * @tile_size, origin_y + dy * @tile_size)
          tile_keys << k if @tiles[k]
        end
      end

      bake_chunk(key, tile_keys)
    end

    def generating?
      @generating
    end

    def tick_generate
      return if !generating?

      if @generating_fiber&.alive?
        @generating_fiber.resume
      else
        @generating = false
      end
    end

    def fiber_generate
      generation_start = current_time_ms
      i = 0

      @rows.times do |x|
        @columns.times do |y|
          generate_tile(x, y)

          i += 1
          if i >= 500          # check time every 500 tiles instead of every tile
            i = 0
            if current_time_ms - generation_start >= @max_elapsed_ms
              Fiber.yield
              generation_start = current_time_ms
            end
          end
        end
      end

      bake_chunks
      @generating = false
      # $gtk.serialize_state("#{@save_directory}/complete.dat", { complete: true, seed: @seed })
    end

    def generate_chunk(cx, cy)
      origin_x = cx * @chunk_px
      origin_y = cy * @chunk_px
      CHUNK_TILES.times do |dx|
        CHUNK_TILES.times do |dy|
          generate_tile(
            (origin_x + dx * @tile_size).idiv(@tile_size),
            (origin_y + dy * @tile_size).idiv(@tile_size)
          )
        end
      end
    end

    def generate_tile(x, y)
      tile_x = x * @tile_size
      tile_y = y * @tile_size
      k = chunk_key(tile_x, tile_y)

      @tiles[k] = :grass

      sym = roll_scatter
      if sym
        # overlap check needs w/h from legend
        obj_sprite = SPRITES[sym]
        obj = { x: tile_x, y: tile_y, w: obj_sprite.w || @tile_size, h: obj_sprite.h || @tile_size }
        if !object_overlaps?(obj)
          @objects[k] = sym
          add_object(obj)
        end
      end
    end


    def add_object(obj)
      steps_x = [obj.w.idiv(@tile_size), 1].max
      steps_y = [obj.h.idiv(@tile_size), 1].max
      steps_x.times do |dx|
        steps_y.times do |dy|
          @occupied[chunk_key(obj.x + (dx * @tile_size), obj.y + (dy * @tile_size))] = true
        end
      end
    end

    def remove_object(obj)
      steps_x = [obj.w.idiv(@tile_size), 1].max
      steps_y = [obj.h.idiv(@tile_size), 1].max
      steps_x.times do |dx|
        steps_y.times do |dy|
          @occupied.delete(chunk_key(obj.x + (dx * @tile_size), obj.y + (dy * @tile_size)))
        end
      end
    end

    def current_time_ms
      (Time.now.to_f * 1000).to_i
    end

    def bake_chunks
      generation_start = current_time_ms
      i = 0

      by_chunk = Hash.new { |h, k| h[k] = [] }
      @tiles.each_key do |tile_key|
        px = chunk_key_to_cx(tile_key)
        py = chunk_key_to_cy(tile_key)
        cx = px.idiv(@chunk_px)
        cy = py.idiv(@chunk_px)
        by_chunk[chunk_key(cx, cy)] << tile_key

        i += 1
        if i >= 500
          i = 0
          if current_time_ms - generation_start >= @max_elapsed_ms
            Fiber.yield
            generation_start = current_time_ms
          end
        end
      end

      by_chunk.each do |key, tile_keys|
        bake_chunk(key, tile_keys)
        cx = chunk_key_to_cx(key)
        cy = chunk_key_to_cy(key)
        save_chunk(cx, cy)
        if current_time_ms - generation_start >= @max_elapsed_ms
          Fiber.yield
          generation_start = current_time_ms
        end
      end
    end

    def bake_chunk(key, chunk_tiles)
      cx = chunk_key_to_cx(key)
      cy = chunk_key_to_cy(key)
      origin_x = cx * @chunk_px
      origin_y = cy * @chunk_px

      key = "map_chunk_#{cx}_#{cy}"
      rt = @outputs[key]
      @render_targets[key] = rt
      rt.w = @chunk_px
      rt.h = @chunk_px
      chunked_tiles = []
      Array.each(chunk_tiles) do |tile_key|
        # chunked_tiles << t.merge(x: t.x - origin_x, y: t.y - origin_y)
        sym = @tiles[tile_key]
        sprite = SPRITES[sym]
        x = chunk_key_to_cx(tile_key)  # pixel x
        y = chunk_key_to_cy(tile_key)  # pixel y

        chunked_tiles << SPRITES[sym].merge(
          x: x - origin_x,
          y: y - origin_y,
          w: sprite.w,
          h: sprite.h,
        )
      end

      if chunked_tiles.length > 0
        rt.sprites.concat(chunked_tiles)
      end
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
      hash = {
        x: nil,
        y: nil,
        w: @chunk_px,
        h: @chunk_px,
        path: nil
      }

      while cx <= max_cx
        cy = min_cy
        while cy <= max_cy
          key = "map_chunk_#{cx}_#{cy}"
          if @render_targets[key]
            h = hash.dup
            h.x = cx * @chunk_px
            h.y = cy * @chunk_px
            h.path = key
            result << h
          end
          cy += 1
        end
        cx += 1
      end
      result
    end

    def __in_viewport__(camera, hash:, largest_tile:)
      world = camera.to_world_space!(camera.viewport.dup)

      min_x = ((world.x - largest_tile) / @tile_size).floor * @tile_size
      min_y = ((world.y - largest_tile) / @tile_size).floor * @tile_size
      max_x = world.x + world.w + largest_tile
      max_y = world.y + world.h + largest_tile

      result = []
      x = min_x
      while x <= max_x
        y = min_y
        while y <= max_y
          sym = hash[chunk_key(x, y)]
          if sym
            sprite = SPRITES[sym]
            result << sprite.merge(x: x, y: y)
          end
          y += @tile_size
        end
        x += @tile_size
      end
      result
    end

    def objects_in_viewport(camera)
      __in_viewport__(camera, hash: @objects, largest_tile: @largest_obj)
    end

    def tiles_in_viewport(camera)
      __in_viewport__(camera, hash: @tiles, largest_tile: @tile_size)
    end

    def chunk_file(cx, cy)
      "#{@save_directory}/chunk_#{cx}_#{cy}.dat"
    end

    def save_chunk(cx, cy)
      # tiles = {}
      # @tiles.each do |k, sym|
      #   px = chunk_key_to_cx(k)
      #   py = chunk_key_to_cy(k)
      #   tiles[k] = sym if px.idiv(@chunk_px) == cx && py.idiv(@chunk_px) == cy
      # end

      # objects = {}
      # @objects.each do |k, sym|
      #   px = chunk_key_to_cx(k)
      #   py = chunk_key_to_cy(k)
      #   objects[k] = sym if px.idiv(@chunk_px) == cx && py.idiv(@chunk_px) == cy
      # end

      # $gtk.serialize_state(chunk_file(cx, cy), { tiles: tiles, objects: objects })
    end

    def load_chunk(cx, cy)
      path = chunk_file(cx, cy)
      # raw  = $gtk.read_file(path)
      raw = nil

      if raw
        data = $gtk.deserialize_state(path)
        @tiles.merge!(data[:tiles])
        @objects.merge!(data[:objects])

        # Reconstruct occupied set so collision stays valid
        data[:objects].each do |k, sym|
          x = chunk_key_to_cx(k)
          y = chunk_key_to_cy(k)
          sprite = SPRITES[sym]
          add_object({ x: x, y: y, w: sprite.w, h: sprite.h })
        end
      else
        generate_chunk(cx, cy)  # see below
      end

      # Re-bake: collect this chunk's tile keys then render
      origin_x = cx * @chunk_px
      origin_y = cy * @chunk_px
      tile_keys = []
      CHUNK_TILES.times do |dx|
        CHUNK_TILES.times do |dy|
          k = chunk_key(origin_x + dx * @tile_size, origin_y + dy * @tile_size)
          tile_keys << k if @tiles[k]
        end
      end

      bake_chunk(chunk_key(cx, cy), tile_keys)
    end

    def unload_chunk(cx, cy)
      key = chunk_key(cx, cy)
      save_chunk(cx, cy) if @dirty_chunks.delete(key)

      # Evict tiles + objects from memory
      origin_x = cx * @chunk_px
      origin_y = cy * @chunk_px
      CHUNK_TILES.times do |dx|
        CHUNK_TILES.times do |dy|
          k = chunk_key(origin_x + dx * @tile_size, origin_y + dy * @tile_size)
          @tiles.delete(k)
          @objects.delete(k)
          @occupied.delete(k)
        end
      end

      # Drop the render texture
      @render_targets.delete("map_chunk_#{cx}_#{cy}")
    end

    def remove_object_at(tile_x, tile_y)
      k = chunk_key(tile_x, tile_y)
      sym = @objects.delete(k)
      return unless sym

      sprite = SPRITES[sym]
      remove_object({ x: tile_x, y: tile_y, w: sprite.w, h: sprite.h })

      cx = tile_x.idiv(@chunk_px)
      cy = tile_y.idiv(@chunk_px)
      mark_dirty(cx, cy)
      rebake_chunk(cx, cy)  # refresh the render target
    end

    def save_dirty_chunks
      @dirty_chunks.each_key do |key|
        cx = chunk_key_to_cx(key)
        cy = chunk_key_to_cy(key)
        save_chunk(cx, cy)
      end
      @dirty_chunks.clear
    end

    def clear_chunk_saves
      files = $gtk.list_files(@save_directory)
      return unless files
      files.each do |filename|
        $gtk.delete_file("#{@save_directory}/#{filename}")
      end
    end
  end
end
