module App
  class Engine
    attr_accessor :player, :camera

    def initialize(player:)
      @player = player
    end
  end
end
