module App
  module AnimationMixin
    def self.included(base)
      base.prepend(PrependedMethods)
    end

    module PrependedMethods
      def initialize(...)
        super(...)
        @state ||= :idle
        @animations ||= {}
        @animation_start ||= 0
        update_sprite
      end
    end

    attr_accessor :state, :animations, :animation_start

    def update_sprite(sprite = @animations[@state])
      @sprite = sprite
      if @sprite
        @source_x = sprite.source_x
        @source_y = sprite.source_y
        @source_w = sprite.source_w
        @source_h = sprite.source_h
        @path = sprite.path
      end
    end

    def current_frame
      # get the frame data for the current action the player is in
      action = @animations[@state]

      return if !action

      # Numeric.frame returns the following hash
      # For example, this would be the frame data for performing an attack
      # {
      #   frame_index: 3,
      #   frame_count: 5,
      #   frames_left: 2,
      #   started: true,
      #   completed: false,
      #   duration: 15,
      #   elapsed_time: 10,
      #   frame_elapsed_time: 1
      # }
      Numeric.frame(start_at: @animation_start,
                    frame_count: action.frame_count,
                    hold_for: action.hold_for,
                    repeat: action.repeat)
    end
  end
end
