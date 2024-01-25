
# "Workshop: Crítica e Imputação de Dados: Pacote DataMaid"
## subtitle:  'Tutorial Transformação Digital nº 2' 
description: | 
  Compartilhando o código em R
abstract: |
  Neste tutorial, você aprenderá como utilizar o pacote DataMaid no ambiente R para a preparação de dados, uma etapa crucial na análise de dados. O DataMaid é uma ferramenta poderosa que auxilia na verificação e limpeza de dados, fornecendo um documento para análise da estrutura dos dados. Ele é capaz de identificar diversos tipos de erros e inconsistências nos dados, como classes incorretas, duplicatas, inconsistências de capitalização, valores improváveis, espaços em branco, indicadores de falta não reconhecidos e muito mais.
author:
  - name: "[Vitor Marinho](https://github.com/vitor-marinho-fjp)"
    affiliation: Fundação João Pinheiro/Cedeplar
    affiliation_url: https://fjp.mg.gov.br/
  - name: "[Caio Gonçalves](https://github.com/ccsgonc)"
    affiliation: Fundação João Pinheiro
    affiliation_url: https://fjp.mg.gov.br/
format: html
theme: Sandstone
toc: true 
toc_float: true
number-sections: true
lang: pt
editor: visual
bibliography: 
 - references.bib


```{r setup, include=FALSE}
knitr::opts_chunk$set(message = F, warning = F)
```

**Contato: [transformacao.digital\@fjp.mg.gov.br](mailto:transformacao.digital@fjp.mg.gov.br)**

# Introdução

Nesta oficina, aprenderemos como usar o pacote DataMaid no R para uma etapa prévia a crítica de dados: a preparação dos dados.

Tutorial disponível: <https://github.com/vitor-marinho-fjp/Critica_Datamaid>

O que é o DataMaid?

Um assistente de limpeza de dados capaz de fornecer um documento para ser lido e avaliado por uma pessoa. Uma ferramenta para auxiliar na lógica/verificação de erros tanto em colunas quanto em linhas. [@petersen2019]

### Exemplos de erros em verificações de dados para a limpeza de dados:

-   Classe incorreta

-   Duplicatas

-   Consistência de capitalização (**B**elo **H**orizonte vs **B**elo **h**orizonte)

-   Valor improvável (peso = 1000, idade = 201)

-   Espaços em branco

-   Indicadores de falta não reconhecidos

-   Quantidade de faltantes (NA)

-   Observações/categorias únicas com contagem baixa

-   Dados imprecisos (data de falecimento antes da data de nascimento)

### Inserção do dataMaid no Fluxo de trabalho em Ciência de Dados

![Fonte: Wickham & Grolemund (2017).](data-science.png){alt="Fonte: Wickham & Grolemund (2017)."}

Foco nos dois primeiros passos: Import → Tidy

# **Import/Tidy**

## Pacotes utilizados

```{r, message=FALSE, warning=FALSE, output=FALSE}


### Instalação e Carregamento do Pacote

# Lista de pacotes necessários
pacotes <- c('dataMaid', 'tidyverse', 'readxl', 'gt')

# Verifica se os pacotes estão instalados e instala se necessário
install.packages(setdiff(x = pacotes,
                         y = rownames(installed.packages())))

# Carrega os pacotes
lapply(X = pacotes,
       FUN = library,
       character.only = TRUE)
```

Documentação:

```{r eval=FALSE, include=FALSE}
vignette("extending_dataMaid")
```

## Carregando os Dados de Exemplo Indicadores de Saúde

