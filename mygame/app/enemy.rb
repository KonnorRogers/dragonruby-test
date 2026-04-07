module App
  class Enemy
    attr_sprite

    include AnimationMixin

    attr_accessor :hp, :speed, :actions

    def initialize(data)
      @hp            = data[:hp]
      @speed         = data[:speed]
      @animations    = data[:animations] # loaded from data
      @state         = :idle
      # @behavior   = data[:behavior]    # a behavior object/proc
    end

    # Shortcut in DR to always render.
    def to_a
      self
    end
  end
end

