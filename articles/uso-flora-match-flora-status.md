# Uso Integrado de flora_match() y flora_status()

## 1. Introducción y Marco Normativo

En estudios de biodiversidad vegetal, consultoría ambiental (Líneas Base
de Flora para EIA, DIA, PMA), peritajes forestales y proyectos de
conservación en el Perú, botánicos e investigadores contrastan
rutinariamente listados de especies frente a cuatro fuentes oficiales e
independientes:

1.  **Comercio Internacional (CITES Flora):** Apéndices I, II y III del
    Ministerio del Ambiente (`citesperu` / MINAM 2018). Regula el
    comercio internacional y no certifica por sí solo residencia
    exclusiva ni endemismo.
2.  **Endemismo Actual:** Catálogo de taxones vasculares endémicos del
    Perú (`ppendemic`), basado en el catálogo mundial *World Checklist
    of Vascular Plants* (WCVP V-16, 2026, \>8000 registros).
3.  **Libro Rojo Histórico:** *Libro Rojo de las Plantas Endémicas del
    Perú* (`redbookperu` / León et al., 2006, Revista Peruana de
    Biología), que aporta categorizaciones UICN técnicas y actualización
    taxonómica. No confiere protección legal vinculante.
4.  **Categorización Oficial de Amenaza:** Especies amenazadas de flora
    silvestre legalmente protegidas bajo el Decreto Supremo N°
    043-2006-AG (`peruflorads43`: Peligro Crítico CR, En Peligro EN,
    Vulnerable VU, Casi Amenazado NT), con correspondencias entre
    nombres originales y actualizados.

El metapaquete **`peruflora`** armoniza este ecosistema botánico y
provee dos funciones principales de consulta cruzada: \*
**[`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md)**:
Consulta detallada con formato largo (una fila por nombre y fuente) que
preserva la evidencia, procedencia y estado de incertidumbre. \*
**[`flora_status()`](https://paulesantos.github.io/peruflora/reference/flora_status.md)**:
Resumen tabular compacto (una fila por nombre de entrada) ideal para
informes técnicos, matrices de evaluación y líneas base.

------------------------------------------------------------------------

## 2. Configuración y Diagnóstico del Entorno

Al cargar `peruflora`, el metapaquete adjunta automáticamente los cuatro
paquetes especializados:

``` r

library(peruflora)
```

Para verificar las fuentes y versiones de las bases de datos integradas,
usa
[`flora_fuentes()`](https://paulesantos.github.io/peruflora/reference/flora_fuentes.md):

``` r

flora_fuentes()
#> # A tibble: 4 × 5
#>   fuente           paquete       edicion              referencia paquete_version
#>   <chr>            <chr>         <chr>                <chr>      <chr>          
#> 1 cites            citesperu     MINAM flora 2018     cites_flo… 0.1.0          
#> 2 endemismo_actual ppendemic     WCVP V-16 (2026-06-… ppendemic… 0.2.2          
#> 3 libro_rojo       redbookperu   Libro Rojo 2006      redbook_s… 0.1.0          
#> 4 ds043            peruflorads43 D. S. 043-2006-AG    original … 0.2.3
```

Y para comprobar el estado y posibles conflictos de funciones en la
sesión:

``` r

peruflora_sitrep()
```

------------------------------------------------------------------------

## 3. Evidencia Detallada con `flora_match()`

[`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md)
toma un vector de nombres científicos (o una tabla) y consulta las
cuatro fuentes independientes devolviendo una fila por cada combinación
de taxón y fuente.

Evaluemos un conjunto representativo de flora peruana:

``` r

nombres <- c(
  "Swietenia macrophylla", # Caoba (CITES II, D.S. 043 VU)
  "Aa aurantiaca",         # Orquídea endémica (CITES II, WCVP Endemic, Libro Rojo)
  "Sanchezia ovata",       # Acantácea endémica (Libro Rojo)
  "Cattleya maxima",       # Orquídea amenazada (CITES II, D.S. 043 CR)
  "Persea americana"       # Palto (cultivo común, no listado)
)

evidencia <- flora_match(nombres)
evidencia[, c("indice_entrada", "nombre_original", "fuente", "evaluacion", "status_fuente", "status_candidato")]
#> # A tibble: 20 × 6
#>    indice_entrada nombre_original       fuente          evaluacion status_fuente
#>             <int> <chr>                 <chr>           <chr>      <chr>        
#>  1              1 Swietenia macrophylla cites           confirmado II           
#>  2              2 Aa aurantiaca         cites           confirmado II           
#>  3              3 Sanchezia ovata       cites           sin_coinc… NA           
#>  4              4 Cattleya maxima       cites           confirmado II           
#>  5              5 Persea americana      cites           sin_coinc… NA           
#>  6              1 Swietenia macrophylla endemismo_actu… sin_coinc… NA           
#>  7              2 Aa aurantiaca         endemismo_actu… confirmado Endemic      
#>  8              3 Sanchezia ovata       endemismo_actu… sin_coinc… NA           
#>  9              4 Cattleya maxima       endemismo_actu… sin_coinc… NA           
#> 10              5 Persea americana      endemismo_actu… sin_coinc… NA           
#> 11              1 Swietenia macrophylla libro_rojo      sin_coinc… NA           
#> 12              2 Aa aurantiaca         libro_rojo      sin_coinc… NA           
#> 13              3 Sanchezia ovata       libro_rojo      confirmado endemic      
#> 14              4 Cattleya maxima       libro_rojo      sin_coinc… NA           
#> 15              5 Persea americana      libro_rojo      sin_coinc… NA           
#> 16              1 Swietenia macrophylla ds043           confirmado VU           
#> 17              2 Aa aurantiaca         ds043           sin_coinc… NA           
#> 18              3 Sanchezia ovata       ds043           sin_coinc… NA           
#> 19              4 Cattleya maxima       ds043           confirmado CR           
#> 20              5 Persea americana      ds043           sin_coinc… NA           
#> # ℹ 1 more variable: status_candidato <chr>
```

