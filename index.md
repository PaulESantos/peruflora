# peruflora

`peruflora` consulta cuatro fuentes independientes de flora peruana: el
listado CITES de flora del MINAM (2018), los taxones endémicos aceptados
de `ppendemic` (WCVP V-16), el Libro Rojo de plantas endémicas (2006) y
el D. S. 043-2006-AG. Mantiene el estado, la edición y la incertidumbre
de cada fuente.

## Instalación

La primera versión de `peruflora` es 0.1.0. Hasta su publicación en
CRAN, instálela desde GitHub. Requiere `redbookperu` 0.1.0 o posterior,
disponible en CRAN:

``` r

if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
install.packages("redbookperu")
pak::pak("PaulESantos/peruflora")

packageVersion("redbookperu") # debe ser >= 0.1.0
```

Si ya tiene instalada una versión anterior de `redbookperu`, actualícela
desde CRAN antes de cargar `peruflora`. El adaptador usa
[`redbookperu::match_redbook_names()`](https://paulesantos.github.io/redbookperu/reference/match_redbook_names.html)
de la versión 0.1.0 y fija el parser `"legacy"` para mantener resultados
reproducibles con independencia de si `wcvpmatch` está instalado.

Los cuatro paquetes especializados también se pueden instalar y utilizar
por separado.
[`library(peruflora)`](https://github.com/PaulESantos/peruflora) los
adjunta en la sesión; sus funciones siguen disponibles con
`paquete::funcion()`. Al cargarse, `peruflora` muestra los paquetes
recién adjuntados con sus versiones y avisa si alguna función queda
enmascarada. Puede silenciar este aviso con
`suppressPackageStartupMessages(library(peruflora))` o con la opción
`options(peruflora.quiet = TRUE)`.

## Aplicación interactiva (Shiny)

`peruflora` incluye una aplicación interactiva Shiny opcional para
consultar, armonizar y auditar lotes de nombres científicos sin
necesidad de escribir código.

### Instalación de dependencias opcionales

``` r

install.packages(c("shiny", "DT", "callr", "later"))
# Opcional: para importación y descarga en Excel (.xlsx)
install.packages(c("readxl", "writexl"))
```

### Iniciar la aplicación

``` r

# Iniciar con el alias canónico
peruflora::flora_app()

# O con opciones avanzadas de host y puerto
peruflora::run_peruflora_app(host = "127.0.0.1", port = 3838)
```

También puedes ejecutarla directamente desde el archivo `app.R` en la
raíz del repositorio, o mediante:

``` r

shiny::runApp(system.file("app", package = "peruflora"))
```

### Capacidades principales

1.  **Ingesta flexible de datos**:
    - Pega nombres directamente en el área de texto o carga archivos en
      formatos **TXT**, **CSV** (con detección automática de comas o
      punto y coma de Excel en español), **TSV**, **XLS** o **XLSX**.
    - Reconocimiento automático de columnas taxonómicas
      (`scientific_name`, `nombre_cientifico`, `species`, `name`, etc.).
    - Admite hasta 10 000 nombres por lote con validación previa de
      caracteres y cardinalidad.
2.  **Cinco vistas especializadas**:
    - **Consulta integrada**: Ejecuta
      [`flora_status()`](https://paulesantos.github.io/peruflora/reference/flora_status.md)
      (resumen) o
      [`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md)
      (evidencia detallada) cruzando simultáneamente las cuatro fuentes.
      Permite alternar entre modo *exploratorio* (con candidatos
      sugeridos) y modo *estricto*.
    - **CITES Flora**: Consulta los Apéndices I, II y III del listado
      oficial MINAM (2018), con parámetros configurables de distancia de
      edición, coincidencia por sinónimos o género.
    - **Endemismo actual**: Búsqueda jerárquica en el catálogo de
      plantas vasculares endémicas del Perú de `ppendemic` (basado en
      WCVP V-16, con más de 8000 registros).
    - **Libro Rojo**: Consulta contra el Libro Rojo de las Plantas
      Endémicas del Perú (León et al., 2006, `redbookperu`) con
      correspondencias taxonómicas actualizadas y categorías UICN
      técnicas.
    - **D.S. 043-2006-AG**: Verificación normativa de especies
      legalmente protegidas bajo el Decreto Supremo N° 043-2006-AG
      (`peruflorads43`), reconciliando taxonomía original y actualizada.
3.  **Ejecución asíncrona y cancelación**:
    - Las consultas se ejecutan en un subproceso en segundo plano
      (`callr` y `later`), manteniendo la interfaz responsiva y
      permitiendo cancelar la búsqueda en cualquier momento. Si el
      entorno no soporta procesos secundarios, conmuta automáticamente a
      modo síncrono.
4.  **Auditoría visual y métricas**:
    - Tarjetas KPI interactivas con recuentos y porcentajes de
      coincidencia por fuente.
    - Alerta visual destacada cuando existen filas que requieren
      revisión manual (`review_flag = TRUE`).
    - Tabla interactiva (`DT`) en español con ordenación, paginación y
      búsqueda facetada por columnas.
    - Ficha de detalle para inspeccionar exhaustivamente cualquier
      registro seleccionado.
5.  **Exportación reproducible**:
    - Descarga de resultados en formatos **CSV** (UTF-8) o **Excel
      (XLSX)**, preservando el archivo y número de fila de origen,
      estado de revisión y observaciones.

## Consulta integrada

``` r

library(peruflora)
#> ── Adjuntando paquetes principales de peruflora ───────────────────────────────────────────────────────────────────────── peruflora 0.1.0 ──
#> ✔ citesperu     0.1.0     ✔ ppendemic     0.2.2
#> ✔ peruflorads43 0.2.3     ✔ redbookperu   0.1.0
#> ℹ Use flora_match() para consultar las cuatro fuentes.

nombres <- c("Swietenia macrophylla", "Aa aurantiaca",
             "Sanchezia ovata", "Cattleya maxima", "Persea americana")

evidencia <- flora_match(nombres)
evidencia
#> # A tibble: 20 × 16
#>    indice_entrada nombre_original       fuente           edicion                paquete_version nombre_coincidente    nombre_aceptado      
#>             <int> <chr>                 <chr>            <chr>                  <chr>           <chr>                 <chr>                
#>  1              1 Swietenia macrophylla cites            MINAM flora 2018       0.1.0           Swietenia macrophylla Swietenia macrophylla
#>  2              2 Aa aurantiaca         cites            MINAM flora 2018       0.1.0           Aa aurantiaca         Aa aurantiaca        
#>  3              3 Sanchezia ovata       cites            MINAM flora 2018       0.1.0           <NA>                  <NA>                 
#>  4              4 Cattleya maxima       cites            MINAM flora 2018       0.1.0           Cattleya maxima       Cattleya maxima      
#>  5              5 Persea americana      cites            MINAM flora 2018       0.1.0           <NA>                  <NA>                 
#>  6              1 Swietenia macrophylla endemismo_actual WCVP V-16 (2026-06-04) 0.2.2           <NA>                  <NA>                 
#>  7              2 Aa aurantiaca         endemismo_actual WCVP V-16 (2026-06-04) 0.2.2           Aa aurantiaca         Aa aurantiaca        
#>  8              3 Sanchezia ovata       endemismo_actual WCVP V-16 (2026-06-04) 0.2.2           <NA>                  <NA>                 
#>  9              4 Cattleya maxima       endemismo_actual WCVP V-16 (2026-06-04) 0.2.2           <NA>                  <NA>                 
#> 10              5 Persea americana      endemismo_actual WCVP V-16 (2026-06-04) 0.2.2           <NA>                  <NA>                 
#> 11              1 Swietenia macrophylla libro_rojo       Libro Rojo 2006        0.1.0           <NA>                  <NA>                 
#> 12              2 Aa aurantiaca         libro_rojo       Libro Rojo 2006        0.1.0           <NA>                  <NA>                 
#> 13              3 Sanchezia ovata       libro_rojo       Libro Rojo 2006        0.1.0           Sanchezia capitata    Sanchezia ovata      
#> 14              4 Cattleya maxima       libro_rojo       Libro Rojo 2006        0.1.0           <NA>                  <NA>                 
#> 15              5 Persea americana      libro_rojo       Libro Rojo 2006        0.1.0           <NA>                  <NA>                 
#> 16              1 Swietenia macrophylla ds043            D. S. 043-2006-AG      0.2.3           Swietenia macrophylla <NA>                 
#> 17              2 Aa aurantiaca         ds043            D. S. 043-2006-AG      0.2.3           <NA>                  <NA>                 
#> 18              3 Sanchezia ovata       ds043            D. S. 043-2006-AG      0.2.3           <NA>                  <NA>                 
#> 19              4 Cattleya maxima       ds043            D. S. 043-2006-AG      0.2.3           Cattleya maxima       <NA>                 
#> 20              5 Persea americana      ds043            D. S. 043-2006-AG      0.2.3           <NA>                  <NA>                 
#>    nombre_candidato tipo_coincidencia evaluacion       distancia presencia status_fuente status_candidato id_registro
#>    <chr>            <chr>             <chr>                <dbl> <lgl>     <chr>         <chr>            <chr>      
#>  1 <NA>             exact             confirmado               0 TRUE      II            <NA>             292        
#>  2 <NA>             exact             confirmado               0 TRUE      II            <NA>             293        
#>  3 <NA>             unmatched         sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#>  4 <NA>             exact             confirmado               0 TRUE      II            <NA>             488        
#>  5 <NA>             unmatched         sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#>  6 <NA>             <NA>              sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#>  7 <NA>             exact             confirmado               0 TRUE      Endemic       <NA>             <NA>       
#>  8 <NA>             <NA>              sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#>  9 <NA>             <NA>              sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#> 10 <NA>             <NA>              sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#> 11 <NA>             no_match          sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#> 12 <NA>             no_match          sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#> 13 <NA>             exact             confirmado               0 TRUE      endemic       <NA>             32SACA     
#> 14 <NA>             no_match          sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#> 15 <NA>             no_match          sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#> 16 <NA>             exact             confirmado               0 TRUE      VU            <NA>             <NA>       
#> 17 <NA>             <NA>              sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#> 18 <NA>             <NA>              sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#> 19 <NA>             exact             confirmado               0 TRUE      CR            <NA>             <NA>       
#> 20 <NA>             <NA>              sin_coincidencia        NA FALSE     <NA>          <NA>             <NA>       
#>    referencia                         
#>    <chr>                              
#>  1 cites_flora_peru_2018              
#>  2 cites_flora_peru_2018              
#>  3 cites_flora_peru_2018              
#>  4 cites_flora_peru_2018              
#>  5 cites_flora_peru_2018              
#>  6 ppendemic_tab16                    
#>  7 ppendemic_tab16                    
#>  8 ppendemic_tab16                    
#>  9 ppendemic_tab16                    
#> 10 ppendemic_tab16                    
#> 11 redbook_sp_data                    
#> 12 redbook_sp_data                    
#> 13 redbook_sp_data                    
#> 14 redbook_sp_data                    
#> 15 redbook_sp_data                    
#> 16 original y nomenclatura actualizada
#> 17 original y nomenclatura actualizada
#> 18 original y nomenclatura actualizada
#> 19 original y nomenclatura actualizada
#> 20 original y nomenclatura actualizada
flora_status(evidencia)
#> # A tibble: 5 × 7
#>   indice_entrada nombre_original       cites_apendice endemismo_actual libro_rojo_endemico ds043_categoria requiere_revision
#>            <int> <chr>                 <chr>          <lgl>            <lgl>               <chr>           <lgl>            
#> 1              1 Swietenia macrophylla II             FALSE            FALSE               VU              FALSE            
#> 2              2 Aa aurantiaca         II             TRUE             FALSE               <NA>            FALSE            
#> 3              3 Sanchezia ovata       <NA>           FALSE            TRUE                <NA>            FALSE            
#> 4              4 Cattleya maxima       II             FALSE            FALSE               CR              FALSE            
#> 5              5 Persea americana      <NA>           FALSE            FALSE               <NA>            FALSE
```

[`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md)
devuelve una fila por nombre y fuente. `evaluacion` distingue
`confirmado`, `sin_coincidencia`, `requiere_revision`, `ambiguo` y
`entrada_invalida`. `presencia = FALSE` significa ausencia **en la
edición consultada**. Los nombres aproximados se muestran en
`nombre_candidato` y su estado en `status_candidato`, sin trasladarlos a
`status_fuente`. El resumen
[`flora_status()`](https://paulesantos.github.io/peruflora/reference/flora_status.md)
muestra también esos estados candidatos y activa `requiere_revision`;
consulte el detalle antes de utilizarlos como confirmados.

``` r

flora_match("Catleya maxima", modo = "exploratorio")
#> # A tibble: 4 × 16
#>   indice_entrada nombre_original fuente           edicion                paquete_version nombre_coincidente nombre_aceptado nombre_candidato
#>            <int> <chr>           <chr>            <chr>                  <chr>           <chr>              <chr>           <chr>           
#> 1              1 Catleya maxima  cites            MINAM flora 2018       0.1.0           <NA>               <NA>            Cattleya maxima 
#> 2              1 Catleya maxima  endemismo_actual WCVP V-16 (2026-06-04) 0.2.2           <NA>               <NA>            <NA>            
#> 3              1 Catleya maxima  libro_rojo       Libro Rojo 2006        0.1.0           <NA>               <NA>            <NA>            
#> 4              1 Catleya maxima  ds043            D. S. 043-2006-AG      0.2.3           <NA>               <NA>            Cattleya maxima 
#>   tipo_coincidencia evaluacion        distancia presencia status_fuente status_candidato id_registro referencia                         
#>   <chr>             <chr>                 <dbl> <lgl>     <chr>         <chr>            <chr>       <chr>                              
#> 1 fuzzy             requiere_revision         1 NA        <NA>          II               488         cites_flora_peru_2018              
#> 2 <NA>              sin_coincidencia          1 FALSE     <NA>          <NA>             <NA>        ppendemic_tab16                    
#> 3 no_match          sin_coincidencia         NA FALSE     <NA>          <NA>             <NA>        redbook_sp_data                    
#> 4 approximate       requiere_revision        NA NA        <NA>          CR               <NA>        original y nomenclatura actualizada
flora_status(c("Aa aurantiaca", "Persea americana"))
#> # A tibble: 2 × 7
#>   indice_entrada nombre_original  cites_apendice endemismo_actual libro_rojo_endemico ds043_categoria requiere_revision
#>            <int> <chr>            <chr>          <lgl>            <lgl>               <chr>           <lgl>            
#> 1              1 Aa aurantiaca    II             TRUE             FALSE               <NA>            FALSE            
#> 2              2 Persea americana <NA>           FALSE            FALSE               <NA>            FALSE
flora_fuentes()
#> # A tibble: 4 × 5
#>   fuente           paquete       edicion                referencia                          paquete_version
#>   <chr>            <chr>         <chr>                  <chr>                               <chr>          
#> 1 cites            citesperu     MINAM flora 2018       cites_flora_peru_2018               0.1.0          
#> 2 endemismo_actual ppendemic     WCVP V-16 (2026-06-04) ppendemic_tab16                     0.2.2          
#> 3 libro_rojo       redbookperu   Libro Rojo 2006        redbook_sp_data                     0.1.0          
#> 4 ds043            peruflorads43 D. S. 043-2006-AG      original y nomenclatura actualizada 0.2.3
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
[`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md).

## Evaluar un inventario

[`flora_status()`](https://paulesantos.github.io/peruflora/reference/flora_status.md)
acepta tablas con otras columnas si se indica `name_col`. El resultado
conserva una fila por registro, incluso cuando un nombre se repite.
`indice_entrada` corresponde a la posición de cada fila del inventario,
por lo que permite unir el resumen sin mezclar registros repetidos.

``` r

library(peruflora)
library(dplyr)
#> 
#> Adjuntando el paquete: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
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
#> # A tibble: 5 × 4
#>   indice_entrada parcela nombre_cientifico abundancia
#>            <int> <chr>   <chr>                  <dbl>
#> 1              1 P01     Aa aurantiaca              2
#> 2              2 P01     Cattleya maxima            1
#> 3              3 P02     Persea americana           4
#> 4              4 P02     Aa aurantiaca              3
#> 5              5 P03     Catleya maxima             1

estado <- flora_status(
  inventario,
  name_col = "nombre_cientifico"
)
estado
#> # A tibble: 5 × 7
#>   indice_entrada nombre_original  cites_apendice endemismo_actual libro_rojo_endemico ds043_categoria requiere_revision
#>            <int> <chr>            <chr>          <lgl>            <lgl>               <chr>           <lgl>            
#> 1              1 Aa aurantiaca    II             TRUE             FALSE               <NA>            FALSE            
#> 2              2 Cattleya maxima  II             FALSE            FALSE               CR              FALSE            
#> 3              3 Persea americana <NA>           FALSE            FALSE               <NA>            FALSE            
#> 4              4 Aa aurantiaca    II             TRUE             FALSE               <NA>            FALSE            
#> 5              5 Catleya maxima   II             FALSE            FALSE               CR              TRUE

inventario_evaluado <- inventario |>
  left_join(
    select(estado, -nombre_original),
    by = "indice_entrada"
  )

inventario_evaluado
#> # A tibble: 5 × 9
#>   indice_entrada parcela nombre_cientifico abundancia cites_apendice endemismo_actual libro_rojo_endemico ds043_categoria requiere_revision
#>            <int> <chr>   <chr>                  <dbl> <chr>          <lgl>            <lgl>               <chr>           <lgl>            
#> 1              1 P01     Aa aurantiaca              2 II             TRUE             FALSE               <NA>            FALSE            
#> 2              2 P01     Cattleya maxima            1 II             FALSE            FALSE               CR              FALSE            
#> 3              3 P02     Persea americana           4 <NA>           FALSE            FALSE               <NA>            FALSE            
#> 4              4 P02     Aa aurantiaca              3 II             TRUE             FALSE               <NA>            FALSE            
#> 5              5 P03     Catleya maxima             1 II             FALSE            FALSE               CR              TRUE
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

[`peruflora_deps()`](https://paulesantos.github.io/peruflora/reference/peruflora_deps.md),
[`peruflora_sitrep()`](https://paulesantos.github.io/peruflora/reference/peruflora_sitrep.md)
y
[`peruflora_conflicts()`](https://paulesantos.github.io/peruflora/reference/peruflora_conflicts.md)
ayudan a inspeccionar versiones y posibles conflictos en la sesión. Cite
también cada paquete y fuente que utilice en un análisis. El Libro Rojo,
la lista WCVP, el decreto y CITES responden preguntas distintas; el
resumen no los combina en una categoría única de conservación.
