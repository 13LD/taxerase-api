import {
  startTransition,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState
} from "react";
import { buildCalculationPayload, requestCalculation } from "./api";
import {
  buildAssumptionItems,
  buildDetailCards,
  buildDisplayedSources,
  buildHeadlineMetrics,
  pendingOutputValue
} from "./display";
import { buildCountOptions, buildProfileOptions } from "./options";
import {
  buildCalculationSignature,
  buildRegionOptions,
  buildResultCalculationSignature,
  findInitialRegime,
  findSelectedRegime
} from "./selection";

export default function useTaxCalculatorEngine({
  calculationEndpoint,
  defaultInput,
  defaultTaxRegimeKey,
  initialResult,
  regimeOptions,
  supportsThirtyPercentRuling = false,
  taxYearOptions
}) {
  const initialRegime = findInitialRegime({
    regimeOptions,
    defaultTaxRegimeKey,
    defaultTaxYear: defaultInput.tax_year
  });

  const [selectedTaxYear, setSelectedTaxYear] = useState(defaultInput.tax_year);
  const [selectedCategoryPreference, setSelectedCategoryPreference] = useState(
    initialRegime?.category || "employee"
  );
  const [selectedRegionPreference, setSelectedRegionPreference] = useState(
    initialRegime?.region || ""
  );
  const [grossIncome, setGrossIncome] = useState(String(defaultInput.gross_income));
  const [deductibleExpenses, setDeductibleExpenses] = useState(
    String(defaultInput.deductible_expenses || 0)
  );
  const [ageBracket, setAgeBracket] = useState(defaultInput.age_bracket || "under_65");
  const [childrenCount, setChildrenCount] = useState(String(defaultInput.children_count || 0));
  const [childrenUnderThreeCount, setChildrenUnderThreeCount] = useState(
    String(defaultInput.children_under_three_count || 0)
  );
  const [disabilityLevel, setDisabilityLevel] = useState(defaultInput.disability_level || "none");
  const [applyThirtyPercentRuling, setApplyThirtyPercentRuling] = useState(
    Boolean(defaultInput.apply_thirty_percent_ruling)
  );
  const [thirtyPercentRulingBasis, setThirtyPercentRulingBasis] = useState(
    defaultInput.thirty_percent_ruling_basis || "standard_threshold"
  );
  const [salaryPeriod, setSalaryPeriod] = useState(defaultInput.salary_period);
  const [result, setResult] = useState(initialResult);
  const [status, setStatus] = useState("ready");
  const [errors, setErrors] = useState([]);
  const requestAbortControllerRef = useRef(null);

  const regimesForYear = useMemo(
    () => regimeOptions.filter((regime) => regime.tax_year === selectedTaxYear),
    [regimeOptions, selectedTaxYear]
  );
  const profileOptions = useMemo(() => buildProfileOptions(regimesForYear), [regimesForYear]);
  const selectedCategory = profileOptions.some(
    (profile) => profile.value === selectedCategoryPreference
  )
    ? selectedCategoryPreference
    : (profileOptions[0]?.value || "employee");

  const regionOptions = useMemo(
    () => buildRegionOptions(regimesForYear, selectedCategory),
    [regimesForYear, selectedCategory]
  );
  const selectedRegion = regionOptions.some(
    (region) => region.region === selectedRegionPreference
  )
    ? selectedRegionPreference
    : (regionOptions[0]?.region || "");

  const selectedRegime = useMemo(
    () => findSelectedRegime(regimesForYear, selectedCategory, selectedRegion),
    [regimesForYear, selectedCategory, selectedRegion]
  );
  const selectedRegimeKey = selectedRegime?.key || null;
  const childrenCountNumber = Number(childrenCount || 0);
  const showDeductibleExpenses = selectedCategory === "self_employed";
  const effectiveApplyThirtyPercentRuling =
    supportsThirtyPercentRuling &&
    selectedCategory === "employee" &&
    applyThirtyPercentRuling;
  const effectiveThirtyPercentRulingBasis = effectiveApplyThirtyPercentRuling
    ? thirtyPercentRulingBasis
    : "";
  const incomeLabel =
    selectedCategory === "self_employed" ? "Revenue before expenses" : "Gross income";
  const periodLabel =
    selectedCategory === "self_employed" ? "Income period" : "Salary period";

  const selectedCalculationSignature = useMemo(
    () =>
      buildCalculationSignature({
        selectedTaxYear,
        selectedRegimeKey,
        ageBracket,
        childrenCount,
        childrenUnderThreeCount,
        disabilityLevel,
        applyThirtyPercentRuling: effectiveApplyThirtyPercentRuling,
        thirtyPercentRulingBasis: effectiveThirtyPercentRulingBasis
      }),
    [
      ageBracket,
      effectiveApplyThirtyPercentRuling,
      effectiveThirtyPercentRulingBasis,
      childrenCount,
      childrenUnderThreeCount,
      disabilityLevel,
      selectedRegimeKey,
      selectedTaxYear
    ]
  );
  const resultCalculationSignature = useMemo(
    () => buildResultCalculationSignature(result),
    [result]
  );
  const isSupportedRegime = Boolean(selectedRegime?.supported);
  const resultMatchesSelection =
    selectedCalculationSignature !== null &&
    selectedCalculationSignature === resultCalculationSignature;
  const displayStatus = !selectedRegime
    ? "unavailable"
    : !isSupportedRegime
      ? "unavailable"
      : status === "error"
        ? "error"
        : resultMatchesSelection
          ? status
          : "loading";
  const isCalculating = status === "loading" && Boolean(selectedRegime) && isSupportedRegime;
  const pendingValue = pendingOutputValue(selectedRegime, isSupportedRegime);

  const headlineMetrics = useMemo(
    () =>
      buildHeadlineMetrics({
        pendingValue,
        result,
        resultMatchesSelection
      }),
    [pendingValue, result, resultMatchesSelection]
  );
  const detailCards = useMemo(
    () =>
      buildDetailCards({
        result,
        resultMatchesSelection,
        selectedCategory,
        selectedRegion,
        pendingValue,
        applyThirtyPercentRuling: effectiveApplyThirtyPercentRuling,
        deductibleExpenses: Number(deductibleExpenses || 0)
      }),
    [
      effectiveApplyThirtyPercentRuling,
      deductibleExpenses,
      pendingValue,
      result,
      resultMatchesSelection,
      selectedCategory,
      selectedRegion
    ]
  );
  const displayedSources = useMemo(
    () =>
      buildDisplayedSources({
        resultMatchesSelection,
        result,
        selectedRegime
      }),
    [result, resultMatchesSelection, selectedRegime]
  );
  const assumptionItems = useMemo(
    () =>
      buildAssumptionItems({
        isSupportedRegime,
        result,
        resultMatchesSelection,
        selectedRegime
      }),
    [isSupportedRegime, result, resultMatchesSelection, selectedRegime]
  );
  const childrenCountOptions = useMemo(() => buildCountOptions(6), []);
  const childrenUnderThreeOptions = useMemo(
    () => buildCountOptions(childrenCountNumber),
    [childrenCountNumber]
  );

  function resetFormState() {
    setErrors([]);
    setStatus("ready");
  }

  function prepareAutoRefresh() {
    setErrors([]);
    setStatus("loading");
  }

  function handleTaxYearChange(event) {
    setSelectedTaxYear(Number(event.target.value));
    prepareAutoRefresh();
  }

  function handleCategoryChange(category) {
    setSelectedCategoryPreference(category);
    prepareAutoRefresh();
  }

  function handleRegionChange(event) {
    setSelectedRegionPreference(event.target.value);
    prepareAutoRefresh();
  }

  function handleAgeBracketChange(event) {
    setAgeBracket(event.target.value);
    prepareAutoRefresh();
  }

  function handleChildrenCountChange(event) {
    const nextChildrenCount = event.target.value;
    const clampedChildrenUnderThreeCount = String(
      Math.min(Number(childrenUnderThreeCount || 0), Number(nextChildrenCount || 0))
    );

    setChildrenCount(nextChildrenCount);
    setChildrenUnderThreeCount(clampedChildrenUnderThreeCount);
    prepareAutoRefresh();
  }

  function handleChildrenUnderThreeChange(event) {
    setChildrenUnderThreeCount(event.target.value);
    prepareAutoRefresh();
  }

  function handleDisabilityLevelChange(event) {
    setDisabilityLevel(event.target.value);
    prepareAutoRefresh();
  }

  function handleApplyThirtyPercentRulingChange(event) {
    setApplyThirtyPercentRuling(event.target.checked);
    prepareAutoRefresh();
  }

  function handleThirtyPercentRulingBasisChange(event) {
    setThirtyPercentRulingBasis(event.target.value);
    prepareAutoRefresh();
  }

  const submitCalculation = useCallback(async () => {
    if (!selectedRegime || !isSupportedRegime) return;

    requestAbortControllerRef.current?.abort();

    const abortController = new AbortController();
    requestAbortControllerRef.current = abortController;

    setStatus("loading");
    setErrors([]);

    try {
      const response = await requestCalculation({
        endpoint: calculationEndpoint,
        payload: buildCalculationPayload({
          applyThirtyPercentRuling: effectiveApplyThirtyPercentRuling,
          grossIncome,
          deductibleExpenses: showDeductibleExpenses ? deductibleExpenses : 0,
          salaryPeriod,
          selectedTaxYear,
          selectedRegimeKey: selectedRegime.key,
          ageBracket,
          childrenCount,
          childrenUnderThreeCount,
          disabilityLevel,
          thirtyPercentRulingBasis: effectiveThirtyPercentRulingBasis
        }),
        signal: abortController.signal
      });

      const payload = await response.json();
      if (abortController.signal.aborted) return;

      if (!response.ok) {
        setErrors(payload.errors || ["The calculator could not process this request."]);
        setStatus("error");
        return;
      }

      startTransition(() => {
        setResult(payload);
      });
      setStatus("success");
    } catch {
      if (abortController.signal.aborted) return;

      setErrors(["Network error while calculating."]);
      setStatus("error");
    }
  }, [
    ageBracket,
    calculationEndpoint,
    childrenCount,
    childrenUnderThreeCount,
    deductibleExpenses,
    disabilityLevel,
    effectiveApplyThirtyPercentRuling,
    effectiveThirtyPercentRulingBasis,
    grossIncome,
    isSupportedRegime,
    salaryPeriod,
    selectedRegime,
    selectedTaxYear,
    showDeductibleExpenses
  ]);

  useEffect(() => {
    if (!selectedRegime || !isSupportedRegime) {
      requestAbortControllerRef.current?.abort();
      return;
    }

    if (selectedCalculationSignature === resultCalculationSignature) return;

    void submitCalculation();
  }, [
    isSupportedRegime,
    resultCalculationSignature,
    selectedCalculationSignature,
    selectedRegime,
    submitCalculation
  ]);

  useEffect(
    () => () => {
      requestAbortControllerRef.current?.abort();
    },
    []
  );

  async function handleSubmit(event) {
    event.preventDefault();
    await submitCalculation();
  }

  return {
    assumptionItems,
    detailCards,
    displayStatus,
    displayedSources,
    formProps: {
      ageBracket,
      applyThirtyPercentRuling,
      childrenCount,
      childrenCountNumber,
      childrenCountOptions,
      childrenUnderThreeCount,
      childrenUnderThreeOptions,
      deductibleExpenses,
      disabilityLevel,
      errors,
      grossIncome,
      incomeLabel,
      isCalculating,
      isSupportedRegime,
      onAgeBracketChange: handleAgeBracketChange,
      onApplyThirtyPercentRulingChange: handleApplyThirtyPercentRulingChange,
      onCategoryChange: handleCategoryChange,
      onChildrenCountChange: handleChildrenCountChange,
      onChildrenUnderThreeChange: handleChildrenUnderThreeChange,
      onDeductibleExpensesChange: (event) => {
        setDeductibleExpenses(event.target.value);
        resetFormState();
      },
      onDisabilityLevelChange: handleDisabilityLevelChange,
      onGrossIncomeChange: (event) => {
        setGrossIncome(event.target.value);
        resetFormState();
      },
      onRegionChange: handleRegionChange,
      onSalaryPeriodChange: (nextSalaryPeriod) => {
        setSalaryPeriod(nextSalaryPeriod);
        resetFormState();
      },
      onSubmit: handleSubmit,
      onTaxYearChange: handleTaxYearChange,
      onThirtyPercentRulingBasisChange: handleThirtyPercentRulingBasisChange,
      periodLabel,
      profileOptions,
      regionOptions,
      salaryPeriod,
      selectedCategory,
      selectedRegime,
      selectedRegion,
      selectedTaxYear,
      showDeductibleExpenses,
      thirtyPercentRulingBasis,
      taxYearOptions
    },
    headlineMetrics,
    selectedRegime,
    selectedTaxYear
  };
}
