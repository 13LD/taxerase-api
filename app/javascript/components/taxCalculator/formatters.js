const currencyFormatters = {};
const currencySymbols = {};
const fallbackCurrencySymbols = {
  EUR: "€",
  PLN: "zł",
  CZK: "Kč"
};

const percentageFormatter = new Intl.NumberFormat("en-US", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});

export function formatCurrency(value, currencyCode = "EUR") {
  const resolvedCurrencyCode = currencyCode || "EUR";

  if (!currencyFormatters[resolvedCurrencyCode]) {
    currencyFormatters[resolvedCurrencyCode] = new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: resolvedCurrencyCode,
      maximumFractionDigits: 2
    });
  }

  return currencyFormatters[resolvedCurrencyCode].format(Number(value || 0));
}

export function formatCompactCurrency(value, currencyCode = "EUR") {
  const resolvedCurrencyCode = currencyCode || "EUR";
  const normalizedValue = Math.trunc(Number(value || 0) * 10) / 10;

  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: resolvedCurrencyCode,
    minimumFractionDigits: 0,
    maximumFractionDigits: 1
  }).format(normalizedValue);
}

export function currencySymbol(currencyCode = "EUR") {
  const resolvedCurrencyCode = currencyCode || "EUR";

  if (fallbackCurrencySymbols[resolvedCurrencyCode]) {
    return fallbackCurrencySymbols[resolvedCurrencyCode];
  }

  if (!currencySymbols[resolvedCurrencyCode]) {
    const currencyPart = new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: resolvedCurrencyCode,
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).formatToParts(1).find((part) => part.type === "currency");

    currencySymbols[resolvedCurrencyCode] = currencyPart?.value || resolvedCurrencyCode;
  }

  return currencySymbols[resolvedCurrencyCode];
}

export function formatPercentage(value) {
  return `${percentageFormatter.format(Number(value || 0))}%`;
}
