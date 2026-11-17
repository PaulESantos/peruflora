# Resumir las consultas de flora peruana

`flora_status()` conserva por separado las cuatro fuentes. Muestra
también los estados candidatos y marca sus filas con
`requiere_revision = TRUE`. Consulte
[`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md)
para distinguir los valores confirmados de los candidatos antes de
usarlos como evidencia.

## Usage

``` r
flora_status(x, ...)
```

## Arguments

- x:

  Nombres o un resultado de
  [`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md).

- ...:

  Argumentos pasados a
  [`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md)
  cuando `x` contiene nombres.

## Value

Tibble con una fila por nombre de entrada.

## Examples

``` r
flora_status("Aa aurantiaca", fuentes = "cites")
#> # A tibble: 1 × 7
#>   indice_entrada nombre_original cites_apendice endemismo_actual
#>            <int> <chr>           <chr>          <lgl>           
#> 1              1 Aa aurantiaca   II             NA              
#> # ℹ 3 more variables: libro_rojo_endemico <lgl>, ds043_categoria <chr>,
#> #   requiere_revision <lgl>
```
