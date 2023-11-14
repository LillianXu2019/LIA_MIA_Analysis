"""
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

@author: Lillian(Yuyan)Xu

The correct response is dependent on two columns: 'go' and 'cue'. 
go:
TRUE = press the correct button that corresponds to the target side & no timeout (<1000ms)
FALSE = either one above is not true

cue:
0 = go to win
1 = no go to win
2 = go to maintain
3 = no go to maintain

accurate response:
(cue == 0 | 2) & go == TRUE: GO in NO GO TO WIN/AVOID LOSS
(cue == 1 | 3) & go == FALSE: NOGO in  NOGO TO WIN/AVOID LOSS

Note: 'score' is probabilistic where only 80% of the correct responses were rewarded, so not a good indicator of response accuracy.
"""
import os
import glob
import time
import pandas as pd
import numpy as np
import os.path as op
import re
from datetime import datetime as dt

# set up directories
script_dir = op.dirname(__file__)
LIA_dir = op.abspath(op.join(script_dir,'../../..'))

input_dir = op.join(LIA_dir,'raw_data/gonogo_task/pilot_data')
output_dir = op.join(LIA_dir,'processed_data/gonogo_task')


# ######### task data ######### 
# # initiate empty lists to store extracted data
# gng_info = []
# task_length = []

# # get file names and sort them based on the date and time on filename
# # files_full_dir = list(map(lambda x: op.join(input_dir, x), os.listdir(input_dir)))
# # list_of_files = sorted(files_full_dir, key = os.path.getmtime)
# list_of_files = list(map(lambda x: op.join(input_dir, x), sorted(os.listdir(input_dir))))

# # extract task data
# for file in list_of_files:
#     filename = op.basename(file)
#     if filename.startswith("go-nogo") and os.stat(file).st_size > 90*1024: # discard incomplete data that are less than 100 KB (1 KB = 1024 bytes)
#         print("Processing {} ...".format(filename)) # for debugging
#         gng_raw = pd.read_csv(file, sep = ',')
#         participant_id = gng_raw.subject.values[1]

#         # task duration
#         time_start = gng_raw.time_elapsed.values[0]
#         time_end = gng_raw.time_elapsed.values[len(gng_raw)-1]
#         duration_second = (time_end - time_start)/1000
#         duration_min = duration_second/60
#         task_length.append([participant_id,filename,time_start,time_end,duration_second,duration_min])
        
#         # go nogo task data
#         trial = 1
#         for i in range(0, len(gng_raw)): # the second parameter in range() needs to be an integer, so use the integer division // instead of float division /
#             if pd.notna(gng_raw.score.values[i]): # 'score' is not NA == True
#                 rt = gng_raw.rt.values[i]
#                 pavlovia_trial = gng_raw.trial_index.values[i]
#                 cue = gng_raw.cue.values[i]
#                 if gng_raw.go.values[i] == True:
#                     go = 1
#                 else:
#                     go = 0
#                 if (int(gng_raw.cue.values[i]) == 0) | (int(gng_raw.cue.values[i]) == 2):
#                     go_nogo = 1 # 1 = reward 'go'; 0 = reward 'nogo'
#                 else:
#                     go_nogo = 0
#                 if (int(gng_raw.cue.values[i]) == 0) | (int(gng_raw.cue.values[i]) == 1):
#                     win_maintain = 1 # 1 = positive valence: win; 0 = negative valence: avoid loss
#                 else:
#                     win_maintain = 0

#                 if (int(gng_raw.cue.values[i]) == 0 and gng_raw.go.values[i] == True) or (int(gng_raw.cue.values[i]) == 2 and gng_raw.go.values[i] == True) or (int(gng_raw.cue.values[i]) == 1 and gng_raw.go.values[i] == False) or (int(gng_raw.cue.values[i]) == 3 and gng_raw.go.values[i] == False):
#                     # print('FOUND IT!')
#                     correct = 1
#                 else:
#                     # print("Not found because: {}, {}.".format(int(gng_raw.cue.values[i]), gng_raw.go.values[i]))
#                     correct = 0

#                 gng_info.append([participant_id,filename,trial,pavlovia_trial,cue,go,go_nogo,win_maintain,correct,rt])
#                 trial +=1

# # export csv files to the output dir
# df_gng_info = pd.DataFrame(gng_info, columns = ["id", "filename", "trial", "pavlovia_trial", "cue", "go","go_nogo", "win_maintain","correct","rt"])
# df_gng_info.to_csv(op.join(output_dir,'df_gng_info.csv'), sep=",")

# # task duration
# df_task_length = pd.DataFrame(task_length, columns = ["participant_id","filename","time_start","time_end","duration_second","duration_min"])
# df_task_length.to_csv(op.join(output_dir,'task_length.csv'), sep=",")



######### understanding check data ######### 
# initiate empty lists to store extracted data
check = []

# create a function that ignores the hidden file when getting the files (e.g., DS_store)
def listdir_nohidden(path):
    return glob.glob(os.path.join(path, '*'))

# get file names
files_full_dir = list(map(lambda x: op.join(input_dir, x), listdir_nohidden(input_dir)))
list_of_files = sorted(files_full_dir, key = os.path.getmtime)

# set the date when the first new understanding code was used
# ids that used old understanding check codes: 2002, 2004, 2005, 2006
# understanding check codes changed after 11/4/2022 (id 2003) after the in-lab pilots
first_date = "11/4/2022"

