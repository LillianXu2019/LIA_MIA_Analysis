########################################################################
######################## Read in and preprocess data ###################
########################################################################
# The correct response is dependent on two columns: 'go' and 'cue'.  
# 
# go:  
# TRUE = press the correct button that corresponds to the target side & no timeout (<1000ms)  
# FALSE = either one above is not true  
# 
# cue (index.html line 263-275):  
# 0 = go to win  
# 1 = no go to win  
# 2 = go to maintain  
# 3 = no go to maintain  
# 
# accurate response:  
#   (cue == 0 | 2) & go == TRUE: GO in GO TO WIN/AVOID LOSS  
# (cue == 1 | 3) & go == FALSE: NOGO in  NOGO TO WIN/AVOID LOSS  
# 
# Note: 'score' is probabilistic where only 80% of the correct responses were rewarded, so not a good indicator of response accuracy.  

######### load packages #########
# packages <- c('tidyverse', 'caret', 'rsample', 'janitor', 'cowplot', 'corrplot', 'ggeffects', "dplyr", 'plyr', 'gt', 'effects','mediation', 'knitr', 'tidyr', "sjPlot", 'mice', 'kableExtra', 'lmerTest', 'lme4', 'Hmisc', 'reshape', 'reshape2', 'ggplot2', 'jsonlite', 'MASS', 'gridExtra', 'zoo', 'Rmisc', 'car', 'webshot', 'GGally', 'naniar', 'simr', 'lmtest', 'broom.mixed', 'influence.ME', 'doParallel', 'webshot', 'simr', 'lmtest', 'influence.ME', 'doParallel', 'PerformanceAnalytics', 'performance', 'ltm', 'gtsummary', 'vtable', 'emmeans', 'ggExtra', 'scales', "Matrix", "factoextra", "lavaan", "ggcorrplot", "psych", "purrr", "broom", "HLMdiag", "rempsyc", "nnet", "foreign", "multcomp", "cluster", "ggpubr", "lubridate", "tibbletime")
# print(lapply(packages, require, character.only = TRUE))

######### set up file path #########
# note: for EXP paper, the cutoff time point is 12/2/2022 (as noted in df_check_12.2.2022, df_gng_info_12.2.2022, and task_length_12.2.2022 in processed_data/gonogo_task), and the last id is 1298. 
data_dir <- file.path("..", "processed_data", "gonogo_task")
plots_dir <- file.path("..", "plots", "gonogo_task")

######### task data ########
gng_raw <- read_csv(file.path(data_dir, "df_gng_info_LIA.csv"), col_types = cols(id = col_character())) %>% 
  clean_names(case = "snake") 

# check for completeness (trial number under each participant id)
id_check <- gng_raw %>% count(id, cue)

# check missingness in rt (trials where kids did not press the button)
rt_check <- gng_raw %>% group_by(id) %>% tally(is.na(rt)) # 1006 n=120; 1023 n=115; 1147 n=112; 1160; 1180; 1261

# ID 1044 and 1224 completed the task twice: keep the first one and discard the second one
gng_raw <- gng_raw %>% 
  filter(!filename %in% c("go-nogo-dev_PARTICIPANT_SESSION_2021-08-13_11h22.17.162.csv",
                          "go-nogo-dev_PARTICIPANT_SESSION_2022-11-20_16h54.34.688.csv")) %>% 
  filter(!id %in% c('100500', '10492', '10493', '1000000', '10500', '10501')) %>% # remove invalid ids
  filter(!id == "1031") # incomplete instructions (version updating) 

gng_raw$id[gng_raw$id == "732"] <- "1232"
gng_raw$id[gng_raw$id == "1793"] <- "1293"

# find out ids that have done the task more than once (i.e., same id, different filename; lag(id) means the previous id). We will keep the first entry of these ids (indicated by date that they took the task)
gng_raw <- gng_raw[order(gng_raw$id) , ]
repeat_ids <- gng_raw %>% 
  mutate(repeat_task = ifelse(id == lag(id) & filename != lag(filename), 1, 0)) %>% 
  filter(repeat_task == 1)
repeat_ids$id # "1309" "1310"

