# Consultar fuentes independientes de flora peruana

`flora_match()` devuelve una fila por nombre y fuente. `presencia`
afirma inclusión únicamente en la edición consultada; una coincidencia
aproximada permanece como candidata hasta su revisión.

## Usage

``` r
flora_match(
  x,
  name_col = NULL,
  fuentes = c("cites", "endemismo_actual", "libro_rojo", "ds043"),
  modo = c("exploratorio", "estricto")
)
```

## Arguments

- x:

  Vector de nombres (o factor) o tabla con una columna de nombres.

- name_col:

  Nombre de la columna cuando `x` es una tabla. Si se omite, se reconoce
  una columna usual o la única columna disponible.

- fuentes:

  Subconjunto de `"cites"`, `"endemismo_actual"`, `"libro_rojo"` y
  `"ds043"`.

- modo:

  `"exploratorio"` (predeterminado) o `"estricto"`. El modo exploratorio
  permite las distancias propias de cada paquete, pero no confirma
  automáticamente sus candidatos.

## Value

Tibble largo de evidencia. `status_fuente` contiene solo valores
confirmados; `status_candidato` conserva valores pendientes de revisión.

## Examples

``` r
flora_match("Aa aurantiaca", fuentes = "cites")
#> # A tibble: 1 × 16
#>   indice_entrada nombre_original fuente edicion          paquete_version
#>            <int> <chr>           <chr>  <chr>            <chr>          
#> 1              1 Aa aurantiaca   cites  MINAM flora 2018 0.1.0          
#> # ℹ 11 more variables: nombre_coincidente <chr>, nombre_aceptado <chr>,
#> #   nombre_candidato <chr>, tipo_coincidencia <chr>, evaluacion <chr>,
#> #   distancia <dbl>, presencia <lgl>, status_fuente <chr>,
#> #   status_candidato <chr>, id_registro <chr>, referencia <chr>
```
