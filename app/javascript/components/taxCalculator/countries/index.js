import defaultCountryCalculatorConfig from "./default";
import spainCalculatorConfig from "./spain";

const countryConfigs = {
  ES: spainCalculatorConfig
};

export function resolveCountryCalculatorConfig(countryCode) {
  return countryConfigs[countryCode] || defaultCountryCalculatorConfig;
}