# create a list for the duplicated ids
# Note: duplicate ids by mis-assignment: 1308 1309 1310 ids are assigned to different kids, so they may have two entries each.
# 1309 on '2023-01-11'
# 1310 on '2023-01-11'
# 1312 (assigned as 1308) on '2023-02-09' 
# 1313 (assigned as 1309) on '2023-02-10' 
# 1314 (assigned as 1310) on '2023-02-10' 
# note: id 1308 hasn't completed the study yet
date1309 <- '2023-01-11'
date1310 <- '2023-01-11'
date1312 <- '2023-02-09'
date1313 <- '2023-02-10'
date1314 <- '2023-02-10'
date1085 <- '2021-07-30'
date1093 <- '2021-07-27'
date1267 <- '2022-07-16'
filename1312 <- 'go-nogo-dev_PARTICIPANT_SESSION_2023-02-09_19h12.52.683.csv'
filename1313 <- 'go-nogo-dev_PARTICIPANT_SESSION_2023-02-10_11h52.51.933.csv'
filename1314 <- 'go-nogo-dev_PARTICIPANT_SESSION_2023-02-10_09h17.07.190.csv'

wrong_id_assignment <- c('1308', '1309', '1310') 
list_id <- unique(c(repeat_ids$id, wrong_id_assignment))

# create a data frame to allow filtering by date
df_date <- gng_raw %>% 
  separate(filename, c('a', 'b', 'c', 'd', 'e'), sep = '_') %>% 
  select(-c(a,b,c,e)) %>%
  rename(date = d) %>% 
  mutate(date = as.Date(date)) 

print(paste("sample size prior to id correction for task data: ", n_distinct(df_date$id)))
print("Glancing each id: ")
print(sort(table(df_date$id)))

fun_correct_id <- function(original_id, data) {
  # for ids that are assigned to two different kids
  if (original_id %in% wrong_id_assignment) {
    alternate_id <- as.character(as.numeric(original_id) + 4)
    # print(alternate_id)
    date_of_alternate_id <- get(paste0('date', alternate_id))
    # print(date_of_alternate_id)
    
    df1 <- data %>% filter(id == original_id) %>% mutate(id = if_else(date == date_of_alternate_id, alternate_id, original_id)) 
    # this df should include both the original and the alternate id, with the alternate id labeled correctly
    data <- data %>% filter(!id == original_id) %>% rbind(., df1)
    # print(df1)
  } else {
    # for kids that did the task twice (default is to keep the first entry, but depends on how 'date_to_be_included' is coded above)
    date_to_be_included <- get(paste0('date', original_id))
    # print(original_id)
    # print(date_to_be_included)
    
    df1 <- data %>% filter(id == original_id & date == date_to_be_included)
    data <- data %>% filter(!id == original_id) %>% rbind(., df1)
    # print(df1)
  }
  assign('data',data,envir=.GlobalEnv) # explicitly assign the local copy of 'data' to the data (argument passed into the function) in the .GlobalEnv.
}

for (i in 1: length(list_id)) { 
  df_date <- fun_correct_id(list_id[i], df_date)
}

# re-assign the file name to corrected ids
gng_raw <- gng_raw %>% 
  group_by(id, filename) %>% 
  right_join(., df_date) %>% 
  mutate(filename = case_when(id == '1312' ~ filename1312,
                              id == '1313' ~ filename1313,
                              id == '1314' ~ filename1314,
                              TRUE ~ filename))

print(paste("sample size after id correction for task data: ", n_distinct(gng_raw$id)))
print("Glancing each id: ")
print(sort(table(gng_raw$id)))

######### understanding check data ######### 
gng_check_raw <- read_csv(file.path(data_dir, "df_check_LIA.csv"), col_types = cols(id = col_character())) %>% 
  clean_names(case = "snake")

# check for completeness (trial number under each participant id)
id_check <- gng_check_raw %>% count(id)

# ID 1044 and 1224 completed the task twice: keep the first one and discard the second one
gng_check_raw <- gng_check_raw %>% 
  filter(!filename %in% c("go-nogo-dev_PARTICIPANT_SESSION_2021-08-13_11h22.17.162.csv",
                          "go-nogo-dev_PARTICIPANT_SESSION_2022-11-20_16h54.34.688.csv")) %>% 
  filter(!id %in% c('100500', '10492', '10493', '1000000', '10500', '10501')) %>% # remove invalid ids
  filter(!id == "1031") # incomplete instructions (version updating) 

