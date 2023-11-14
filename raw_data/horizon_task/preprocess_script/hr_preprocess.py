"""
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

@author: Lillian(Yuyan)Xu
"""

import os
import glob
import time
import pandas as pd
import numpy as np
import os.path as op
import re
from datetime import datetime as dt

#### adapted from LIA
#### changes from LIA script: delete "r11" in line 127 and 136.

# set up directories
script_dir = op.dirname(__file__)
LIA_dir = op.abspath(op.join(script_dir,'../../..'))

input_dir = op.join(LIA_dir,'raw_data/horizon_task/pilot_data')
output_dir = op.join(LIA_dir,'processed_data/horizon_task')

# initiate empty lists to store extracted data
hr_info1 = []
hr_info2 = []
task_length = []
comprehension_question = []

# create a function that ignores the hidden file when getting the files (e.g., DS_store)
def listdir_nohidden(path):
    return glob.glob(os.path.join(path, '*'))

# get file names and sort them based on last modification date and time (not the date and time on filename)
files_full_dir = list(map(lambda x: op.join(input_dir, x), listdir_nohidden(input_dir)))
list_of_files = sorted(files_full_dir, key = os.path.getmtime)

# extract task data
for file in list_of_files:
    filename = op.basename(file)
    # extract date and time data from each filename
    timestamp = re.sub('[a-zA-Z]+_', '', filename) # strip things BEFORE the data and time (i.e., 'horizon_PARTICIPANT_SESSION_')
    timestamp = re.sub('\.[0-9]+\.[0-9]+\.csv$', '', timestamp) # strip things AFTER the date and time (e.g., '.566.csv')
    timestamp = re.sub('h', '-', timestamp) # replace 'h' (stands for 'hour' in filename) with '-' for ease of recognization in dt.strptime
    # print(f"timestamp: {timestamp}")
    from_date = dt.strptime("5/23/2021", "%m/%d/%Y")
    # print(f"from_date: {from_date}")
    file_date = dt.strptime(timestamp, "%Y-%m-%d_%H-%M")
    print(f"file_date: {file_date}")


    if filename.startswith("horizon") and file_date > from_date and os.stat(file).st_size > 23*1024: # discard incomplete data that are less than 20 KB (1 KB = 1024 bytes)
        print("Processing {} ...".format(filename)) # for debugging
        #file = op.join(input_dir,filename)
        hr_raw = pd.read_csv(file, sep = ',')
        participant_id = hr_raw.subject.values[1]

        # task duration
        time_start = hr_raw.time_elapsed.values[0]
        time_end = hr_raw.time_elapsed.values[len(hr_raw)-1]
        duration_second = (time_end - time_start)/1000
        duration_min = duration_second/60
        task_length.append([participant_id,filename,time_start,time_end,duration_second,duration_min])

        # comprehension questions
        if hr_raw.test_part[63] == 'practice-question':
            q1 = hr_raw.correct[63]
            q2 = hr_raw.correct[65]
            q3 = hr_raw.correct[67]
            q4 = hr_raw.correct[69]
            q5 = hr_raw.correct[71]
            q6 = hr_raw.correct[73]
            comprehension_question.append([participant_id,filename,q1,q2,q3,q4,q5,q6])

        else:
            q1 = hr_raw.correct[26]
            q2 = hr_raw.correct[28]
            q3 = hr_raw.correct[30]
            q4 = hr_raw.correct[32]
            q5 = hr_raw.correct[34]
            q6 = hr_raw.correct[36]
            comprehension_question.append([participant_id,filename,q1,q2,q3,q4,q5,q6])

        df_comprehension_question = pd.DataFrame(comprehension_question, columns = ["participant_id","filename","q1","q2","q3","q4","q5","q6"])
        df_comprehension_question.to_csv(op.join(output_dir,'comprehension_question.csv'), sep=",")    

        # rewards, choices, and rt data
        game = 1
        block = 1
        for i in range(0, len(hr_raw)):
            if pd.notna(hr_raw.responses.values[i]):
                rewards_chosen = hr_raw.scores.values[i].split(',')
                choices = hr_raw.a.values[i].split(',')
                game_length = len(choices)
                rewards_left = hr_raw.rewards.values[i].split(',')[0:game_length]
                rewards_right = hr_raw.rewards.values[i].split(',')[game_length:]
                
                # reaction time
                # first file with rt recorded "horizon_PARTICIPANT_SESSION_2021-07-15_17h45.50.775.csv"
                # note: file_time (through time.ctime) is slightly off from the time shown in the file name, so to avoid missing the first file with rt recorded,
                # we used '2021-07-15_16h45.54' (get it through time.ctime) to code start_time instead of '2021-07-15_17h45.50'.

                # extract start time for comparison
                start_time = dt.strptime('2021-07-15_16h45.54', '%Y-%m-%d_%Hh%M.%S') # we only keep it to seconds
                # extract file time for each individual file
                file_time = time.ctime(os.path.getmtime(file)) # 
                file_time = dt.strptime(file_time, "%a %b %d %H:%M:%S %Y")
                # compare start_time and file_time to get a list of files with rt recorded
                if (file_time >= start_time):
                    rt = hr_raw.rt.values[i].split(',')
                    hr_info1.append([participant_id,filename,block,game,game_length,rewards_chosen,choices,rewards_left,rewards_right,rt])
                    
                else:
                    hr_info2.append([participant_id,filename,block,game,game_length,rewards_chosen,choices,rewards_left,rewards_right])
                
                game +=1
                if game % 10 == 1:
                    block +=1        
    else:
        continue

