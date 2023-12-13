### Read in data
# file path
hr_dir <- file.path("..", "processed_data", "horizon_task")
gng_dir <- file.path("..", "processed_data", "gonogo_task")
ds_dir <- file.path("..", "processed_data", "digit_span")
q_dir <- file.path("..", "processed_data", "q")
all_dir <- file.path("..", "processed_data", "all")
plots_dir <- file.path("..", "plots", "analysis")

### GNG 
# long data
gng_long <- read_csv(file.path(gng_dir, "gng_long.csv")) %>% 
  clean_names(case = "snake") %>% 
  mutate(id = as.character(id))
n_distinct(gng_long$id)

# wide data
# gng_wide <- read_csv(file.path(gng_dir, "gng_wide.csv")) %>% clean_names(case = "snake") %>% mutate(id = as.character(id))

# understanding check data
gng_check <- read_csv(file.path(gng_dir, "gng_check_raw.csv")) %>% clean_names(case = "snake") %>% mutate(id = as.character(id))

# print(paste("GNG task sample size: ", n_distinct(gng_long$id)))
# print("Glancing each id: ")
# sort(table(gng_long$id))

### Questionnaires
q_var_list <- c('id', 'quic_total', 'sparse_income_num', 'conflict_total', 'pss_total')
q_LIA <- read_rds(file.path(q_dir, "q_LIA.rds")) %>% select(q_var_list) 
# print(paste("Sample size for LIA questionnaires: ", n_distinct(q_LIA$id)))
q_MIA <- read_rds(file.path(q_dir, "q_MIA.rds")) %>% select(q_var_list) 
# print(paste("Sample size for MIA questionnaires: ", n_distinct(q_MIA$id)))

q <- rbind(q_LIA, q_MIA)

### Digit span
ds_var_list <- c('id', 'ds_total')
ds_LIA <- read_csv(file.path(ds_dir, "ds_LIA.csv"), col_types = cols(id = col_character())) %>% select(ds_var_list) 
# print(paste("Sample size for LIA digit span: ", n_distinct(ds_LIA$id)))
ds_MIA <- read_csv(file.path(ds_dir, "ds_MIA.csv"), col_types = cols(id = col_character())) %>% select(ds_var_list) 
# print(paste("Sample size for MIA digit span: ", n_distinct(ds_MIA$id)))

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