La columna `evaluacion` distingue: - `"confirmado"`: coincidencia exacta
o sinónimo oficial validado en la fuente. - `"requiere_revision"`:
coincidencia aproximada o por homonimia pendiente de validación
manual. - `"ambiguo"`: el nombre corresponde a más de un taxón en la
fuente. - `"sin_coincidencia"`: el taxón no figura en la edición
consultada de esa fuente.

------------------------------------------------------------------------

## 4. Resumen Ejecutivo con `flora_status()`

Para generar una tabla consolidada con una fila por taxón ingresado, se
utiliza
[`flora_status()`](https://paulesantos.github.io/peruflora/reference/flora_status.md).
Puede invocarse directamente con los nombres o proyectarse a partir del
resultado de
[`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md)
sin recalcular:

``` r

resumen <- flora_status(evidencia)
resumen
#> # A tibble: 5 × 7
#>   indice_entrada nombre_original       cites_apendice endemismo_actual
#>            <int> <chr>                 <chr>          <lgl>           
#> 1              1 Swietenia macrophylla II             FALSE           
#> 2              2 Aa aurantiaca         II             TRUE            
#> 3              3 Sanchezia ovata       NA             FALSE           
#> 4              4 Cattleya maxima       II             FALSE           
#> 5              5 Persea americana      NA             FALSE           
#> # ℹ 3 more variables: libro_rojo_endemico <lgl>, ds043_categoria <chr>,
#> #   requiere_revision <lgl>
```

------------------------------------------------------------------------

## 5. Manejo de Errores Tipográficos y Nombres Aproximados

En campo y en transcripción de herbarios es frecuente encontrar nombres
con ligeras variaciones ortográficas. En modo exploratorio
(predeterminado), `peruflora` tolera distancias de edición y sugiere los
estados candidatos, marcando la fila con `requiere_revision = TRUE`:

``` r

nombres_variaciones <- c(
  "Cattleya maxima",  # Nombre correcto
  "Catleya maxima",   # Falta una 't'
  "Catleya maximma"   # Falta una 't' y sobra una 'm' (2 ediciones)
)

flora_status(nombres_variaciones)
#> # A tibble: 3 × 7
#>   indice_entrada nombre_original cites_apendice endemismo_actual
#>            <int> <chr>           <chr>          <lgl>           
#> 1              1 Cattleya maxima II             FALSE           
#> 2              2 Catleya maxima  II             FALSE           
#> 3              3 Catleya maximma II             FALSE           
#> # ℹ 3 more variables: libro_rojo_endemico <lgl>, ds043_categoria <chr>,
#> #   requiere_revision <lgl>
```

Ambas variantes ortográficas son identificadas y sugeridas en CITES
(`II`) y D.S. 043 (`CR`), señalando claramente
`requiere_revision = TRUE` para su validación manual antes de emitir un
dictamen legal.

------------------------------------------------------------------------

## 6. Evaluación de un Inventario o Tabla de Campo

[`flora_status()`](https://paulesantos.github.io/peruflora/reference/flora_status.md)
y
[`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md)
aceptan tablas de datos (`data.frame` o `tibble`). Si se especifica
`name_col`, se preserva el orden y la posición de cada fila mediante
`indice_entrada`, lo que permite unir los resultados directamente a las
parcelas originales:

``` r

library(dplyr)
library(tibble)

inventario <- tibble(
  parcela = c("P01", "P01", "P02", "P02", "P03"),
  individuo = 1:5,
  nombre_cientifico = c(
    "Aa aurantiaca",
    "Cattleya maxima",
    "Persea americana",
    "Aa aurantiaca",  # registro repetido en otra parcela
    "Catleya maxima"  # error ortográfico
  ),
  individuos_conteo = c(3, 1, 5, 2, 1)
)

estado <- flora_status(inventario, name_col = "nombre_cientifico")

inventario_evaluado <- inventario |>
  mutate(indice_entrada = row_number()) |>
  left_join(select(estado, -nombre_original), by = "indice_entrada")

inventario_evaluado
#> # A tibble: 5 × 10
#>   parcela individuo nombre_cientifico individuos_conteo indice_entrada
#>   <chr>       <int> <chr>                         <dbl>          <int>
#> 1 P01             1 Aa aurantiaca                     3              1
#> 2 P01             2 Cattleya maxima                   1              2
#> 3 P02             3 Persea americana                  5              3
#> 4 P02             4 Aa aurantiaca                     2              4
#> 5 P03             5 Catleya maxima                    1              5
#> # ℹ 5 more variables: cites_apendice <chr>, endemismo_actual <lgl>,
#> #   libro_rojo_endemico <lgl>, ds043_categoria <chr>, requiere_revision <lgl>
```

------------------------------------------------------------------------

## 7. Aplicación Interactiva Shiny

Para usuarios que prefieren una interfaz gráfica o necesitan procesar
inventarios desde archivos Excel (`.xlsx`), `peruflora` incluye la
aplicación Shiny:

``` r

# Iniciar la app Shiny
peruflora::flora_app()
# o también:
peruflora::run_peruflora_app()
```

La app ofrece carga de archivos con detección automática de columnas,
cinco vistas de consulta con filtros interactivos `DT`, tarjetas
métricas KPI y descarga en CSV o Excel.
