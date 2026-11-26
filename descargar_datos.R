
# UNIVERSIDAD CENTRAL DEL ECUADOR
# Proyecto Integrador - Mineria de Datos
# Integrantes: Giancarlo Loaiza y Luis Suntaxi
# Fuente: SERCOP - OCDS 2025

options(timeout = 1800)

dir.create("data", showWarnings = FALSE)
dir.create("salidas", showWarnings = FALSE)

portal <- "https://datosabiertos.compraspublicas.gob.ec/PLATAFORMA/datos-abiertos"

archivos <- c(
  "awards_2025.csv",
  "contracts_2025.csv",
  "extensions_2025.csv",
  "metadata_2025.csv",
  "planning_2025.csv",
  "releases_2025.csv",
  "suppliers_2025.csv",
  "tender_2025.csv"
)

filas_esperadas <- c(
  184769, 181591, 7, 1,
  37821, 191497, 184766, 186415
)

columnas_esperadas <- c(
  17, 14, 1, 9, 7, 8, 5, 29
)

rutas <- file.path("data", archivos)

if (!all(file.exists(rutas))) {

  zip_datos <- "data/SERCOP_2025.zip"

  if (!file.exists(zip_datos)) {

    url <- Sys.getenv("SERCOP_CSV_URL")

    if (nzchar(url)) {

      download.file(
        url,
        zip_datos,
        mode = "wb"
      )

    } else {

      if (interactive()) browseURL(portal)

      stop(
        "Descargar el CSV anual 2025 del portal SERCOP.
         Guardar el ZIP como data/SERCOP_2025.zip
         y ejecutar nuevamente el script."
      )
    }
  }

  contenido <- unzip(zip_datos, list = TRUE)

  posiciones <- match(
    archivos,
    basename(contenido$Name)
  )

  stopifnot(!anyNA(posiciones))

  temporal <- tempfile()
  dir.create(temporal)

  unzip(
    zip_datos,
    files = contenido$Name[posiciones],
    exdir = temporal
  )

  for (i in seq_along(archivos)) {

    if (!file.exists(rutas[i])) {

      stopifnot(
        file.copy(
          file.path(
            temporal,
            contenido$Name[posiciones[i]]
          ),
          rutas[i]
        )
      )
    }
  }

  unlink(temporal, recursive = TRUE)
}

stopifnot(all(file.exists(rutas)))

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}

control <- data.frame(
  archivo = archivos,
  filas_esperadas = filas_esperadas,
  columnas_esperadas = columnas_esperadas,
  filas_actuales = NA_integer_,
  columnas_actuales = NA_integer_,
  tamano_MB = round(
    file.info(rutas)$size / 1024^2, 2
  ),
  md5 = unname(tools::md5sum(rutas))
)

for (i in seq_along(rutas)) {

  datos <- data.table::fread(
    rutas[i],
    showProgress = FALSE
  )

  control$filas_actuales[i] <- nrow(datos)
  control$columnas_actuales[i] <- ncol(datos)

  rm(datos)
  gc()
}

control$valido <-
  control$filas_esperadas ==
    control$filas_actuales &
  control$columnas_esperadas ==
    control$columnas_actuales

print(control)

write.csv(
  control,
  "salidas/00_control_datos.csv",
  row.names = FALSE
)

writeLines(
  c(
    paste("Fuente:", portal),
    "Periodo: 2025",
    "Extraccion original: 26/11/2026",
    "Estandar: OCDS 1.1",
    "Licencia: CC BY 3.0 Ecuador"
  ),
  "salidas/00_fuente_datos.txt"
)

stopifnot(all(control$valido))

cat("\nDATOS VALIDADOS CORRECTAMENTE\n")

