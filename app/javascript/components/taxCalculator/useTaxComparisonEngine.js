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
import { profileLabels } from "./options";
import {
  buildComparisonCountryOptions,
  buildComparisonRegimesForCountry,
  findComparisonCountryEntry,
  resolveComparisonCountryCode,
  resolveComparisonRegionSelection,
  resolveComparisonTaxYear
} from "./comparisonSelection";

function buildComparisonProfileOptions(comparisonCatalog) {
  return Object.entries(profileLabels)
    .filter(([category]) =>
      comparisonCatalog.some((entry) =>
        entry.regime_options.some((regime) => regime.category === category)
      )
    )
    .map(([value, label]) => ({ value, label }));
}

export default function useTaxComparisonEngine({
  comparisonCatalog,
  currentCountryCode,
  defaultGrossIncome
}) {
  const requestAbortControllerRef = useRef(null);
  const profileOptions = useMemo(
    () => buildComparisonProfileOptions(comparisonCatalog),
    [comparisonCatalog]
  );
  const [selectedCategoryPreference, setSelectedCategoryPreference] = useState(
    profileOptions[0]?.value || "employee"
  );
  const [grossIncome, setGrossIncome] = useState(String(defaultGrossIncome || 60_000));
  const [deductibleExpenses, setDeductibleExpenses] = useState("0");
  const [leftCountryPreference, setLeftCountryPreference] = useState(currentCountryCode);
  const [leftRegionPreference, setLeftRegionPreference] = useState("");
  const [rightCountryPreference, setRightCountryPreference] = useState("");
  const [rightRegionPreference, setRightRegionPreference] = useState("");
  const [comparisonResult, setComparisonResult] = useState(null);
  const [status, setStatus] = useState("idle");
  const [errors, setErrors] = useState([]);
  const deferredGrossIncome = useDeferredValue(grossIncome);
  const selectedCategory = profileOptions.some(
    (profile) => profile.value === selectedCategoryPreference
  )
    ? selectedCategoryPreference
    : (profileOptions[0]?.value || "employee");
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
  const incomeLabel =
    selectedCategory === "self_employed" ? "Annual revenue before expenses" : "Annual income";
  const showDeductibleExpenses = selectedCategory === "self_employed";
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
        showDeductibleExpenses ? normalizedDeductibleExpenses : "0"
      ].join(":"),
    [
      leftCountryCode,
      leftRegime,
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
      setStatus("success");
    } catch {
      if (abortController.signal.aborted) return;

      setComparisonResult(null);
      setErrors([ "Network error while comparing." ]);
      setStatus("error");
    }
  }, [
    canCompare,
    leftCountryCode,
    leftRegime,
    normalizedDeductibleExpenses,
    normalizedGrossIncome,
    rightCountryCode,
    rightRegime,
    selectedCategory,
    selectedTaxYear,
    showDeductibleExpenses
  ]);

  useEffect(() => {
    void runComparison();
  }, [comparisonSignature, runComparison]);

  useEffect(
    () => () => {
      requestAbortControllerRef.current?.abort();
    },
    []
  );

  return {
    comparisonProps: {
      deductibleExpenses,
      errors,
      grossIncome,
      incomeLabel,
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
      selectedCategory,
      showDeductibleExpenses,
      status,
      summaryMetrics: comparisonResult?.summary_metrics || [],
      taxYear: selectedTaxYear,
      unavailableMessage
    }
  };
}
