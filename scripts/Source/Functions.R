# FUNCTIONS

############################### varScore ############################### 
varScore <- function(Data, Forward, Reverse=NULL, Range = NULL, Prorate = TRUE, MaxMiss = .20)
{
  #select relevant items
  d = Data[,c(Forward, Reverse)]
  
  #check for out of range
  if (!is.null(Range)){
    if (min(d, na.rm=TRUE) < Range[1] || max(d, na.rm=TRUE) > Range[2]){
      stop('Item score(s) out of range')
    }
  }
  
  #check that length of Range == 2 if Reverse is not null
  if (!is.null(Reverse) && length(Range) !=2) {
    stop('Must specify item range (Range) to reverse score items')
  }
  
  #Reverse score relevant items
  if (!is.null(Reverse)){
    for (v in Reverse) {
      d[,v] = (Range[1] + Range[2]) - d[,v]
    }   
  }
  
  if (Prorate){
    Total = rowMeans(d, na.rm=TRUE)*dim(d)[2]
  }
  else{
    Total = rowSums(d, na.rm=TRUE)
  }
  
  #count missing and set > MaxMiss to NA
  MissCount = rowSums(is.na(d))
  MissCount = MissCount/dim(d)[2]
  Total[MissCount > MaxMiss] = NA
  
  return(Total)
}

############################### varRecode ############################### 
varRecode <- function(Var, Old, New)
{
  #check for length match for levels of old and new
  if (length(Old) != length(New))
    stop('Number of Old and New values do not match')
  
  NewVar = rep(NA, length(Var)) #set to NA to start
  for (i in 1:length(Old))
  {
    NewVar[Var==Old[i]] = New[i]
  }
  
  #check for mismatch of NA which means some levels in Var were not reassigned.  Warning only
  if (sum(is.na(NewVar)) != sum(is.na(Var)))
    warning(sprintf('%.0f NAs in original variable but %.0f NAs in recoded variable', sum(is.na(Var)), sum(is.na(NewVar))))
  
  #covert NewVar to factor if Var was factor
  if (is.factor(Var))  
    NewVar = as.factor(NewVar)
  
  return(NewVar)
}

############################### varDescribe ############################### 
varDescribe <- function(Data, Detail = 2, Digits = 2)
{
  t3 = psych::describe(Data)
  t3 = data.frame(t3)
  
  if (!is.null(Digits))  t3 = round(t3,Digits)
  
  t2 = t3[,c(1:5,8,9,11,12)]
  t1 = t3[,c(2:4,8,9)]
  t = switch(Detail, t1, t2, t3)
  return(t)
}

############################### flat_cor_mat ############################### 
flat_cor_mat <- function(cor_r, cor_p, cor_n){
  #This function provides a simple formatting of a correlation matrix
  #into a table with 4 columns containing :
  # Column 1 : row names (variable 1 for the correlation test)
  # Column 2 : column names (variable 2 for the correlation test)
  # Column 3 : the correlation coefficients
  # Column 4 : the p-values of the correlations
  library(tidyr)
  library(tibble)
  cor_r <- rownames_to_column(as.data.frame(cor_r), var = "row")
  cor_r <- gather(cor_r, column, cor, -1)
  cor_p <- rownames_to_column(as.data.frame(cor_p), var = "row")
  cor_p <- gather(cor_p, column, p, -1)
  cor_n <- rownames_to_column(as.data.frame(cor_n), var = "row")
  cor_n <- gather(cor_n, column, n, -1)
  cor_p_matrix <- left_join(cor_r, cor_p, by = c("row", "column"))
  cor_p_matrix <- left_join(cor_p_matrix, cor_n, by = c("row", "column"))
  return(cor_p_matrix)
}
############################### get_correlation_fun ############################### 
# note: this function is for EXP publication (study 1 = EXP; study 2 = LIA)
get_correlation_fun <- function(study, scales) {
  if (study == "study1") {
    q <- hr_wide_study1
    data <- hr_long_study1
  } else {
    q <- hr_wide_study2
    data <- hr_long_study2
  }
  
  df <- q %>% filter(id %in% data$id) %>% select(all_of(scales))
  cor <- rcorr(as.matrix(df, method = "pearson", use = "pairwise.complete.obs", adjust = 'holm'))
  
  # correlation csv file
  cor_matrix <- flat_cor_mat(round(cor$r, 3), round(cor$P, 3), cor$n) %>% arrange(row, p, cor)
  str_scales <- deparse(substitute(scales))
  write.csv(cor_matrix, file = file.path(Code_dir, paste0(str_scales, "_cor_matrix.csv")))
}

############################### model_fun ############################### 
model_fun <- function(response, predictors, data) {
  if (response == "go") {
    control=glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e7))
    formula = as.formula( paste(paste(response, "~"), paste( predictors, collapse = "+") ) )
    glmer(formula, data = data, family = binomial, control = control)
  } else {
    # if (response == "rt") {
      control=lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e7))
      formula = as.formula( paste(paste(response, "~"), paste( predictors, collapse = "+") ) )
      lmer(formula, data = data, control = control)
    # }
  }
}