module App
  class Player < Character
    attr_accessor :targeting_angle, :active_spell, :spells

    def initialize(**kwargs)
      super(**kwargs)

      @animations = {
        idle: {
          source_x: 39,
          source_y: 24,
          source_h: 16,
          source_w: 18,
          path: "sprites/sunny_world/characters/goblin/png/spr_walk_strip8.png",
          hold_for: 1,
          repeat: true
        },
        walking: {
          repeat: true,
          frames: [
            {
              source_x: 39,
              source_y: 24,
              source_h: 16,
              source_w: 18,
              path: "sprites/sunny_world/characters/goblin/png/spr_walk_strip8.png",
              hold_for: 8
            },
            {
              source_x: 135,
              source_y: 24,
              source_h: 16,
              source_w: 18,
              path: "sprites/sunny_world/characters/goblin/png/spr_walk_strip8.png",
              hold_for: 8
            },
            {
              source_x: 232,
              source_y: 24,
              source_h: 16,
              source_w: 16,
              path: "sprites/sunny_world/characters/goblin/png/spr_walk_strip8.png",
              hold_for: 8,
            },
            {
              source_x: 329,
              source_y: 25,
              source_h: 16,
              source_w: 15,
              path: "sprites/sunny_world/characters/goblin/png/spr_walk_strip8.png",
              hold_for: 8,
            },
            {
              source_x: 424,
              source_y: 25,
              source_h: 16,
              source_w: 17,
              path: "sprites/sunny_world/characters/goblin/png/spr_walk_strip8.png",
              hold_for: 8
            }
          ]
        },
        attacking: {
          source_x: 39,
          source_y: 24,
          source_h: 16,
          source_w: 18,
          path: "sprites/sunny_world/characters/goblin/png/spr_walk_strip8.png",
          hold_for: 1,
          frame_count: 1,
          repeat: true,
        },
      }
      @direction = :right
      @w ||= 32
      @h ||= 32
      @primitive_marker = :sprite
      @speed = 100
      @target = nil
      @targeting_angle = 0
      @angle = 0
      @stats = {}
      @equipment = {}
      @active_spell = nil
      @spells = {
        one: Spell.new(SpellDefinition.new(**App::SPELLS[:water_wave])),
        two: nil,
        three: nil,
        four: nil,
        five: nil
      }
    end

    def hit_box
      {
        w: @w,
        h: (@h / 3) * 2
      }
    end

    def serialize
      hash = super
      hash.delete(:spells)
      hash
    end

    def state=(val)
      # if state changes, update animation start time.
      return if val == @state

      @state = val
      @animation_start = @engine.tick_count
      update_sprite
    end

    def collision
      {
        x: @x + 4,
        y: @y + 4,
        w: @w - 8,
        h: @h - 8,
      }
    end

    def update_sprite
      super()

      if @direction == :left || @direction == :right
        @flip_horizontally = @direction == :left
      end

      if @animation_prefab
        @animation_prefab.each { |spr| spr.flip_horizontally = @flip_horizontally }
      end
    end
  end
end
