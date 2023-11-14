"""
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

@author: Lillian(Yuyan)Xu

"""
import os
import pandas as pd
import numpy as np
import os.path as op

### adapted from LIA scripts ###

# set up directories
script_dir = op.dirname(__file__)
LIA_dir = op.abspath(op.join(script_dir,'../../..'))

input_dir = op.join(LIA_dir,'raw_data/digit_span/pilot_data')
output_dir = op.join(LIA_dir,'processed_data/digit_span')

# initiate empty lists to store extracted data
ds_forward = []
ds_reverse = []

# extract data from files in the input dir
for filename in os.listdir(input_dir):
    if filename.startswith("digit-span") and os.stat(op.join(input_dir, filename)).st_size > 11*1024: # discard incomplete data that are less than 1 KB (1 KB = 1024 bytes)
        print("Processing {} ...".format(filename)) # for debugging
        file = op.join(input_dir,filename)
        ds_raw = pd.read_csv(file, sep = ',')
        participant_id = ds_raw.subject.values[1]
        for i in range(0, len(ds_raw)): 
            if ds_raw.condition.values[i] == 'forward' and ds_raw.correct.values[i] == True:
                forward = 1
                rt_forward = ds_raw.rt.values[i]
                ds_forward.append([participant_id,filename,forward,rt_forward])
            if ds_raw.condition.values[i] == 'reverse' and ds_raw.correct.values[i] == True:
                reverse = 1
                rt_reverse = ds_raw.rt.values[i]
                ds_reverse.append([participant_id,filename,reverse,rt_reverse])

df_ds_forward = pd.DataFrame(ds_forward, columns = ["id", "filename", "forward", "rt_forward"])
df_ds_backward = pd.DataFrame(ds_reverse, columns = ["id", "filename", "reverse", "rt_reverse"])

# export csv files to the output dir
df_ds_forward.to_csv(op.join(output_dir,'df_ds_forward.csv'), sep=",")
df_ds_backward.to_csv(op.join(output_dir,'df_ds_backward.csv'), sep=",")


