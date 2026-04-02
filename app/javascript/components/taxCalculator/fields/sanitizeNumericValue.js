export function sanitizeDecimalValue(value) {
  const normalizedValue = String(value ?? "").replace(/,/g, ".");
  let sanitizedValue = "";
  let hasDecimalSeparator = false;

  for (const character of normalizedValue) {
    if (/\d/.test(character)) {
      sanitizedValue += character;
      continue;
    }

    if (character === "." && !hasDecimalSeparator) {
      sanitizedValue += character;
      hasDecimalSeparator = true;
    }
  }

  return sanitizedValue;
}

export function sanitizeIntegerValue(value) {
  return String(value ?? "").replace(/\D/g, "");
}

export function buildSanitizedValueEvent(value) {
  return { target: { value } };
}
