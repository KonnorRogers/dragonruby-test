module App
  class Spell
    attr_accessor :spell_definition, :indicator

    def initialize(spell_definition)
      @spell_definition = spell_definition
      @indicator = nil
    end

    def update(player:, outputs:)
      if @spell_definition.target_type == :cone
        @indicator = UI::Indicators::ArcIndicator.render(outputs: outputs, length: 200, spread: 90, anchor: player, path: :indicator, angle: player.targeting_angle)
      end
    end

    def cast(player:)

    end
  end

  class SpellDefinition
    attr_accessor :rank, :name, :description, :target_type, :range, :spread

    def initialize(
      rank:,
      name:,
      description:,
      target_type:,
      range: nil,
      spread: nil
    )
      @rank = rank
      @name = name
      @description = description
      @target_type = target_type
      @range = range
      @spread = spread
    end
  end

  SPELLS = {
    water_wave: {
      rank: 1,
      name: "Water Wave",
      description: "Shoot water in an arc",
      target_type: :cone,
      spread: 45,
      range: 30,
    }
  }
end