# extract time stamp from file names (not the last modification date and time, as many of them were identical to the time that data were downloaded from Pavlovia)
for file in list_of_files:
    filename = op.basename(file)
    # extract date and time data from each filename
    timestamp = re.sub('[a-zA-Z]+-+[a-zA-Z]+-[a-zA-Z]+_+[a-zA-Z]+_+[a-zA-Z]+_', '', filename) # strip things BEFORE the data and time (i.e., 'go-nogo-dev_PARTICIPANT_SESSION_')
    timestamp = re.sub('\.[0-9]+\.[0-9]+\.csv$', '', timestamp) # strip things AFTER the date and time (e.g., '.566.csv')
    timestamp = re.sub('h', '-', timestamp) # replace 'h' (stands for 'hour' in filename) with '-' for ease of recognization in dt.strptime
    # print(f"timestamp: {timestamp}")
    
    from_date = dt.strptime(first_date, "%m/%d/%Y")
    # print(f"from_date: {from_date}")
    file_date = dt.strptime(timestamp, "%Y-%m-%d_%H-%M")
    # print(f"file_date: {file_date}")
    # print(f"file_date < from_date?: {file_date < from_date}")

    if filename.startswith("go-nogo") and os.stat(op.join(input_dir,filename)).st_size > 90*1024: 
        # discard incomplete data that are less than 90 KB (1 KB = 1024 bytes)
        # filter at 90 KB instead of 100 because 2005 (in-lab pilot) has a complete file size of 93 KB
        print("Processing understanding check {} ...".format(filename)) # for debugging
        file = op.join(input_dir,filename)
        gng_raw = pd.read_csv(file, sep = ',')
        cue_type_dict = dict() # cue_type_dict records the type of cue: 0, 1, 2, 3
        cue_dict = dict() # cue_dict records the correct response: 0 (go), 1 (nogo)
        understanding_check_dict = dict() # understanding_check_dict records responses to the understanding check: 0 (go), 1 (nogo), 2 (idk)
        participant_id = gng_raw.subject.values[1]
        gng_raw['stimulus'] = gng_raw['stimulus'].astype(str) 

        # old understanding check data
        if file_date < from_date: 
            print("old version")
            for i in range(0, len(gng_raw)): 
                if gng_raw.test_part.values[i] == 'cue':
                    cue =  gng_raw.stimulus.values[i]
                    cue_type_dict[cue] = int(gng_raw.cue.values[i+2])
                elif gng_raw.test_part.values[i] == 'target': # why have this code here?
                    cue_dict[cue] = int(gng_raw.cue.values[i]) # why have this code here?
                elif gng_raw.test_part.values[i] == 'understanding_check':
                    cue = gng_raw.stimulus.values[i]
                    understanding_check_dict[cue] = int(gng_raw.button_pressed.values[i])

            # if go to win (0) or go to avoid loss (2), should choose "press the button" (0) in understanding check
            for i in cue_dict:
                if cue_dict[i] == 0 or cue_dict[i] == 2:
                    cue_dict[i] = 0 
                else: 
                    cue_dict[i] = 1
            # correct = 1 if the response is correct
            for i in understanding_check_dict:
                if understanding_check_dict[i] == cue_dict[i]:
                    correct = 1
                else:
                    correct = 0
                check.append([participant_id, filename, i, cue_type_dict[i], understanding_check_dict[i], cue_dict[i], correct]) 
        
        # new understanding check data
        else:
            # print("new version")
            # identify the cue type for each animal
            for i in range(0, len(gng_raw)): 
                question_type = gng_raw.test_part.values[i]
                stimulus = gng_raw.stimulus.values[i]
                if "Monkey" in stimulus: cue = "Monkey"
                if "Lion" in stimulus: cue = "Lion"
                if "Fox" in stimulus: cue = "Fox"
                if "Elephant" in stimulus: cue = "Elephant"

                if question_type == 'cue':
                    if cue in cue_type_dict: 
                        continue
                    else:
                        cue_type_dict[cue] = int(gng_raw.cue.values[i+2])

                else:

                    if question_type == 'practice-question' and stimulus.endswith("real.JPG"):
                        if stimulus == 'img/instr1_real.JPG': 
                            cue = 'Monkey'
                        if stimulus =='img/instr2_real.JPG': 
                            cue = 'Lion'
                        if stimulus == 'img/instr3_real.JPG': 
                            cue = 'Fox'
                        if stimulus == 'img/instr4_real.JPG': 
                            cue = 'Elephant'

                        understanding_check_dict[cue] = int(gng_raw.key_press.values[i])
                        if understanding_check_dict[cue] == 65: understanding_check_dict[cue] = 0
                        if understanding_check_dict[cue] == 66: understanding_check_dict[cue] = 1
                        if understanding_check_dict[cue] == 67: understanding_check_dict[cue] = 2
                        # according to the javascript keyboard code: https://gcctech.org/csc/javascript/javascript_keycodes.htm
                        # 65 = 'a' (go-0), 66 = 'b' (nogo-1), 67 = 'c' (idk-2),
                    
            # if go to win (0) or go to avoid loss (2), should choose "press the button" (0) in understanding check
            for i in cue_type_dict:
                if cue_type_dict[i] == 0 or cue_type_dict[i] == 2:
                    cue_dict[i] = 0 
                else: 
                    cue_dict[i] = 1

            # correct = 1 if the response is correct
            for i in understanding_check_dict:
                if understanding_check_dict[i] == cue_dict[i]:
                    correct = 1
                else:
                    correct = 0
                check.append([participant_id, filename, i, cue_type_dict[i], understanding_check_dict[i], cue_dict[i], correct]) 

# export csv files to the output dir
df_check = pd.DataFrame(check, columns = ["id", "filename", "image", "cue", "response", "correct_response", "correct_check"])
df_check.to_csv(op.join(output_dir,'df_check.csv'), sep=",")

