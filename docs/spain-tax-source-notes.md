# Spain Tax Source Notes

## Current implementation status

The live web calculator in this repository currently implements only one scenario:

- country: Spain
- tax year: 2025
- profile: resident employee
- region: Community of Madrid
- taxpayer assumption: single, under 65, no children, no disability, no extra deductions

This narrow scope is intentional. It gives us a traceable first vertical slice before we broaden into self-employed, company, and special-regime calculators for Taxerase.

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

- autonomous communities other than Madrid
- filing jointly
- children, disability, age increases, or regional deductions
- solidarity contributions above the maximum Social Security base
- temporary-contract unemployment rates
- Beckham Law or other special regimes inside the calculator flow
- self-employed or company tax outputs

These are not ignored because they are unimportant. They are deferred because the first delivery goal is a stable, source-backed web vertical slice that can later be exposed through the same internal API contract.