Disponível em: [base_dados](https://github.com/vitor-marinho-fjp/fjp_boletim/blob/master/dados/dados_datamaid.xlsx){.uri}

```{r message=FALSE, warning=FALSE}
dados_datamaid <- read_excel("dados/dados_datamaid.xlsx")

dados_datamaid%>%
  head(5) %>%
  gt()
```

## Análise Inicial dos Dados

A função `makeDataReport` produz um relatório de visão geral dos dados em que *resume* o conteúdo do conjunto de dados e *sinaliza possíveis problemas*. Esses potenciais erros são identificados executando um conjunto de *verificações de validação* específicas da classe, de modo que diferentes verificações sejam realizadas em diferentes tipos de variáveis. As etapas de verificação podem ser personalizadas de acordo com a entrada do usuário e/ou tipo de dados da variável inserida

Para cada variável, um conjunto de funções de pré-verificação (controladas pelo argumento preChecks) é executado primeiro e depois uma bateria de funções é aplicada dependendo da classe da variável.

```{r eval=FALSE, include=FALSE}

makeDataReport(dados_datamaid, replace=TRUE, output = "html")
```

# Extra: Personalizando o Report

Além da análise inicial, você pode criar regras personalizadas para a análise inicial dos dados.

Por exemplo, podemos verificar a variável ***S_TXBRUTAMORT***

Trace a distribuição de uma variável.

```{r}


standardVisual(dados_datamaid$S_TXBRUTAMORT, "Taxa bruta de mortalidade")
```

```{r}

standardVisual(dados_datamaid$S_TXMOISQCOR45A59, "Taxa de mortalidade por doenças isquêmicas do coração na população de 45 a 59 anos")
```

## Trabalhando com funções personalizadas

### Funções de sumarização

Pode-se criar funções que seja do interesse a verificação. Por exemplo, um função para ocorrências de valores iguais a zero: `countZeros()`

Criando a função:

```{r}

countZeros <- function(v, ...) {
  val <- length(which(v == 0))
  summaryResult(list(feature = "No. zeros", result = val, value = val))
}


```

```{r}
countZeros(dados_datamaid$S_TXMOHOMI15A29)

```

uma outra função útil seria a contagem dos valores atípicos (outliers) em uma variável numérica `v` usando a abordagem do intervalo interquartil (IQR) com um fator de limiar (threshold):

```{r}
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

```

Além dessas, outras possibilidades são possíveis, por exemplo, criar uma função que calcule estatísticas (média, mediana, etc.) para uma variável numérica, segmentadas por grupos de uma variável categórica. Isso pode ser útil para entender as diferenças entre grupos:

```{r}
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

```

### Adicionando novas funções ao `report`

A inclusão das funções criadas anteriormente são realizadas da seguinte maneira:

```{r}
makeDataReport(dados_datamaid, summaries = setSummaries(
  character = defaultCharacterSummaries(add = c("countZeros", "countOutliers")),
  factor = defaultFactorSummaries(add = c("countZeros", "countOutliers")),
  labelled = defaultLabelledSummaries(add = c("countZeros", "countOutliers")),
  numeric = defaultNumericSummaries(add = c("countZeros", "countOutliers")),  
  integer = defaultIntegerSummaries(add = c("countZeros", "countOutliers")),
  logical = defaultLogicalSummaries(add = c("countZeros", "countOutliers"))
), replace = TRUE, output = "html")


```

**Funções do DataMaid**

| name                    | descrição                                                                |
|:-------------------|:---------------------------------------------------|
| identifyCaseIssues      | Identificar problemas                                                    |
| identifyLoners          | Identificar variáveis com \< 6 obs.                                      |
| identifyMissing         | Identificar valores ausentes mal codificados                             |
| identifyNums            | Identificar variáveis numéricas ou inteiras classificadas incorretamente |
| identifyOutliers        | Identificar outliers                                                     |
| identifyOutliersTBStyle | Identify outliers (Turkish Boxplot style)                                |
| identifyWhitespace      | Identifique espaços em branco prefixados e sufixados                     |
| isCPR                   | Identify Danish CPR numbers                                              |
| isEmpty                 | Verifique se a variável contém apenas um único valor                     |
| isKey                   | Verifique se a variável é uma chave                                      |
| isSingular              | Verifique se a variável contém apenas um único valor                     |
| isSupported             | Verifique se a classe da variável é suportada pelo dataMaid.             |

## Recursos Adicionais

Documentação DataMaid - <https://github.com/ekstroem/DataMaid>

Documentação DataMaid : <https://cran.r-project.org/web/packages/dataMaid/index.html>

```{r}
vignette("extending_dataMaid")
```

# Citação

Marinho,V.; Gonçalves, C. **Preparação de Dados: Pacote DataMaid**. Tutorial Transformação Digital. Fundação João Pinheiro, n. 2, 2023. Disponível em: https://rpubs.com/fjp/datamaid.
