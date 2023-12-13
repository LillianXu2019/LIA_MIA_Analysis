###### set up file path
hr_dir <- file.path("..", "processed_data", "horizon_task")
gng_dir <- file.path("..", "processed_data", "gonogo_task")
ds_dir <- file.path("..", "processed_data", "digit_span")
q_dir <- file.path("..", "processed_data", "q")
all_dir <- file.path("..", "processed_data", "all")
plots_dir <- file.path("..", "plots", "analysis")

###### gng task
## long data
gng_long <- read_csv(file.path(gng_dir, "gng_long.csv")) %>% 
  clean_names(case = "snake") %>% 
  mutate(id = as.character(id))
n_distinct(gng_long$id)

## wide data
# gng_wide <- read_csv(file.path(gng_dir, "gng_wide.csv")) %>% clean_names(case = "snake") %>% mutate(id = as.character(id))

## understanding check data
gng_check <- read_csv(file.path(gng_dir, "gng_check_raw.csv")) %>% clean_names(case = "snake") %>% mutate(id = as.character(id))

print(paste("GNG task sample size: ", n_distinct(gng_long$id)))
# print("Glancing each id: ")
# sort(table(gng_long$id))

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

##### digit span task
ds_wide <- read_csv(file.path(ds_dir, "ds.csv")) %>% clean_names(case = "snake") %>% mutate(id = as.character(id)) %>% select(-x1)

##### questionnaires
q <- read_rds(file.path(q_dir, "q.rds")) %>% clean_names(case = "snake")
q <- q %>%
  group_by(id) %>%
  fill(2:ncol(q), .direction = "downup") %>%
  distinct()
# note: The default of 'fill' is to fill "down" (i.e. fill NAs with values from preceding rows). You could try fill(var, .direction = "downup") which will look both above and below for replacement values, if you know that each id only has one response for each questionnaire item.

# recode factor variables
q <- q %>% 
  mutate(sex = factor(child_gender, levels=1:3, labels=c("Female", "Male", "Others")),
         parent_gender = factor(parent_gender, levels=1:3, labels=c("Female", "Male", "Others")))

##### covariate data (q + digit span)
df_covar <- full_join(ds_wide, q) 
