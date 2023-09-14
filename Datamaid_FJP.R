

# Instalação e Carregamento do Pacote ------------------------------------



# Lista de pacotes necessários
pacotes <- c('dataMaid', 'tidyverse', 'readxl', 'patchwork')

# Verificar se os pacotes estão instalados e instalá-los se necessário
for (pacote in pacotes) {
  if (!requireNamespace(pacote, quietly = TRUE)) {
    install.packages(pacote)
    library(pacote, character.only = TRUE)
  } else {
    library(pacote, character.only = TRUE)
  }
}




# Carregar base e gerar relatório -----------------------------------------

# Disponível: https://docs.google.com/spreadsheets/d/1e8eTy8gwlWFLV8zzEPEB56WR0TkJ5i1u/edit?usp=sharing&ouid=114631608050578367156&rtpof=true&sd=true

imrs_saude <- read_excel("IMRS_BASE_SAUDE_2000-2021.xlsx")


makeDataReport(imrs_saude, replace=TRUE, output = "html")

# Adicionando Funções -----------------------------------------------------



#Contar valores zeros

countZeros <- function(v, ...) {
  val <- length(which(v == 0))
  summaryResult(list(feature = "No. zeros", result = val, value = val))
}


countZeros(imrs_saude$S_TXMOHOMI15A29)


#Função para Identificar Outliers:
countOutliers <- function(v, threshold = 1.5) {
  q1 <- quantile(v, 0.25)
  q3 <- quantile(v, 0.75)
  iqr <- q3 - q1
  lower_bound <- q1 - threshold * iqr
  upper_bound <- q3 + threshold * iqr
  val <- length(which(v < lower_bound | v > upper_bound))
  summaryResult(list(feature = "No. outliers", result = val, value = val))
}


# Por grupo

## Crie uma função que calcule estatísticas (média, mediana, etc.) para uma variável numérica,
# segmentadas por grupos de uma variável categórica. Isso pode ser útil para entender as diferenças entre grupos.

calculateStatsByGroup <- function(data, numeric_var, categorical_var) {
  stats_by_group <- data %>%
    group_by({{categorical_var}}) %>%
    summarise(
      Mean = mean({{numeric_var}}, na.rm = TRUE),
      Median = median({{numeric_var}}, na.rm = TRUE),
      SD = sd({{numeric_var}}, na.rm = TRUE)
    )
  summaryResult(list(
    feature = paste("Summary Statistics by", as_label(categorical_var)),
    result = stats_by_group,
    value = NULL
  ))
}



#-----------------------Adicionando novas funções ao report

makeDataReport(imrs_saude, summaries = setSummaries(
  character = defaultCharacterSummaries(add = c("countZeros", "countOutliers")),
  factor = defaultFactorSummaries(add = c("countZeros", "countOutliers")),
  labelled = defaultLabelledSummaries(add = c("countZeros", "countOutliers")),
  numeric = defaultNumericSummaries(add = c("countZeros", "countOutliers")),  
  integer = defaultIntegerSummaries(add = c("countZeros", "countOutliers")),
  logical = defaultLogicalSummaries(add = c("countZeros", "countOutliers"))
), replace = TRUE, output = "html")



#----------------Recursos Adicionais

# Documentação DataMaid - https://github.com/ekstroem/DataMaid
