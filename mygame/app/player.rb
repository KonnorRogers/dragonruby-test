module App
  class Player
    attr_sprite
    attr_accessor :target_x, :target_y

    include AnimationMixin
    include ReactiveMixin

    reactive :state, :speed, :direction

    def initialize(...)
      super(...)

      on_change { update_sprite }

      @state = :idle
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
      }
      @direction = :right
      @w = 32
      @h = 32
      @primitive_marker = :sprite
      @speed = 100
    end

    def update_sprite
      super()
      @flip_horizontally = @direction == :right
    end
  end
end