gng_check_raw$id[gng_check_raw$id == "732"] <- "1232"
gng_check_raw$id[gng_check_raw$id == "1793"] <- "1293"

# find out ids that have done the task more than once (i.e., same id, different filename; lag(id) means the previous id). We will keep the first entry of these ids (indicated by date that they took the task)
gng_check_raw <- gng_check_raw[order(gng_check_raw$id) , ]
repeat_ids <- gng_check_raw %>% 
  mutate(repeat_task = ifelse(id == lag(id) & filename != lag(filename), 1, 0)) %>% 
  filter(repeat_task == 1)
repeat_ids$id # "1309" "1310"

# create a list for the duplicated ids
# Note: duplicate ids by mis-assignment: 1308 1309 1310 ids are assigned to different kids, so they may have two entries each.
# 1309 on '2023-01-11'
# 1310 on '2023-01-11'
# 1312 (assigned as 1308) on '2023-02-09' 
# 1313 (assigned as 1309) on '2023-02-10' 
# 1314 (assigned as 1310) on '2023-02-10' 
# note: id 1308 hasn't completed the study yet
date1309 <- '2023-01-11'
date1310 <- '2023-01-11'
date1312 <- '2023-02-09'
date1313 <- '2023-02-10'
date1314 <- '2023-02-10'
date1085 <- '2021-07-30'
date1093 <- '2021-07-27'
date1267 <- '2022-07-16'
filename1312 <- 'go-nogo-dev_PARTICIPANT_SESSION_2023-02-09_19h12.52.683.csv'
filename1313 <- 'go-nogo-dev_PARTICIPANT_SESSION_2023-02-10_11h52.51.933.csv'
filename1314 <- 'go-nogo-dev_PARTICIPANT_SESSION_2023-02-10_09h17.07.190.csv'

wrong_id_assignment <- c('1308', '1309', '1310') 
list_id <- unique(c(repeat_ids$id, wrong_id_assignment))

# create a data frame to allow filtering by date
df_date <- gng_check_raw %>% 
  separate(filename, c('a', 'b', 'c', 'd', 'e'), sep = '_') %>% 
  select(-c(a,b,c,e)) %>%
  rename(date = d) %>% 
  mutate(date = as.Date(date)) 

print(paste("sample size prior to id correction for understanding check data: ", n_distinct(df_date$id)))
print("Glancing each id: ")
print(sort(table(df_date$id)))

for (i in 1: length(list_id)) { 
  df_date <- fun_correct_id(list_id[i], df_date)
}

# re-assign the file name to corrected ids
gng_check_raw <- gng_check_raw %>% 
  group_by(id, filename) %>% 
  right_join(., df_date) %>% 
  mutate(filename = case_when(id == '1312' ~ filename1312,
                              id == '1313' ~ filename1313,
                              id == '1314' ~ filename1314,
                              TRUE ~ filename))

# inspect id
print(paste("sample size after id correction for understanding check data: ", n_distinct(gng_check_raw$id)))
print("Glancing each id: ")
print(sort(table(gng_check_raw$id)))

######### subset data based on task version ######### 
df_date <- gng_raw %>% 
  separate(filename, c('a', 'b', 'c', 'd', 'e'), sep = '_') %>% 
  select(x1, id, d) %>% 
  rename(date = d) 

df_time <- gng_raw %>% 
  separate(filename, c('a', 'b', 'c', 'd', 'e'), sep = '_') %>% 
  separate(e, c('a', 'b', 'c', 'd')) %>% 
  select(x1, id, a) %>% 
  rename(time = a)

df_time$time <- gsub('h', ':', df_time$time)
df_time$time <- paste0(df_time$time, ":00")

df_dt <- df_date %>% full_join(., df_time) %>% mutate(date = as.Date(date)) %>% na.omit(.)

format <- "%Y-%m-%d %H:%M:%S"
df_dt$dt <- as.POSIXct(paste(df_dt$date, df_dt$time, format=format))

gng_raw <- gng_raw %>% left_join(., df_dt) %>% select(x1, id, dt, everything()) %>% as_tbl_time(., index = dt) %>% arrange(dt)

# filter data based on date and time
end_of_first_version <- '2021-07-23 15:00:00' 
end_of_second_version <- '2021-08-13 00:00:00'

