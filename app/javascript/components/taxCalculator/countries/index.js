import czechRepublicCalculatorConfig from "./czech_republic";
import defaultCountryCalculatorConfig from "./default";
import netherlandsCalculatorConfig from "./netherlands";
import polandCalculatorConfig from "./poland";
import spainCalculatorConfig from "./spain";

const countryConfigs = {
  CZ: czechRepublicCalculatorConfig,
  ES: spainCalculatorConfig,
  NL: netherlandsCalculatorConfig,
  PL: polandCalculatorConfig
};

export function resolveCountryCalculatorConfig(countryCode) {
  return countryConfigs[countryCode] || defaultCountryCalculatorConfig;
}
