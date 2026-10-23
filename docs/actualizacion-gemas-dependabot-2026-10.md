# Actualización de gemas desde cashflow (Dependabot, octubre 2026)

En cashflow se mezclaron los PRs de Dependabot #47, #50, #56, #62, #63, #64, #65, #66 y #67.
Este documento lista las gemas que cambiaron allá y qué hay que aplicar en puntapie.

Rango comparado en cashflow: `ab44b4f..faa0211` (`Gemfile` y `Gemfile.lock`).

## Qué aplicar en puntapie

Puntapie no tiene `Gemfile.lock`: el `Gemfile.lock` se resuelve al generar cada app con `template.rb`.
Por eso solo importan las gemas fijadas en `Gemfile.tt`. Las dependencias indirectas salen
actualizadas solas en cada `rails new`.

| Gema | `Gemfile.tt` hoy | cashflow ahora | Cambio en `Gemfile.tt` |
|---|---|---|---|
| json | `"~> 2.13"` | `"~> 2.19"` (2.19.9) | `gem "json", "~> 2.19"` (dejar el comentario de json 3.x) |
| sqlite3 | `"2.9.0"` | `"2.9.6"` | `gem "sqlite3", "2.9.6"` |
| rspec-rails | `"6.1.0"` | `"8.0.4"` | `gem "rspec-rails", "8.0.4"` |

Notas:

- **rspec-rails**: puntapie va de 6.1.0 a 8.0.4, un salto más grande que el de cashflow (7.1.1 → 8.0.4).
  rspec-rails 8 pide Rails >= 7.2; la plantilla usa `rails 7.2.3.1`, así que es compatible.
  Conviene generar una app de prueba y correr `bundle exec rspec`, porque `configure_rspec`
  ejecuta `rails g rspec:install` y la salida del generador puede cambiar entre versiones mayores.
- **rubyzip** (3.0.1 → 3.4.0) llega por `selenium-webdriver`. En `Gemfile.tt`, selenium está fijado en
  `4.16.0`; rubyzip se resuelve solo dentro del rango que pide selenium.

## Todas las gemas que cambiaron en cashflow

### Fijadas en el `Gemfile`

| Gema | Antes | Después | PR |
|---|---|---|---|
| json | 2.13.2 (`~> 2.13`) | 2.19.9 (`~> 2.19`) | #63 |
| sqlite3 | 2.9.0 | 2.9.6 | #67 |
| rspec-rails | 7.1.1 | 8.0.4 | #47 |

### Solo en el `Gemfile.lock`

| Gema | Antes | Después | Llega por |
|---|---|---|---|
| bigdecimal | 4.1.2 | 4.1.3 | #47 |
| concurrent-ruby | 1.3.7 | 1.3.8 | #47 |
| crass | 1.0.7 | 1.0.8 | #47 |
| date | 3.5.1 | 3.6.0 | #50 / #62 |
| erb | 6.0.4 | 6.0.7 | #47 |
| io-console | 0.8.2 | 0.9.4 | #47 |
| loofah | 2.25.1 | 2.25.2 | #64 / #66 |
| mail | 2.9.0 | 2.9.1 | #62 |
| net-imap | 0.6.3 | 0.6.8 | #50 / #62 |
| net-protocol | 0.2.2 | 0.4.0 | #50 / #62 |
| net-smtp | 0.5.1 | 0.5.2 | #62 |
| prettyprint | 0.2.0 | 0.2.1 | #47 |
| psych | 5.4.0 | 5.5.0 | #47 |
| rack | 3.2.6 | 3.2.7 | #47 |
| rack-test | 2.2.0 | 2.3.0 | #47 |
| rails-html-sanitizer | 1.7.0 | 1.7.1 | #64 |
| reline | 0.6.3 | 0.7.0 | #47 |
| rexml | 3.4.1 | 3.4.2 | #56 |
| rubyzip | 3.0.1 | 3.4.0 | #65 |
| zeitwerk | 2.8.2 | 2.8.3 | #47 |
