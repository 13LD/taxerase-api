import defaultCountryCalculatorConfig from "./default";
import netherlandsCalculatorConfig from "./netherlands";
import spainCalculatorConfig from "./spain";

const countryConfigs = {
  ES: spainCalculatorConfig,
  NL: netherlandsCalculatorConfig
};

export function resolveCountryCalculatorConfig(countryCode) {
  return countryConfigs[countryCode] || defaultCountryCalculatorConfig;
}
