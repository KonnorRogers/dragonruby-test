module App
  class Enemy
    attr_sprite
    attr_accessor :hp, :speed, :animations, :state, :behavior

    def initialize(data)
      @hp         = data[:hp]
      @speed      = data[:speed]
      @animations = data[:animations]  # loaded from data
      @state      = :idle
      @behavior   = data[:behavior]    # a behavior object/proc
    end

    # def tick
    #   @behavior.call(self) # data drives *which* behavior runs
    #   animate(@state)
    # end

    # def animate(state)
    #   # @current_frame = @animations[state]
    # end
  end
end