#### first version
first <- filter_time(gng_raw, 'start' ~ end_of_first_version) %>% mutate(version = "first")
first_check <- gng_check_raw %>% filter(id %in% first$id) %>% mutate(version = "first")

#### second version
# The **2nd** task instructions were updated on Friday, 7/23 at noon CDT. 
# The first participant who had this version was 1058, filename = 'go-nogo-dev_PARTICIPANT_SESSION_2021-07-23_16h56.12.244.csv'
# The last participant who had this version was 1098, filename = 'go-nogo-dev_PARTICIPANT_SESSION_2021-08-11_13h28.09.789.csv'
# 1. 1044 was the last participant who had this version of task, but we will later exclude this kid as there was too many NAs in the rt data, suggesting that this kid was not responding most of the time. 
# 2. The second last kid who did this version was 1111, who has a low accuracy rate
# 3. The third last kid who did this version was 1098.
second <- filter_time(gng_raw, end_of_first_version ~ end_of_second_version) %>% mutate(version = "second")
second_check <- gng_check_raw %>% filter(id %in% second$id) %>% mutate(version = "second")

#### third version
# The **3rd** task instructions were updated on 8/13. 
# The first participant who had the second instructions was 1113, filename = 'go-nogo-dev_PARTICIPANT_SESSION_2021-08-16_10h02.34.326.csv'
third <- filter_time(gng_raw, end_of_second_version ~ 'end') %>% mutate(version = "third")
third_check <- gng_check_raw %>% filter(id %in% third$id) %>% mutate(version = "third")

print(paste("first version sample size: ", n_distinct(first$id)))

print(paste("second version sample size: ", n_distinct(second$id)))

print(paste("third version sample size: ", n_distinct(third$id)))

gng_all <- rbind(first, second, third)
gng_check_raw <- rbind(first_check, second_check, third_check)

######### subset data based on task performance ######### 
# rule 1: understanding check got 0 correct
gng_check1 <- gng_check_raw %>% group_by(id) %>% summarise(mean_acc = mean(correct_check), sd_acc = sd(correct_check)) %>% filter(mean_acc == 0)

# rule 2： total accuracy rate less than 50% (according to de Berker 2016 group comparison)
gng_check2 <- gng_raw %>% group_by(id) %>% summarise(mean_acc = mean(correct), sd_acc = sd(correct)) %>% filter(mean_acc < 0.5)

# rule 3: showing inattention (eye-ball inspection of individual plots -- nearly 0% of go throughout the game)
### from the plots
bad_id_first_version <- c('1006', '1018', '1023')
bad_id_second_version <- c('1046') # 1046 at chance level
bad_id_third_version <- c('1147', '1160', '1180', '1263', '1222') # 1222 at chance level in the second half of the game
### from the data
gng_check_response_rate <- gng_raw %>% group_by(id) %>% summarise(go_percent = mean(go)) %>% filter(go_percent < .10) # response rate less than 10% across the game will be considered inattention,
print("Participants removed because of inattention (percentage of go, i.e., button press, < 10%): ")
print(gng_check_response_rate)
# gng_check3 <- c(bad_id_first_version, bad_id_second_version, bad_id_third_version)

# exclude kids task data based on data check
gng_all <- gng_all %>% 
  # filter(!id %in% gng_check1$id) %>% 
  # filter(!id %in% gng_check2$id) %>% 
  # filter(!id %in% gng_check3$id)
  filter(!id %in% gng_check_response_rate$id)

gng_check_raw <- gng_check_raw %>% 
  # filter(!id %in% gng_check1$id) %>% 
  # filter(!id %in% gng_check2$id) %>% 
  # filter(!id %in% gng_check3$id)
  filter(!id %in% gng_check_response_rate$id)

# note: might also get rid of 1116 and 1117, whom we suspect are faking an identify and participating just for money...

# removal summary
print(paste("N removed: ", length(gng_check_response_rate$id)))
# print(length(gng_check_response_rate$id))
print(paste("N kept: ", n_distinct(gng_all$id)))
print("Take a look at the cleaned raw data: ")
print(head(gng_all))

# write out csv file
write_csv(gng_all, file.path(data_dir, "gng_all_LIA.csv"))
write_csv(gng_check_raw, file.path(data_dir, "gng_check_raw_LIA.csv"))