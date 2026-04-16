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
  buildInitialRegimeControlValues,
  buildRegimeControlPayload,
  buildResultControlSignatureParts,
  buildSelectedControlSignatureParts,
  buildVisibleRegimeControls,
  resolveRegimeControlEffects
} from "./regimeControls";
import {
  buildCalculationSignature,
  buildRegionOptions,
  buildResultCalculationSignature,
  buildSelectionResultSignature,
  findInitialRegime,
  resolveSelectedRegime
} from "./selection";

export default function useTaxCalculatorEngine({
  calculationEndpoint,
  countryCurrencyCode = "EUR",
  defaultInput,
  defaultTaxRegimeKey,
  inputCurrencyOptions = [],
  initialResult,
  incomeLabels: _incomeLabels = {},
  periodLabels: _periodLabels = {},
  profileLabels = {},
  regimeControls = [],
  regimeOptions,
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
  const [selectedInputCurrencyCode, setSelectedInputCurrencyCode] = useState(
    defaultInput.input_currency_code || inputCurrencyOptions[0]?.code || countryCurrencyCode
  );
  const [deductibleExpenses, setDeductibleExpenses] = useState(
    String(defaultInput.deductible_expenses || 0)
  );
  const [ageBracket, setAgeBracket] = useState(defaultInput.age_bracket || "under_65");
  const [childrenCount, setChildrenCount] = useState(String(defaultInput.children_count || 0));
  const [childrenUnderThreeCount, setChildrenUnderThreeCount] = useState(
    String(defaultInput.children_under_three_count || 0)
  );
  const [disabilityLevel, setDisabilityLevel] = useState(defaultInput.disability_level || "none");
  const [regimeControlValues, setRegimeControlValues] = useState(
    buildInitialRegimeControlValues({
      defaultInput,
      regimeControls
    })
  );
  const [salaryPeriod, setSalaryPeriod] = useState(defaultInput.salary_period);
  const [result, setResult] = useState(initialResult);
  const [status, setStatus] = useState("ready");
  const [errors, setErrors] = useState([]);
  const requestAbortControllerRef = useRef(null);
  const inFlightCalculationSignatureRef = useRef(null);
  const successfulCalculationSignatureRef = useRef(null);

  const regimesForYear = useMemo(
    () => regimeOptions.filter((regime) => regime.tax_year === selectedTaxYear),
    [regimeOptions, selectedTaxYear]
  );
  const profileOptions = useMemo(
    () => buildProfileOptions(regimesForYear, profileLabels),
    [profileLabels, regimesForYear]
  );
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
  const visibleRegimeControls = useMemo(
    () =>
      buildVisibleRegimeControls({
        regimeControls,
        selectedCategory,
        controlValues: regimeControlValues
      }),
    [regimeControlValues, regimeControls, selectedCategory]
  );
  const regimeControlEffects = useMemo(
    () =>
      resolveRegimeControlEffects({
        regimeControls,
        selectedCategory,
        controlValues: regimeControlValues
      }),
    [regimeControlValues, regimeControls, selectedCategory]
  );
  const regimeCategoryOverride = regimeControlEffects.regimeCategoryOverride || null;

  const selectedRegime = useMemo(
    () =>
      resolveSelectedRegime({
        regimesForYear,
        selectedCategory,
        selectedRegion,
        regimeCategoryOverride
      }),
    [regimeCategoryOverride, regimesForYear, selectedCategory, selectedRegion]
  );
  const selectedRegimeKey = selectedRegime?.key || null;
  const childrenCountNumber = Number(childrenCount || 0);
  const showDeductibleExpenses =
    selectedCategory === "self_employed" && !regimeControlEffects.hideDeductibleExpenses;
  const showPersonalReliefFields = !regimeControlEffects.hidePersonalReliefFields;
  const incomeLabel = regimeControlEffects.incomeLabel || "Gross income";
  const periodLabel = "Income period";
  const selectedControlSignatureParts = useMemo(
    () =>
      buildSelectedControlSignatureParts({
        regimeControls,
        selectedCategory,
        controlValues: regimeControlValues
      }),
    [regimeControlValues, regimeControls, selectedCategory]
  );

  const selectedCalculationRequestSignature = useMemo(
    () =>
      buildCalculationSignature({
        selectedTaxYear,
        selectedRegimeKey,
        grossIncome,
        salaryPeriod,
        ageBracket,
        childrenCount,
        childrenUnderThreeCount,
        disabilityLevel,
        extraSignatureParts: [ selectedInputCurrencyCode, ...selectedControlSignatureParts ]
      }),
    [
      ageBracket,
      childrenCount,
      childrenUnderThreeCount,
      disabilityLevel,
      grossIncome,
      salaryPeriod,
      selectedInputCurrencyCode,
      selectedControlSignatureParts,
      selectedRegimeKey,
      selectedTaxYear
    ]
  );
  const selectedCalculationResultSignature = useMemo(
    () =>
      buildSelectionResultSignature({
        selectedTaxYear,
        selectedRegimeKey,
        grossIncome,
        salaryPeriod,
        ageBracket,
        childrenCount,
        childrenUnderThreeCount,
        disabilityLevel,
        extraSignatureParts: [ selectedInputCurrencyCode, ...selectedControlSignatureParts ]
      }),
    [
      ageBracket,
      childrenCount,
      childrenUnderThreeCount,
      disabilityLevel,
      grossIncome,
      salaryPeriod,
      selectedInputCurrencyCode,
      selectedControlSignatureParts,
      selectedRegimeKey,
      selectedTaxYear
    ]
  );
  const resultControlSignatureParts = useMemo(
    () =>
      buildResultControlSignatureParts({
        result,
        regimeControls,
        selectedCategory,
        controlValues: regimeControlValues
      }),
    [regimeControlValues, regimeControls, result, selectedCategory]
  );
  const resultCalculationSignature = useMemo(() => {
    const resultInputCurrencyCode = result?.input?.input_currency_code || countryCurrencyCode;

    return buildResultCalculationSignature(result, [
      resultInputCurrencyCode,
      ...resultControlSignatureParts
    ]);
  }, [countryCurrencyCode, result, resultControlSignatureParts]);
  const isSupportedRegime = Boolean(selectedRegime?.supported);
  const resultMatchesSelection =
    selectedCalculationResultSignature !== null &&
    selectedCalculationResultSignature === resultCalculationSignature;
  const displayStatus = !selectedRegime
    ? "unavailable"
    : !isSupportedRegime
      ? "unavailable"
      : status === "error"
        ? "error"
        : resultMatchesSelection
          ? status
          : "loading";
  const displayCurrencyCode = resultMatchesSelection
    ? (result?.metadata?.display_currency_code || countryCurrencyCode)
    : (selectedInputCurrencyCode || countryCurrencyCode);
  const isCalculating = status === "loading" && Boolean(selectedRegime) && isSupportedRegime;
  const pendingValue = pendingOutputValue(selectedRegime, isSupportedRegime);

  const headlineMetrics = useMemo(
    () =>
      buildHeadlineMetrics({
        currencyCode: displayCurrencyCode,
        pendingValue,
        result,
        resultMatchesSelection
      }),
    [displayCurrencyCode, pendingValue, result, resultMatchesSelection]
  );
  const detailCards = useMemo(
    () =>
      buildDetailCards({
        currencyCode: displayCurrencyCode,
        result,
        resultMatchesSelection,
        selectedCategory: selectedRegime?.category || selectedCategory,
        selectedRegion,
        pendingValue,
        applyThirtyPercentRuling: Boolean(regimeControlValues.apply_thirty_percent_ruling),
        deductibleExpenses: Number(deductibleExpenses || 0)
      }),
    [
      deductibleExpenses,
      displayCurrencyCode,
      pendingValue,
      regimeControlValues,
      result,
      resultMatchesSelection,
      selectedRegime,
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

  function handleRegimeControlChange(controlKey, nextValue) {
    setRegimeControlValues((currentValues) => ({
      ...currentValues,
      [controlKey]: nextValue
    }));
    prepareAutoRefresh();
  }

  const submitCalculation = useCallback(async ({ force = false } = {}) => {
    if (!selectedRegime || !isSupportedRegime) return;
    if (!selectedCalculationRequestSignature) return;
    if (!force && inFlightCalculationSignatureRef.current === selectedCalculationRequestSignature) return;
    if (!force && successfulCalculationSignatureRef.current === selectedCalculationRequestSignature) return;

    requestAbortControllerRef.current?.abort();

    const abortController = new AbortController();
    requestAbortControllerRef.current = abortController;
    inFlightCalculationSignatureRef.current = selectedCalculationRequestSignature;

    setStatus("loading");
    setErrors([]);

    try {
      const response = await requestCalculation({
        endpoint: calculationEndpoint,
        payload: buildCalculationPayload({
          grossIncome,
          inputCurrencyCode: selectedInputCurrencyCode,
          deductibleExpenses: showDeductibleExpenses ? deductibleExpenses : 0,
          salaryPeriod,
          selectedTaxYear,
          selectedRegimeKey: selectedRegime.key,
          ageBracket,
          childrenCount,
          childrenUnderThreeCount,
          disabilityLevel,
          regimeControlPayload: buildRegimeControlPayload({
            regimeControls,
            controlValues: regimeControlValues
          })
        }),
        signal: abortController.signal
      });

      const payload = await response.json();
      if (abortController.signal.aborted) {
        if (inFlightCalculationSignatureRef.current === selectedCalculationRequestSignature) {
          inFlightCalculationSignatureRef.current = null;
        }
        return;
      }

      if (!response.ok) {
        if (inFlightCalculationSignatureRef.current === selectedCalculationRequestSignature) {
          inFlightCalculationSignatureRef.current = null;
        }
        setErrors(payload.errors || ["The calculator could not process this request."]);
        setStatus("error");
        return;
      }

      startTransition(() => {
        setResult(payload);
      });
      successfulCalculationSignatureRef.current = selectedCalculationRequestSignature;
      if (inFlightCalculationSignatureRef.current === selectedCalculationRequestSignature) {
        inFlightCalculationSignatureRef.current = null;
      }
      setStatus("success");
    } catch {
      if (abortController.signal.aborted) {
        if (inFlightCalculationSignatureRef.current === selectedCalculationRequestSignature) {
          inFlightCalculationSignatureRef.current = null;
        }
        return;
      }

      if (inFlightCalculationSignatureRef.current === selectedCalculationRequestSignature) {
        inFlightCalculationSignatureRef.current = null;
      }
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
    grossIncome,
    isSupportedRegime,
    regimeControlValues,
    regimeControls,
    salaryPeriod,
    selectedInputCurrencyCode,
    selectedCalculationRequestSignature,
    selectedRegime,
    selectedTaxYear,
    showDeductibleExpenses
  ]);

  useEffect(() => {
    if (!selectedRegime || !isSupportedRegime) {
      requestAbortControllerRef.current?.abort();
      inFlightCalculationSignatureRef.current = null;
      return;
    }

    if (selectedCalculationRequestSignature === null) return;
    if (selectedCalculationRequestSignature === resultCalculationSignature) {
      if (
        inFlightCalculationSignatureRef.current &&
        inFlightCalculationSignatureRef.current !== selectedCalculationRequestSignature
      ) {
        requestAbortControllerRef.current?.abort();
        inFlightCalculationSignatureRef.current = null;
      }
      successfulCalculationSignatureRef.current = selectedCalculationRequestSignature;
      if (errors.length > 0) {
        setErrors([]);
      }
      if (status !== "ready" && status !== "success") {
        setStatus("success");
      }
      return;
    }
    if (inFlightCalculationSignatureRef.current === selectedCalculationRequestSignature) return;
    if (successfulCalculationSignatureRef.current === selectedCalculationRequestSignature) return;

    void submitCalculation();
  }, [
    isSupportedRegime,
    resultCalculationSignature,
    selectedCalculationRequestSignature,
    selectedRegime,
    status,
    errors.length,
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
    await submitCalculation({ force: true });
  }

  return {
    assumptionItems,
    detailCards,
      displayStatus,
      displayedSources,
    formProps: {
      ageBracket,
      childrenCount,
      childrenCountNumber,
      childrenCountOptions,
      childrenUnderThreeCount,
      childrenUnderThreeOptions,
      currencyCode: countryCurrencyCode,
      deductibleExpenses,
      disabilityLevel,
      errors,
      grossIncome,
      incomeLabel,
      inputCurrencyCode: selectedInputCurrencyCode,
      inputCurrencyOptions,
      isCalculating,
      isSupportedRegime,
      onAgeBracketChange: handleAgeBracketChange,
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
        prepareAutoRefresh();
      },
      onInputCurrencyChange: (event) => {
        setSelectedInputCurrencyCode(event.target.value);
        prepareAutoRefresh();
      },
      onRegionChange: handleRegionChange,
      onRegimeControlChange: handleRegimeControlChange,
      onSalaryPeriodChange: (nextSalaryPeriod) => {
        setSalaryPeriod(nextSalaryPeriod);
        prepareAutoRefresh();
      },
      onSubmit: handleSubmit,
      onTaxYearChange: handleTaxYearChange,
      periodLabel,
      profileOptions,
      regimeControls: visibleRegimeControls,
      regimeControlValues,
      regionOptions,
      salaryPeriod,
      selectedCategory,
      selectedRegime,
      selectedRegion,
      selectedTaxYear,
      showDeductibleExpenses,
      showPersonalReliefFields,
      showChildrenCountField: false,
      showChildrenUnderThreeField: false,
      taxYearOptions
    },
    headlineMetrics,
    selectedRegime,
    selectedTaxYear
  };
}
