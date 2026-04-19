module App
  class Player < Character
    attr_accessor :targeting_angle, :active_spell, :spells

    def initialize(**kwargs)
      super(**kwargs)

      @animations = {
        idle: {
          source_x: 0,
          source_y: 192,
          source_h: 32,
          source_w: 32,
          path: "sprites/32rogues/rogues.png",
          hold_for: 3,
          frame_count: 1,
          repeat: true
        },
        attacking: {
          source_x: 0,
          source_y: 192,
          source_h: 32,
          source_w: 32,
          path: "sprites/32rogues/rogues.png",
          hold_for: 3,
          frame_count: 1,
          repeat: true
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
      # @active_spell = Spells::Spell.new(SPELLS[:cone_of_cold])
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

    def update_sprite
      super()
      @flip_horizontally = @direction == :right
    end
  end
end
