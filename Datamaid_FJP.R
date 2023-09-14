

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


###Carregando Base Saúde IMRS
# Disponível em: https://docs.google.com/spreadsheets/d/1e8eTy8gwlWFLV8zzEPEB56WR0TkJ5i1u/edit?usp=sharing&ouid=114631608050578367156&rtpof=true&sd=true

imrs_saude <- read_excel("IMRS_BASE_SAUDE_2000-2021.xlsx")


#  Parte 1: Crítica de Dados ----------------------------------------------


#1 Distribuição
p1 <- standardVisual(imrs_saude$S_TXBRUTAMORT, "Taxa bruta de mortalidade")

p2 <-standardVisual(imrs_saude$S_TXMOISQCOR45A59, "Taxa de mortalidade por doenças isquêmicas do coração na população de 45 a 59 anos")


p1+p2



#2------------------------ Trabalhando com funções personalizadas

countZeros <- function(v, ...) {
  val <- length(which(v == 0))
  summaryResult(list(feature = "No. zeros", result = val, value = val))
}


countZeros(imrs_saude$S_TXMOHOMI15A29)


#-----------------------Adicionando novas funções ao report

makeDataReport(imrs_saude, summaries = setSummaries(
  character = defaultCharacterSummaries(add = "countZeros"),
  factor = defaultFactorSummaries(add = "countZeros"),
  labelled = defaultLabelledSummaries(add = "countZeros"),
  numeric = defaultNumericSummaries(add = "countZeros"),  
  integer = defaultIntegerSummaries(add = "countZeros"),
  logical = defaultLogicalSummaries(add = c("countMissing"))
), replace=TRUE, output = "html")


#----------------Recursos Adicionais

# Documentação DataMaid - https://github.com/ekstroem/DataMaid
