const currencyFormatter = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "EUR",
  maximumFractionDigits: 2
});

const percentageFormatter = new Intl.NumberFormat("en-US", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});

export function formatCurrency(value) {
  return currencyFormatter.format(Number(value || 0));
}

export function formatPercentage(value) {
  return `${percentageFormatter.format(Number(value || 0))}%`;
}
