import andorraCalculatorConfig from "./andorra";
import czechRepublicCalculatorConfig from "./czech_republic";
import defaultCountryCalculatorConfig from "./default";
import netherlandsCalculatorConfig from "./netherlands";
import polandCalculatorConfig from "./poland";
import portugalCalculatorConfig from "./portugal";
import spainCalculatorConfig from "./spain";

const countryConfigs = {
  AD: andorraCalculatorConfig,
  CZ: czechRepublicCalculatorConfig,
  ES: spainCalculatorConfig,
  NL: netherlandsCalculatorConfig,
  PL: polandCalculatorConfig,
  PT: portugalCalculatorConfig
};

export function resolveCountryCalculatorConfig(countryCode) {
  return countryConfigs[countryCode] || defaultCountryCalculatorConfig;
}
