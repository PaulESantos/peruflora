
<!-- README.md is generated from README.Rmd. Please edit that file -->

# peruflora

`peruflora` consulta cuatro fuentes independientes de flora peruana: el
listado CITES de flora del MINAM (2018), los taxones endémicos aceptados
de `ppendemic` (WCVP V-16), el Libro Rojo de plantas endémicas (2006) y
el D. S. 043-2006-AG. Mantiene el estado, la edición y la incertidumbre
de cada fuente.

## Instalación

Esta es una versión de desarrollo. `peruflora` requiere `redbookperu`
0.1.0 o posterior, que todavía no está disponible en CRAN. Instale
primero la versión de desarrollo de `redbookperu` desde GitHub y después
`peruflora`:

``` r
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pak("PaulESantos/redbookperu")
pak::pak("PaulESantos/peruflora")

packageVersion("redbookperu") # debe ser >= 0.1.0
```

La versión 0.0.3 de `redbookperu` disponible en CRAN no incluye
`match_redbook_names()`, función que usa `peruflora`. Cuando se publique
una versión compatible en CRAN, se podrá instalar `peruflora` sin este
paso previo.

Los cuatro paquetes especializados también se pueden instalar y utilizar
por separado. `library(peruflora)` los adjunta en la sesión; sus
funciones siguen disponibles con `paquete::funcion()`. Al cargarse,
`peruflora` muestra los paquetes recién adjuntados con sus versiones y
avisa si alguna función queda enmascarada. Puede silenciar este aviso
con `suppressPackageStartupMessages(library(peruflora))` o con la opción
`options(peruflora.quiet = TRUE)`.

## Consulta integrada

``` r
library(peruflora)

nombres <- c("Swietenia macrophylla", "Aa aurantiaca",
             "Sanchezia ovata", "Cattleya maxima", "Persea americana")

evidencia <- flora_match(nombres)
evidencia
flora_status(evidencia)
```

`flora_match()` devuelve una fila por nombre y fuente. `evaluacion`
distingue `confirmado`, `sin_coincidencia`, `requiere_revision`,
`ambiguo` y `entrada_invalida`. `presencia = FALSE` significa ausencia
**en la edición consultada**. Los nombres aproximados se muestran en
`nombre_candidato` y su estado en `status_candidato`, sin trasladarlos a
`status_fuente`. El resumen `flora_status()` muestra también esos
estados candidatos y activa `requiere_revision`; consulte el detalle
antes de utilizarlos como confirmados.

``` r
flora_match("Catleya maxima", modo = "exploratorio")
flora_status(c("Aa aurantiaca", "Persea americana"))
flora_fuentes()
```

El modo `exploratorio` (predeterminado) permite sugerencias, siempre
marcadas para revisión. En modo `estricto`, CITES, WCVP y Libro Rojo
usan búsqueda exacta; la salida del D. S. 043 se comprueba además contra
el nombre ingresado porque su API no permite desactivar la búsqueda
aproximada. `sp.`, `spp.` y nombres de solo género quedan como
identificaciones incompletas.

Por ejemplo, `flora_status(c("Cattleya maxima", "Catleya maxima"))`
muestra el mismo apéndice CITES y la misma categoría D. S. 043 para
ambos nombres. Solo la segunda fila indica `requiere_revision = TRUE`;
los valores de esa fila son candidatos y se pueden auditar con
`flora_match()`.

## Evaluar un inventario

`flora_status()` acepta tablas con otras columnas si se indica
`name_col`. El resultado conserva una fila por registro, incluso cuando
un nombre se repite. `indice_entrada` corresponde a la posición de cada
fila del inventario, por lo que permite unir el resumen sin mezclar
registros repetidos.

``` r
library(peruflora)
library(dplyr)
library(tibble)

inventario <- tibble(
  indice_entrada = 1:5,
  parcela = c("P01", "P01", "P02", "P02", "P03"),
  nombre_cientifico = c(
    "Aa aurantiaca",
    "Cattleya maxima",
    "Persea americana",
    "Aa aurantiaca",  # registro repetido
    "Catleya maxima"  # posible error de escritura
  ),
  abundancia = c(2, 1, 4, 3, 1)
)
inventario

estado <- flora_status(
  inventario,
  name_col = "nombre_cientifico"
)
estado

inventario_evaluado <- inventario |>
  left_join(
    select(estado, -nombre_original),
    by = "indice_entrada"
  )

inventario_evaluado
```

La fila con `Catleya maxima` conserva las categorías sugeridas en el
resumen, pero `requiere_revision = TRUE` indica que son candidatas. Para
revisar la evidencia de ese registro, use
`flora_match(inventario, name_col = "nombre_cientifico")`.

## Paquetes y procedencia

| Paquete | Información consultada |
|----|----|
| `citesperu` | Solo flora, edición MINAM 2018; apéndice CITES |
| `ppendemic` | Endemismo de taxones aceptados, WCVP V-16 |
| `redbookperu` | Registro histórico del Libro Rojo de 2006 |
| `peruflorads43` | Categoría del D. S. 043-2006-AG, nombres originales y actualizados |

`peruflora_deps()`, `peruflora_sitrep()` y `peruflora_conflicts()`
ayudan a inspeccionar versiones y posibles conflictos en la sesión. Cite
también cada paquete y fuente que utilice en un análisis. El Libro Rojo,
la lista WCVP, el decreto y CITES responden preguntas distintas; el
resumen no los combina en una categoría única de conservación.
