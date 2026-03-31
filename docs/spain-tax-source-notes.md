# Spain Tax Source Notes

## Current implementation status

The live web calculator in this repository currently implements these common-regime Spain scenarios:

- country: Spain
- tax years: 2024 and 2025
- profiles: resident employee and resident self-employed
- regions: common-regime autonomous communities plus Ceuta and Melilla
- taxpayer assumption: single, under 65, no children, no disability, no extra deductions

This still remains a constrained scope. It gives Taxerase a traceable, source-backed common-regime calculator before we expose foral territories, company flows, or special regimes.

## Official sources used for the first implementation

### Employee income tax

- AEAT 2025 state IRPF scale:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-estatal.html
- AEAT 2025 Madrid regional IRPF scale:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-autonomico/comunidad-madrid.html
- AEAT 2025 Madrid taxpayer minimums:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c14-adecuacion-impuesto-circunstancias-personales/minimo-autonomico-personal-familiar/comunidad-madrid-importes-minimo-personal-familiar.html
- AEAT 2025 deductible employee work expenses:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c03-rendimientos-trabajo/rendimiento-neto-trabajo-integrar-base-imponible/fase-2-determinacion-rendimiento-neto/gastos-deducibles-articulo-19-ley-irpf.html
- AEAT 2025 new work-income deduction guidance:
  https://sede.agenciatributaria.gob.es/Sede/en_gb/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/guia-principales-novedades/deducciones-cuota-liquida-total.html

### Employee Social Security

- Seguridad Social 2025 employee contribution rates:
  https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10957/9932/4315/4316?changeLanguage=es
- Seguridad Social 2025 contribution bases:
  https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10957/9932/4327

## Official sources researched for the next slices

### Common-regime Spain 2024

- AEAT 2024 state IRPF scale:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-estatal.html
- AEAT 2024 regional IRPF scales index:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-autonomico.html
- AEAT 2024 taxpayer minimum comparison:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c14-adecuacion-impuesto-circunstancias-personales/minimo-autonomico-personal-familiar/cuadro-minimos-personales-familiares-estatal-autonomicos.html
- AEAT 2024 deductible employee work expenses:
  https://sede.agenciatributaria.gob.es/Sede/gl_es/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c03-rendimientos-trabajo/rendimiento-neto-trabajo-integrar-base-imponible/fase-2-determinacion-rendimiento-neto/gastos-deducibles-articulo-19-ley-irpf.html
- AEAT 2024 reduction for work income:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c03-rendimientos-trabajo/rendimiento-neto-trabajo-integrar-base-imponible/fase-3-determinacion-rendimiento-neto-reducido.html
- Seguridad Social 2024 employee contribution rates:
  https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10957/9932/4315/4316?changeLanguage=es
- Seguridad Social 2024 employee contribution bases:
  https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10957/9932/4327
- Seguridad Social 2024 RETA summary:
  https://www.seg-social.es/descarga/es/Tabla_Autonomo
- AEAT 2024 difficult-to-justify expense rule for simplified direct estimation:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c07-rendimientos-actividades-economicas-estimacion-directa/fase-1-determinacion-rendimiento-neto/gastos-fiscalmente-deducibles/provisiones.html

The 2024 common-regime source set is materially complete for the current calculator scope:

- employee state and regional IRPF scales
- regional taxpayer minimums
- employee Social Security rates and bases
- self-employed RETA bands
- simplified direct-estimation 5% difficult-to-justify deduction cap and rule

This 2024 source set is now wired into the seeded common-regime calculator. The separate foral territories still need their own formula work.

### Self-employed

- AEAT 2025 direct-estimation manual:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c07-rendimientos-actividades-economicas-estimacion-directa.html
- Seguridad Social RETA contribution table:
  https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10724/1320/1322/boni6

### Companies

- AEAT corporate tax rates:
  https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-ayuda-presentacion/modelo-200-2018/05-tipo-gravamen/5_02-tipos-impositivos-vigentes.html

### Special regimes

- AEAT regime for workers displaced to Spain:
  https://sede.agenciatributaria.gob.es/Sede/eu_es/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/regimen-fiscal-especial-aplicable-trabajadores.html

## Deliberate omissions in v1

The live calculator does not yet model:

- filing jointly
- children, disability, age increases, or regional deductions
- solidarity contributions above the maximum Social Security base
- temporary-contract unemployment rates
- Beckham Law or other special regimes inside the calculator flow
- company tax outputs
- foral territory calculations for Álava, Bizkaia, Gipuzkoa, or Navarre

These are not ignored because they are unimportant. They are deferred because the first delivery goal is a stable, source-backed web vertical slice that can later be exposed through the same internal API contract.

## Public calculator exposure policy

As of March 31, 2026, the public web calculator should expose only fully implemented, officially sourced combinations.

- AEAT currently surfaces complete manuals for both `Renta 2024` and `Renta 2025`, which is enough for the current common-regime implementations for those years.
-   https://sede.agenciatributaria.gob.es/
- Seguridad Social already publishes 2026 RETA contribution bands, but that does not by itself provide a complete 2026 Spain income-tax calculator.
-   https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10724/1320/1322
- Some foral territories also publish official 2025 or 2026 tax updates, but the data shape and formulas are jurisdiction-specific and should not be exposed until each calculator is implemented end to end.
-   https://www.bizkaia.eus/es/web/comunicacion/noticias/-/news/detailView/bizkaia-tiene-nueva-tabla-de-retenciones-en-irpf-con-efectos-a-1-de-julio-de-2025
-   https://www.navarra.es/es/-/nota-prensa/aprobada-la-modificacion-del-reglamento-del-irpf-que-exime-de-hacer-declaracion-a-las-personas-con-rentas-de-trabajo-inferiores-a-17-000-euros-anuales?back=true&pageBackId=7574878

Because of that, unsupported year and region combinations remain stored in the rules database for future work, but they should stay hidden from the public calculator instead of appearing as research-only options. As of March 31, 2026, that means the public Spain calculator exposes common-regime `2024` and `2025`, while `2026` and the foral jurisdictions remain off-screen until their formulas are implemented end to end.
