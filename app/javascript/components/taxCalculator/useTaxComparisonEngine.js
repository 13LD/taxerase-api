import {
  startTransition,
  useCallback,
  useDeferredValue,
  useEffect,
  useMemo,
  useRef,
  useState
} from "react";
import { buildComparisonPayload, requestComparison } from "./api";
import {
  buildComparisonGraphicCopy,
  buildComparisonProfileOptions,
  resolveComparisonProfile
} from "./comparisonProfiles";
import {
  buildComparisonCountryOptions,
  buildComparisonInputCurrencyOptions,
  buildComparisonRegimesForCountry,
  findComparisonCountryEntry,
  resolveComparisonCountryCode,
  resolveComparisonRegionSelection,
  resolveComparisonTaxYear
} from "./comparisonSelection";

export default function useTaxComparisonEngine({
  comparisonCatalog,
  currentCountryCode,
  defaultGrossIncome,
  enabled = true
}) {
  const requestAbortControllerRef = useRef(null);
  const successfulSignatureRef = useRef(null);
  const profileOptions = useMemo(
    () => buildComparisonProfileOptions(comparisonCatalog),
    [comparisonCatalog]
  );
  const [selectedCategoryPreference, setSelectedCategoryPreference] = useState(
    profileOptions[0]?.value || "employee"
  );
  const [grossIncome, setGrossIncome] = useState(String(defaultGrossIncome || 60_000));
  const [inputCurrencyPreference, setInputCurrencyPreference] = useState("");
  const [deductibleExpenses, setDeductibleExpenses] = useState("0");
  const [leftCountryPreference, setLeftCountryPreference] = useState(currentCountryCode);
  const [leftRegionPreference, setLeftRegionPreference] = useState("");
  const [rightCountryPreference, setRightCountryPreference] = useState("");
  const [rightRegionPreference, setRightRegionPreference] = useState("");
  const [comparisonResult, setComparisonResult] = useState(null);
  const [status, setStatus] = useState("idle");
  const [errors, setErrors] = useState([]);
  const deferredGrossIncome = useDeferredValue(grossIncome);
  const selectedProfile = useMemo(
    () => resolveComparisonProfile(selectedCategoryPreference, profileOptions),
    [profileOptions, selectedCategoryPreference]
  );
  const selectedCategory = selectedProfile.key;

  useEffect(() => {
    if (
      selectedCategoryPreference &&
      profileOptions.some((profile) => profile.value === selectedCategoryPreference)
    ) {
      return;
    }

    if (profileOptions[0]?.value) {
      setSelectedCategoryPreference(profileOptions[0].value);
    }
  }, [profileOptions, selectedCategoryPreference]);

  const availableCountryOptions = useMemo(
    () => buildComparisonCountryOptions(comparisonCatalog, selectedCategory),
    [comparisonCatalog, selectedCategory]
  );

  const leftCountryCode = resolveComparisonCountryCode({
    availableCountryOptions,
    preferredCountryCode: leftCountryPreference,
    fallbackCountryCode: currentCountryCode
  });
  const defaultRightCountryCode =
    availableCountryOptions.find((entry) => entry.country.code !== leftCountryCode)?.country.code ||
    leftCountryCode;
  const rightCountryCode = resolveComparisonCountryCode({
    availableCountryOptions,
    preferredCountryCode: rightCountryPreference,
    fallbackCountryCode: defaultRightCountryCode
  });

  const leftCountryEntry = findComparisonCountryEntry(availableCountryOptions, leftCountryCode);
  const rightCountryEntry = findComparisonCountryEntry(availableCountryOptions, rightCountryCode);
  const leftCurrencyCode = leftCountryEntry?.country?.currency_code || "EUR";
  const rightCurrencyCode = rightCountryEntry?.country?.currency_code || "EUR";
  const usesEuroNormalization = leftCurrencyCode !== rightCurrencyCode;
  const comparisonCurrencyCode = usesEuroNormalization ? "EUR" : leftCurrencyCode;
  const inputCurrencyOptions = useMemo(
    () => buildComparisonInputCurrencyOptions(leftCountryEntry, rightCountryEntry),
    [leftCountryEntry, rightCountryEntry]
  );
  const inputCurrencyCode = inputCurrencyOptions.some(
    (option) => option.code === inputCurrencyPreference
  )
    ? inputCurrencyPreference
    : (inputCurrencyOptions[0]?.code || comparisonCurrencyCode);
  const selectedTaxYear = resolveComparisonTaxYear({
    leftCountryEntry,
    rightCountryEntry,
    selectedCategory
  });
  const leftComparisonRegimes = buildComparisonRegimesForCountry(
    leftCountryEntry,
    selectedTaxYear,
    selectedCategory
  );
  const rightComparisonRegimes = buildComparisonRegimesForCountry(
    rightCountryEntry,
    selectedTaxYear,
    selectedCategory
  );
  const leftComparisonSelection = resolveComparisonRegionSelection({
    comparisonRegimes: leftComparisonRegimes,
    preferredRegion: leftRegionPreference,
    fallbackRegion: ""
  });
  const rightComparisonSelection = resolveComparisonRegionSelection({
    comparisonRegimes: rightComparisonRegimes,
    preferredRegion: rightRegionPreference,
    fallbackRegion: ""
  });
  const leftRegime = leftComparisonSelection.selectedRegime;
  const rightRegime = rightComparisonSelection.selectedRegime;
  const leftRegionOptions = leftComparisonSelection.regionOptions;
  const rightRegionOptions = rightComparisonSelection.regionOptions;
  const normalizedGrossIncome = deferredGrossIncome.trim();
  const normalizedDeductibleExpenses = deductibleExpenses.trim();
  const incomeLabel = selectedProfile.incomeLabel;
  const showDeductibleExpenses = selectedProfile.showDeductibleExpenses;
  const canCompare = Boolean(
    selectedTaxYear &&
      leftRegime &&
      rightRegime &&
      normalizedGrossIncome !== "" &&
      Number(normalizedGrossIncome) > 0
  );
  const comparisonSignature = useMemo(
    () =>
      [
        leftCountryCode,
        leftRegime?.key || "",
        rightCountryCode,
        rightRegime?.key || "",
        selectedTaxYear || "",
        selectedCategory,
        normalizedGrossIncome,
        inputCurrencyCode,
        showDeductibleExpenses ? normalizedDeductibleExpenses : "0"
      ].join(":"),
    [
      leftCountryCode,
      leftRegime,
      inputCurrencyCode,
      normalizedDeductibleExpenses,
      normalizedGrossIncome,
      rightCountryCode,
      rightRegime,
      selectedCategory,
      selectedTaxYear,
      showDeductibleExpenses
    ]
  );

  const unavailableMessage = useMemo(() => {
    if (normalizedGrossIncome === "" || Number(normalizedGrossIncome) <= 0) {
      return "Enter an annual income to compare two jurisdictions.";
    }

    if (!selectedTaxYear) {
      return "No shared supported tax year is available for the selected jurisdictions and tax profile.";
    }

    if (!leftRegime || !rightRegime) {
      return "Choose two supported jurisdictions to compare.";
    }

    return "Comparison is not available for the current selection.";
  }, [leftRegime, normalizedGrossIncome, rightRegime, selectedTaxYear]);
  const graphicCopy = useMemo(
    () =>
      buildComparisonGraphicCopy({
        inputCurrencyCode,
        deductibleExpenses: normalizedDeductibleExpenses || "0",
        grossIncome: normalizedGrossIncome || "0",
        incomeLabel,
        profile: selectedProfile
      }),
    [
      incomeLabel,
      inputCurrencyCode,
      normalizedDeductibleExpenses,
      normalizedGrossIncome,
      selectedProfile
    ]
  );

  const runComparison = useCallback(async () => {
    if (!canCompare) {
      requestAbortControllerRef.current?.abort();
      setComparisonResult(null);
      setErrors([]);
      setStatus("unavailable");
      return;
    }

    requestAbortControllerRef.current?.abort();

    const abortController = new AbortController();
    requestAbortControllerRef.current = abortController;

    setStatus("loading");
    setErrors([]);

    try {
      const response = await requestComparison({
        payload: buildComparisonPayload({
          deductibleExpenses: showDeductibleExpenses ? normalizedDeductibleExpenses || "0" : "0",
          grossIncome: normalizedGrossIncome,
          inputCurrencyCode,
          leftCountryCode,
          leftTaxRegimeKey: leftRegime.key,
          rightCountryCode,
          rightTaxRegimeKey: rightRegime.key,
          selectedCategory,
          selectedTaxYear
        }),
        signal: abortController.signal
      });

      const payload = await response.json();
      if (abortController.signal.aborted) return;

      if (!response.ok) {
        setErrors(payload.errors || [ "The comparison could not be processed." ]);
        setComparisonResult(null);
        setStatus("error");
        return;
      }

      startTransition(() => {
        setComparisonResult(payload);
      });
      successfulSignatureRef.current = comparisonSignature;
      setStatus("success");
    } catch {
      if (abortController.signal.aborted) return;

      setComparisonResult(null);
      setErrors([ "Network error while comparing." ]);
      setStatus("error");
    }
  }, [
    canCompare,
    comparisonSignature,
    leftCountryCode,
    leftRegime,
    inputCurrencyCode,
    normalizedDeductibleExpenses,
    normalizedGrossIncome,
    rightCountryCode,
    rightRegime,
    selectedCategory,
    selectedTaxYear,
    showDeductibleExpenses
  ]);

  useEffect(() => {
    if (!enabled) {
      requestAbortControllerRef.current?.abort();
      return;
    }

    if (successfulSignatureRef.current === comparisonSignature) return;

    void runComparison();
  }, [comparisonSignature, enabled, runComparison]);

  useEffect(
    () => () => {
      requestAbortControllerRef.current?.abort();
    },
    []
  );

  return {
    comparisonProps: {
      comparisonContextLabel: selectedProfile.comparisonContextLabel,
      countryDefaultsNote: selectedProfile.countryDefaultsNote,
      deductibleExpenses,
      deductibleExpensesLabel: selectedProfile.deductibleExpensesLabel,
      errors,
      fxReference: comparisonResult?.metadata?.fx_reference || null,
      graphicCopy,
      grossIncome,
      incomeLabel,
      inputCurrencyCode,
      inputCurrencyOptions,
      leftCountryCode,
      leftCountryOptions: availableCountryOptions.map((entry) => entry.country),
      leftRegion: leftComparisonSelection.selectedRegion,
      leftRegionOptions,
      onCategoryChange: (value) => {
        setSelectedCategoryPreference(value);
        setStatus("loading");
      },
      onGrossIncomeChange: (event) => {
        setGrossIncome(event.target.value);
        setStatus("loading");
      },
      onInputCurrencyChange: (event) => {
        setInputCurrencyPreference(event.target.value);
        setStatus("loading");
      },
      onDeductibleExpensesChange: (event) => {
        setDeductibleExpenses(event.target.value);
        setStatus("loading");
      },
      onLeftCountryChange: (event) => {
        setLeftCountryPreference(event.target.value);
        setStatus("loading");
      },
      onLeftRegionChange: (event) => {
        setLeftRegionPreference(event.target.value);
        setStatus("loading");
      },
      onRightCountryChange: (event) => {
        setRightCountryPreference(event.target.value);
        setStatus("loading");
      },
      onRightRegionChange: (event) => {
        setRightRegionPreference(event.target.value);
        setStatus("loading");
      },
      profileOptions,
      rightCountryCode,
      rightCountryOptions: availableCountryOptions.map((entry) => entry.country),
      rightRegion: rightComparisonSelection.selectedRegion,
      rightRegionOptions,
      selectedCategory: selectedProfile.key,
      showDeductibleExpenses,
      status,
      summaryMetrics: comparisonResult?.summary_metrics || [],
      taxYear: selectedTaxYear,
      unavailableMessage,
      usesEuroNormalization:
        comparisonResult?.metadata?.mixed_currency_comparison ?? usesEuroNormalization
    }
  };
}
