module App
  class Enemy < Character
    attr_accessor :speed, :animations, :hit_box, :state

    reactive :state, :speed, :direction, :max_hp, :current_hp

    def initialize(**kwargs)
      super(**kwargs)

      @state = :idle
      update
    end
  end
end

