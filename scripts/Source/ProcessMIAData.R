########################################################################
######################## Read in and preprocess data ###################
########################################################################
# The correct response is dependent on two columns: 'go' and 'cue'.  
# 
# go:  
# TRUE = press the correct button that corresponds to the target side & no timeout (<1000ms)  
# FALSE = either one above is not true  
# 
# cue (index.html line 328-340):
# 0 = go for positive feedback: go -> positive pictures; no go -> neutral pictures    
# 1 = no go for positive feedback: no go -> positive pictures; go -> neutral pictures    
# 2 = go to avoid negative feedback: go -> neutral pictures; no go -> negative pictures    
# 3 = no go to avoid negative feedback: no go -> neutral pictures; go -> negative pictures    
# 
# accurate response:  
# (cue == 0 | 2): GO    
# (cue == 1 | 3): NOGO    
# 
# Note: 'score' is probabilistic where only 80% of the correct responses were rewarded, so not a good indicator of response accuracy.  

######### load packages #########
# packages <- c('tidyverse', 'caret', 'rsample', 'janitor', 'cowplot', 'corrplot', 'ggeffects', "dplyr", 'plyr', 'gt', 'effects','mediation', 'knitr', 'tidyr', "sjPlot", 'mice', 'kableExtra', 'lmerTest', 'lme4', 'Hmisc', 'reshape', 'reshape2', 'ggplot2', 'jsonlite', 'MASS', 'gridExtra', 'zoo', 'Rmisc', 'car', 'webshot', 'GGally', 'naniar', 'simr', 'lmtest', 'broom.mixed', 'influence.ME', 'doParallel', 'webshot', 'simr', 'lmtest', 'influence.ME', 'doParallel', 'PerformanceAnalytics', 'performance', 'ltm', 'gtsummary', 'vtable', 'emmeans', 'ggExtra', 'scales', "Matrix", "factoextra", "lavaan", "ggcorrplot", "psych", "purrr", "broom", "HLMdiag", "rempsyc", "nnet", "foreign", "multcomp", "cluster", "ggpubr", "lubridate", "tibbletime")
# print(lapply(packages, require, character.only = TRUE))

######### set up file path #########
data_dir <- file.path("..", "processed_data", "gonogo_task")
plots_dir <- file.path("..", "plots", "gonogo_task")

######### task data ########
# gng_raw <- read_csv(file.path(data_dir, "df_gng_info.csv"), col_types = cols(id = col_character())) %>% clean_names(case = "snake")
gng_raw <- read_csv(file.path(data_dir, "df_gng_info_MIA.csv")) %>% 
  clean_names(case = "snake") %>% 
  filter(id > 1000 & id < 10000) %>% 
  mutate(id = as.character(id))

# check for completeness (trial number under each participant id)
id_check <- gng_raw %>% count(id, cue)

# check missingness in rt (trials where kids did not press the button)
rt_check <- gng_raw %>% group_by(id) %>% tally(is.na(rt)) 

# find out ids that have done the task more than once (i.e., same id, different filename; lag(id) means the previous id).
gng_raw <- gng_raw[order(gng_raw$id) , ]
repeat_ids <- gng_raw %>% 
  mutate(repeat_task = ifelse(id == lag(id) & filename != lag(filename), 1, 0)) %>% 
  filter(repeat_task == 1)
paste("Duplicate ids: ", repeat_ids$id )

# inspect ids
print(paste("Current sample size for task data: ", n_distinct(gng_raw$id)))
print("Glancing each id: ")
print(sort(table(gng_raw$id))) # rows per id

######### understanding check data ######### 
gng_check_raw <- read_csv(file.path(data_dir, "df_check_MIA.csv")) %>% 
  clean_names(case = "snake") %>% 
  filter(id > 2000 & id < 10000) %>% 
  mutate(id = as.character(id))

# check for completeness (trial number under each participant id)
id_check <- gng_check_raw %>% count(id)

# find out ids that have done the task more than once (i.e., same id, different filename; lag(id) means the previous id).
gng_check_raw <- gng_check_raw[order(gng_check_raw$id) , ]
repeat_ids <- gng_check_raw %>% 
  mutate(repeat_task = ifelse(id == lag(id) & filename != lag(filename), 1, 0)) %>% 
  filter(repeat_task == 1)
paste("Duplicate ids: ", repeat_ids$id )

# inspect ids
print(paste("Current sample size for understanding check data: ", n_distinct(gng_check_raw$id)))
print("Glancing each id: ")
print(sort(table(gng_check_raw$id))) # rows per id

# write out csv file
write_csv(gng_check_raw, file.path(data_dir, "gng_check_raw_MIA.csv"))

######### subset data based on task performance ######### 
# rule 1: understanding check got 0 correct
gng_check1 <- gng_check_raw %>% group_by(id) %>% summarise(mean_acc = mean(correct_check), sd_acc = sd(correct_check)) %>% filter(mean_acc == 0)

# rule 2： total accuracy rate less than 50% (according to de Berker 2016 group comparison) --> need to be changed to within 2nd half of the game
gng_check2 <- gng_raw %>% group_by(id) %>% summarise(mean_acc = mean(correct), sd_acc = sd(correct)) %>% filter(mean_acc < 0.5)

# rule 3 (current criteria): showing inattention
gng_check_response_rate <- gng_raw %>% group_by(id) %>% summarise(go_percent = mean(go)) %>% filter(go_percent < .10) # response rate less than 10% across the game will be considered inattention,
# gng_check3 <- c('2002', '2017', '2030', '2047', '2034') # bad ids based on eyeballing individual plots (subjective, as a confirmation check)
# 2045, 2041, 2071 could be problematic (outliers), will see the influence plot
print("Participants removed because of inattention (percentage of go, i.e., button press, < 10%): ")
print(gng_check_response_rate)

# exclude kids task data based on data check
gng_raw <- gng_raw %>% 
  # filter(!id %in% gng_check1$id) %>% 
  # filter(!id %in% gng_check2$id) %>% 
  filter(!id %in% gng_check_response_rate$id)

# removal summary
print(paste("N removed: ", length(gng_check_response_rate$id)))
# print(length(gng_check_response_rate$id))
print(paste("N kept: ", n_distinct(gng_raw$id)))
print("Take a look at the cleaned raw data: ")
print(head(gng_raw))

# write out csv file
write_csv(gng_raw, file.path(data_dir, "gng_all_MIA.csv"))