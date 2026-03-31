module Taxerase
  module Spain2025
    module RegionCatalog
      STATE_TAXPAYER_MINIMUM = 5_550

      STATE_IRPF_BRACKETS = [
        [ 12_450, 0.095 ],
        [ 20_200, 0.12 ],
        [ 35_200, 0.15 ],
        [ 60_000, 0.185 ],
        [ 300_000, 0.225 ],
        [ nil, 0.245 ]
      ].freeze

      RETA_2025_BANDS = [
        { upper_bound: 670, lower_bound: 0, base_min: 653.59, base_max: 718.94, label: "Tramo 1 <= 670" },
        { upper_bound: 900, lower_bound: 670.01, base_min: 718.95, base_max: 900, label: "Tramo 2 > 670 y <= 900" },
        { upper_bound: 1_166.69, lower_bound: 900.01, base_min: 849.67, base_max: 1_166.70, label: "Tramo 3 > 900 y < 1.166,70" },
        { upper_bound: 1_300, lower_bound: 1_166.70, base_min: 950.98, base_max: 1_300, label: "Tramo 1 >= 1.166,70 y <= 1.300" },
        { upper_bound: 1_500, lower_bound: 1_300.01, base_min: 960.78, base_max: 1_500, label: "Tramo 2 > 1.300 y <= 1.500" },
        { upper_bound: 1_700, lower_bound: 1_500.01, base_min: 960.78, base_max: 1_700, label: "Tramo 3 > 1.500 y <= 1.700" },
        { upper_bound: 1_850, lower_bound: 1_700.01, base_min: 1_143.79, base_max: 1_850, label: "Tramo 4 > 1.700 y <= 1.850" },
        { upper_bound: 2_030, lower_bound: 1_850.01, base_min: 1_209.15, base_max: 2_030, label: "Tramo 5 > 1.850 y <= 2.030" },
        { upper_bound: 2_330, lower_bound: 2_030.01, base_min: 1_274.51, base_max: 2_330, label: "Tramo 6 > 2.030 y <= 2.330" },
        { upper_bound: 2_760, lower_bound: 2_330.01, base_min: 1_356.21, base_max: 2_760, label: "Tramo 7 > 2.330 y <= 2.760" },
        { upper_bound: 3_190, lower_bound: 2_760.01, base_min: 1_437.91, base_max: 3_190, label: "Tramo 8 > 2.760 y <= 3.190" },
        { upper_bound: 3_620, lower_bound: 3_190.01, base_min: 1_519.61, base_max: 3_620, label: "Tramo 9 > 3.190 y <= 3.620" },
        { upper_bound: 4_050, lower_bound: 3_620.01, base_min: 1_601.31, base_max: 4_050, label: "Tramo 10 > 3.620 y <= 4.050" },
        { upper_bound: 6_000, lower_bound: 4_050.01, base_min: 1_732.03, base_max: 4_909.50, label: "Tramo 11 > 4.050 y <= 6.000" },
        { upper_bound: nil, lower_bound: 6_000.01, base_min: 1_928.10, base_max: 4_909.50, label: "Tramo 12 > 6.000" }
      ].freeze

      COMMON_REGIME_REGIONS = [
        {
          key: "andalusia",
          name: "Andalusia",
          regional_taxpayer_minimum: 5_790,
          regional_brackets: [
            [ 13_000, 0.095 ],
            [ 21_100, 0.12 ],
            [ 35_200, 0.15 ],
            [ 60_000, 0.185 ],
            [ nil, 0.225 ]
          ]
        },
        {
          key: "aragon",
          name: "Aragon",
          regional_taxpayer_minimum: STATE_TAXPAYER_MINIMUM,
          regional_brackets: [
            [ 13_072.50, 0.095 ],
            [ 21_210, 0.12 ],
            [ 36_960, 0.15 ],
            [ 52_500, 0.185 ],
            [ 60_000, 0.205 ],
            [ 80_000, 0.23 ],
            [ 90_000, 0.24 ],
            [ 130_000, 0.25 ],
            [ nil, 0.255 ]
          ]
        },
        {
          key: "asturias",
          name: "Asturias",
          regional_taxpayer_minimum: 6_105,
          regional_brackets: [
            [ 12_450, 0.09 ],
            [ 17_707.20, 0.12 ],
            [ 33_007.20, 0.14 ],
            [ 53_407.20, 0.192 ],
            [ 70_000, 0.215 ],
            [ 90_000, 0.225 ],
            [ 175_000, 0.25 ],
            [ nil, 0.26 ]
          ]
        },
        {
          key: "balearic_islands",
          name: "Balearic Islands",
          regional_taxpayer_minimum: STATE_TAXPAYER_MINIMUM,
          regional_brackets: [
            [ 10_000, 0.09 ],
            [ 18_000, 0.1125 ],
            [ 30_000, 0.1425 ],
            [ 48_000, 0.175 ],
            [ 70_000, 0.19 ],
            [ 90_000, 0.2175 ],
            [ 120_000, 0.2275 ],
            [ 175_000, 0.2375 ],
            [ nil, 0.2475 ]
          ]
        },
        {
          key: "canary_islands",
          name: "Canary Islands",
          regional_taxpayer_minimum: 5_606,
          regional_brackets: [
            [ 13_748, 0.09 ],
            [ 19_422, 0.115 ],
            [ 35_924, 0.14 ],
            [ 57_566, 0.185 ],
            [ 93_268, 0.235 ],
            [ 123_745, 0.25 ],
            [ nil, 0.26 ]
          ]
        },
        {
          key: "cantabria",
          name: "Cantabria",
          regional_taxpayer_minimum: STATE_TAXPAYER_MINIMUM,
          regional_brackets: [
            [ 13_000, 0.085 ],
            [ 21_000, 0.11 ],
            [ 35_200, 0.145 ],
            [ 60_000, 0.18 ],
            [ 90_000, 0.225 ],
            [ nil, 0.245 ]
          ]
        },
        {
          key: "castilla_la_mancha",
          name: "Castilla-La Mancha",
          regional_taxpayer_minimum: STATE_TAXPAYER_MINIMUM,
          regional_brackets: [
            [ 12_450, 0.095 ],
            [ 20_200, 0.12 ],
            [ 35_200, 0.15 ],
            [ 60_000, 0.185 ],
            [ nil, 0.225 ]
          ]
        },
        {
          key: "castile_and_leon",
          name: "Castile and Leon",
          regional_taxpayer_minimum: STATE_TAXPAYER_MINIMUM,
          regional_brackets: [
            [ 12_450, 0.09 ],
            [ 20_200, 0.12 ],
            [ 35_200, 0.14 ],
            [ 53_407.20, 0.185 ],
            [ nil, 0.215 ]
          ]
        },
        {
          key: "catalonia",
          name: "Catalonia",
          regional_taxpayer_minimum: STATE_TAXPAYER_MINIMUM,
          regional_brackets: [
            [ 12_500, 0.095 ],
            [ 22_000, 0.125 ],
            [ 33_000, 0.16 ],
            [ 53_000, 0.19 ],
            [ 90_000, 0.215 ],
            [ 120_000, 0.235 ],
            [ 175_000, 0.245 ],
            [ nil, 0.255 ]
          ]
        },
        {
          key: "extremadura",
          name: "Extremadura",
          regional_taxpayer_minimum: STATE_TAXPAYER_MINIMUM,
          regional_brackets: [
            [ 12_450, 0.08 ],
            [ 20_200, 0.10 ],
            [ 24_200, 0.16 ],
            [ 35_200, 0.175 ],
            [ 60_000, 0.21 ],
            [ 80_200, 0.235 ],
            [ 99_200, 0.24 ],
            [ 120_200, 0.245 ],
            [ nil, 0.25 ]
          ]
        },
        {
          key: "galicia",
          name: "Galicia",
          regional_taxpayer_minimum: 5_789,
          regional_brackets: [
            [ 12_985.35, 0.09 ],
            [ 21_068.60, 0.1165 ],
            [ 35_200, 0.149 ],
            [ 60_000, 0.184 ],
            [ nil, 0.225 ]
          ]
        },
        {
          key: "madrid",
          name: "Madrid",
          regional_taxpayer_minimum: 5_956.65,
          regional_brackets: [
            [ 13_362.22, 0.085 ],
            [ 19_004.63, 0.107 ],
            [ 35_425.68, 0.128 ],
            [ 57_320.40, 0.174 ],
            [ nil, 0.205 ]
          ]
        },
        {
          key: "murcia",
          name: "Murcia",
          regional_taxpayer_minimum: STATE_TAXPAYER_MINIMUM,
          regional_brackets: [
            [ 12_450, 0.095 ],
            [ 20_200, 0.112 ],
            [ 34_000, 0.133 ],
            [ 60_000, 0.179 ],
            [ nil, 0.225 ]
          ]
        },
        {
          key: "la_rioja",
          name: "La Rioja",
          regional_taxpayer_minimum: STATE_TAXPAYER_MINIMUM,
          regional_brackets: [
            [ 12_450, 0.08 ],
            [ 20_200, 0.106 ],
            [ 35_200, 0.136 ],
            [ 40_000, 0.178 ],
            [ 50_000, 0.183 ],
            [ 60_000, 0.19 ],
            [ 120_000, 0.245 ],
            [ nil, 0.27 ]
          ]
        },
        {
          key: "valencian_community",
          name: "Valencian Community",
          regional_taxpayer_minimum: 6_105,
          regional_brackets: [
            [ 12_000, 0.09 ],
            [ 22_000, 0.12 ],
            [ 32_000, 0.15 ],
            [ 42_000, 0.175 ],
            [ 52_000, 0.20 ],
            [ 62_000, 0.225 ],
            [ 72_000, 0.25 ],
            [ 100_000, 0.265 ],
            [ 150_000, 0.275 ],
            [ 200_000, 0.285 ],
            [ nil, 0.295 ]
          ]
        },
        {
          key: "ceuta_melilla",
          name: "Ceuta and Melilla",
          regional_taxpayer_minimum: STATE_TAXPAYER_MINIMUM,
          regional_brackets: [
            [ 12_450, 0.095 ],
            [ 20_200, 0.12 ],
            [ 35_200, 0.15 ],
            [ 60_000, 0.185 ],
            [ nil, 0.225 ]
          ]
        }
      ].freeze

      def self.default_region_key
        "madrid"
      end

      def self.default_employee_regime_key
        regime_key(category: "employee", region_key: default_region_key)
      end

      def self.regime_key(category:, region_key:)
        "#{category}_#{region_key}"
      end

      def self.region(region_key)
        COMMON_REGIME_REGIONS.find { |item| item[:key] == region_key }
      end
    end
  end
end
