### Read in data
# file path
hr_dir <- file.path("..", "processed_data", "horizon_task")
gng_dir <- file.path("..", "processed_data", "gonogo_task")
ds_dir <- file.path("..", "processed_data", "digit_span")
q_dir <- file.path("..", "processed_data", "q")
all_dir <- file.path("..", "processed_data", "all")
plots_dir <- file.path("..", "plots", "analysis")

### GNG 
# LIA data
gng_LIA <- read_csv(file.path(gng_dir, "gng_all_LIA.csv"), 
                    col_types = cols(id = col_character()))
gng_check_LIA <- read_csv(file.path(gng_dir, "gng_check_raw_LIA.csv"), 
                          col_types = cols(id = col_character()))
print(paste("Sample size for LIA Go-Nogo task: ", n_distinct(gng_LIA$id)))
print(paste("Sample size for LIA Go-Nogo task - third version: ", n_distinct(subset(gng_LIA, version == "third")$id)))

# MIA data
gng_MIA <- read_csv(file.path(gng_dir, "gng_all_MIA.csv"), 
                    col_types = cols(id = col_character())) %>% 
  mutate(version = "MIA")
gng_check_MIA <- read_csv(file.path(gng_dir, "gng_check_raw_MIA.csv"), 
                          col_types = cols(id = col_character())) %>% 
  mutate(version = "MIA")
print(paste("Sample size for MIA Go-Nogo task: ", n_distinct(gng_MIA$id)))

# combine LIA and MIA data
gng_all <- bind_rows(gng_LIA, gng_MIA) %>% select(-c(date, time)) 
gng_check_raw <- gng_check_LIA %>% select(-date) %>% bind_rows(., gng_check_MIA)

### Questionnaires
q_var_list <- c('id', 'quic_total', 'sparse_income_num', 'conflict_total', 'pss_total')
q_LIA <- read_rds(file.path(q_dir, "q_LIA.rds")) %>% select(q_var_list) 
print(paste("Sample size for LIA questionnaires: ", n_distinct(q_LIA$id)))
q_MIA <- read_rds(file.path(q_dir, "q_MIA.rds")) %>% select(q_var_list) 
print(paste("Sample size for MIA questionnaires: ", n_distinct(q_MIA$id)))

q <- rbind(q_LIA, q_MIA)

### Digit span
ds_var_list <- c('id', 'ds_total')
ds_LIA <- read_csv(file.path(ds_dir, "ds_LIA.csv"), col_types = cols(id = col_character())) %>% select(ds_var_list) 
print(paste("Sample size for LIA digit span: ", n_distinct(ds_LIA$id)))
ds_MIA <- read_csv(file.path(ds_dir, "ds_MIA.csv"), col_types = cols(id = col_character())) %>% select(ds_var_list) 
print(paste("Sample size for MIA digit span: ", n_distinct(ds_MIA$id)))

ds <- rbind(ds_LIA, ds_MIA)

### Predictors data combined (Questionnaires + Digit span) 
df_predictors <- left_join(q, ds) %>% 
  rename(QUIC = quic_total, 
         Perceived_stress = pss_total, 
         Digit_span = ds_total, 
         Family_income = sparse_income_num, 
         Parent_child_conflict = conflict_total)

### remove dfs
rm(gng_LIA, gng_MIA, gng_check_LIA, gng_check_MIA, q_LIA, q_MIA, ds_LIA, ds_MIA, q, ds)