# merge hr_info1 (w/ rt) and hr_info2 (w/o rt) together
df_hr_info1 = pd.DataFrame(hr_info1, columns = ["participant_id", "filename", "block", "game", "game_length","rewards_chosen","choices","rewards_left","rewards_right","rt"])
# df_hr_info1[['rt1','rt2','rt3','rt4','rt5','rt6','rt7','rt8','rt9','rt10','rt11']] = pd.DataFrame(df_hr_info1.rt.tolist(), index= df_hr_info1.index)
df_hr_info1[['rt1','rt2','rt3','rt4','rt5','rt6','rt7','rt8','rt9','rt10']] = pd.DataFrame(df_hr_info1.rt.tolist(), index= df_hr_info1.index)

df_hr_info2 = pd.DataFrame(hr_info2, columns = ["participant_id", "filename", "block", "game", "game_length","rewards_chosen","choices","rewards_left","rewards_right"])
df_hr_info = pd.concat([df_hr_info1,df_hr_info2])

# remove the additional rt in horizon 1 and horizon 6 games 
if (pd.notnull(df_hr_info.rt6).bool == True) and (pd.isnull(df_hr_info.rt7).bool == True):
    df_hr_info["rt6"]= ''
# df_hr_info.drop(['rt11','rt12'], axis=1, inplace=True)

# unlist rewards and choices in each trial from one column to separate columns
df_hr_info[['r1','r2','r3','r4','r5','r6','r7','r8','r9','r10']] = pd.DataFrame(df_hr_info.rewards_chosen.tolist(), index= df_hr_info.index)
df_hr_info[['c1','c2','c3','c4','c5','c6','c7','c8','c9','c10']] = pd.DataFrame(df_hr_info.choices.tolist(), index= df_hr_info.index)
df_hr_info[['rl1','rl2','rl3','rl4','rl5','rl6','rl7','rl8','rl9','rl10']] = pd.DataFrame(df_hr_info.rewards_left.tolist(), index= df_hr_info.index)
df_hr_info[['rr1','rr2','rr3','rr4','rr5','rr6','rr7','rr8','rr9','rr10']] = pd.DataFrame(df_hr_info.rewards_right.tolist(), index= df_hr_info.index)

# calculate the mean rewards on each side (m1, m2) for each trial
cols = df_hr_info.columns.drop(['participant_id','filename','block','game','game_length'])
df_hr_info[cols] = df_hr_info[cols].apply(pd.to_numeric, errors='coerce')

df_hr_info['m1'] = df_hr_info[['rl1','rl2','rl3','rl4','rl5','rl6','rl7','rl8','rl9','rl10']].mean(axis=1, skipna = True)
df_hr_info['m2'] = df_hr_info[['rr1','rr2','rr3','rr4','rr5','rr6','rr7','rr8','rr9','rr10']].mean(axis=1, skipna = True)

# determine which side is the high info_value side (side 1 was seen 3 times if sum = 5, and side 2 was seen 3 times if sum = 7)
df_hr_info['sum_c1-4'] = df_hr_info[['c1','c2','c3','c4']].sum(axis=1, skipna = True) 

# export csv files to the output dir
df_hr_info.drop(['rewards_chosen', 'choices', 'rewards_left', 'rewards_right', 'rt'], axis=1, inplace = True)
df_hr_info.to_csv(op.join(output_dir,'df_hr_info.csv'), sep=",")

# task duration
df_task_length = pd.DataFrame(task_length, columns = ["participant_id","filename","time_start","time_end","duration_second","duration_min"])
df_task_length.to_csv(op.join(output_dir,'task_length.csv'), sep=",")




