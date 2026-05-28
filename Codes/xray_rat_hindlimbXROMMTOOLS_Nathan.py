#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
xray_rat_hindlimnbXROMMTOOLS
Developed by Nathan Kirkpatrick
edited from existing code by J.D. Laurence-Chasen (xrommtools, Laurence-Chasen et al. JEB 2020)
using code described in Kane et al. eLife 2020


Current project development note:
    The original code attribution above is preserved. For the current rat
    hindlimb X-ray workflow, model development/adaptation and expanded
    training were performed by Seyed Mohammadali Rahmati, Comparative
    Neuromechanics Lab, School of Biological Sciences, Georgia Institute of
    Technology, Atlanta, GA, USA.

    This project uses an expanded model-development dataset of approximately
    1500 paired X-ray frames. Nathan Kirkpatrick's original distributed
    xray_rat_hindlimb models were reported as trained on 590 paired X-ray
    video frames. The code below remains in the original Nathan/XROMMTools
    style and keeps the original function comments and input descriptions.

Kane, Gary A., Lopes, Goncalo, Saunders, Jonny L., Mathis, Alexander and Mathis, Mackenzie W.
    “Real-Time, Low-Latency Closed-Loop Feedback Using Markerless Posture Tracking.”
    ELife, vol. 9, Dec. 2020, p. e61909. https://doi.org/10.7554/eLife.61909.

Laurence-Chasen, J. D., Manafzadeh, A. R., Hatsopoulos, N. G., Ross, C. F. and Arce-McShane, F. I.
    (2020). Integrating XMALab and DeepLabCut for high-throughput XROMM.
    The Journal of Experimental Biology, 223.


Functions:

dlc_to_xma: convert output of DeepLabCut to XMALab format 2D points file
analyze_xromm_videos_external_model: use pre-trained models to generate XMALab-ready labels


"""

import os
import pandas as pd
from dlclive import benchmark_videos


def dlc_to_xma(cam1data,cam2data,trialname,savepath):

    h5_save_path = savepath+"/"+trialname+"-Predicted2DPoints.h5"
    csv_save_path = savepath+"/"+trialname+"-Predicted2DPoints.csv"

    if isinstance(cam1data, str): #is string
        if ".csv" in cam1data:

            cam1data=pd.read_csv(cam1data, sep=',',header=None)
            cam2data=pd.read_csv(cam2data, sep=',',header=None)
            pointnames = list(cam1data.loc[1,1:].unique())

            # reformat CSV / get rid of headers
            cam1data = cam1data.loc[3:,1:]
            cam1data.columns = range(cam1data.shape[1])
            cam1data.index = range(cam1data.shape[0])
            cam2data = cam2data.loc[3:,1:]
            cam2data.columns = range(cam2data.shape[1])
            cam2data.index = range(cam2data.shape[0])

        elif ".h5" in cam1data:# is .h5 file
            cam1data = pd.read_hdf(cam1data)
            cam2data = pd.read_hdf(cam2data)
            pointnames = list(cam1data.columns.get_level_values('bodyparts').unique())

        else:
            raise ValueError('2D point input is not in correct format')
    else:

        pointnames = list(cam1data.columns.get_level_values('bodyparts').unique())

    # make new column names
    nvar = len(pointnames)
    pointnames = [item for item in pointnames for repetitions in range(4)]
    post = ["_cam1_X", "_cam1_Y", "_cam2_X", "_cam2_Y"]*nvar
    cols = [m+str(n) for m,n in zip(pointnames,post)]


    # remove likelihood columns
    cam1data = cam1data.drop(cam1data.columns[2::3],axis=1)
    cam2data = cam2data.drop(cam2data.columns[2::3],axis=1)

    # replace col names with new indices
    c1cols = list(range(0,cam1data.shape[1]*2,4)) + list(range(1,cam1data.shape[1]*2,4))
    c2cols = list(range(2,cam1data.shape[1]*2,4)) + list(range(3,cam1data.shape[1]*2,4))
    c1cols.sort()
    c2cols.sort()
    cam1data.columns = c1cols
    cam2data.columns = c2cols

    df = pd.concat([cam1data,cam2data],axis=1).sort_index(axis=1)
    df.columns = cols
    df.to_hdf(h5_save_path, key="df_with_missing", mode="w")
    df.to_csv(csv_save_path,na_rep='NaN',index=False)

def analyze_xromm_videos_external_model(path_data_to_analyze,cam1_model2use, cam2_model2use,path_models,save_video_flag=False):
    #modified from xrommtools by Laurence-Chasen
#INPUTS:
    #path_data_to_analyze = parent folder organized as follows
            # path_data_to_analyze
            #   - trial1
            #       - trial1-cam1.avi
            #       - trial1-cam2.avi
            #   - trial2
            #       - trial2-cam1.avi
            #       - trial2-cam2.avi
    #cam1_model2use = 1 or 2, which model is most like your cam1 videos.
    #                 1 = if your cam1 videos have the animal’s RIGHT hindlimb
    #                     to the LEFT SIDE of the left hindlimb with
    #                     the animal walking to the left of the frame.
    #                 2 = if your cam1 videos have the animal's RIGHT hindlimb
    #                     to the RIGHT SIDE of the left hindlimb with
    #                     the animal walking to the left of the frame.
    #cam2_model2use = same as cam1_model2use but for your cam2 videos.
    #path_models = path to parent folder containing the unzipped contents of
    #              xray_rat_hindlimb-cam1.tar.gz and xray_rat_hindlimb-cam2.tar.gz
    #save_video_flag = True or False, if True, a labeled video will be generated. WARNING: this will be slow

    #Example
    #analyze_xromm_videos_external_model("/Users/nathan/Documents/Data/Xray-Videos/Collection1",
    #                                    1, 2,
    #                                    "/Users/nathan/Documents/Data/xray_rat_hindlimb-distributed_models",False)

    # analyze videos
    cameras = [1,2]
    subs =[["c01","c1","C01","C1","Cam1","cam1","Cam01","cam01","Camera1","camera1"],["c02","c2","C02","C2","Cam2","cam2","Cam02","cam02","Camera2","camera2"]]
    vidTypes = [".avi", ".mp4"]

    print("Directory being listed:", path_data_to_analyze)

    trialnames = os.listdir(path_data_to_analyze)

    models2use = [cam1_model2use, cam2_model2use]
    # modelNames is set by the user below, next to modelPath.
    # It should contain the two model folder names inside path_models.

    for trialnum, trial in enumerate(trialnames):
        trialpath = os.path.join(path_data_to_analyze, trial)

        # Skip hidden files and other invalid paths
        if trial.startswith('.'):
            continue

        # Check if `trialpath` is a directory
        if not os.path.isdir(trialpath):
            print(f"Skipping invalid trial directory: {trialpath}")
            continue

        # List all files in the trial directory
        contents = os.listdir(trialpath)
        savepath = os.path.join(trialpath, "Labels")

        # Create Labels folder if it doesn't exist
        if not os.path.exists(savepath):
            os.makedirs(savepath)

        # Process video files for each camera
        for camera in cameras:
            video_file = None

            # Find the video file for the current camera
            for name in contents:
                if any(x in name for x in subs[camera - 1]) and name.endswith(tuple(vidTypes)):
                    video_file = name
                    break

            if not video_file:
                print(f"Missing video file for Camera {camera} in trial: {trial}")
                continue

            video_path = os.path.join(trialpath, video_file)
            thisModel = models2use[camera - 1]
            thisModelPath = os.path.join(path_models, modelNames[thisModel - 1])

            # Analyze the video
            benchmark_videos(
                thisModelPath,
                video_path,
                n_frames=0,
                save_poses=True,
                save_video=save_video_flag
            )

            # Move the generated output file
            output_file = os.path.splitext(video_path)[0] + "_DLCLIVE_POSES.h5"
            if not os.path.exists(output_file):
                print(f"Output file not found for video: {video_path}")
                continue

            output_file_new = os.path.join(savepath, os.path.basename(output_file))
            os.rename(output_file, output_file_new)

        # After processing both cameras, convert to XMALab format
        datafiles = [f for f in os.listdir(savepath) if f.endswith('.h5')]
        if len(datafiles) < 2:
            print(f"Not enough data files in {savepath} to process.")
            continue

        cam1data = pd.read_hdf(os.path.join(savepath, datafiles[0]))
        cam2data = pd.read_hdf(os.path.join(savepath, datafiles[1]))
        dlc_to_xma(cam1data, cam2data, trial, savepath)


# List of parent paths to process.
#
# IMPORTANT:
#   Each path listed here must contain one or more trial subfolders.
#   The script creates the output Labels folder inside each trial subfolder.
#
# Expected folder structure:
#
#   dataPath
#       trial1
#           trial1-cam1.avi   or trial1-cam1.mp4
#           trial1-cam2.avi   or trial1-cam2.mp4
#       trial2
#           trial2-cam1.avi
#           trial2-cam2.avi
#
# Do not put the cam1/cam2 videos directly inside dataPath unless they are
# inside their own trial subfolder; otherwise the script will skip them.
dataPaths = [
      r'J:\GitHub Projects\Rat-Hindlimb-XRAY-3D\2024-10-22_16-15_Evt01',
]

# Model path
# Use Nathan's original distributed models or the current project model folder.
# The current project model was developed/adapted by Seyed Mohammadali Rahmati.
# modelPath = r'C:\Users\srahmati3\Desktop\DLC Models\Models-Nathan' # Nathan's original distributed models
modelPath = r'C:\Users\srahmati3\Desktop\DLC Models\Models-Mohammadali-v2' # Current project expanded-training model

# Model folder names inside modelPath.
# The first name is model 1; the second name is model 2.
# cam1_model2use and cam2_model2use select from this list.
modelNames = [
    "DLC_xray_rat_hindlimb_cam1_resnet_50_iteration-0_shuffle-1",
    "DLC_xray_rat_hindlimb_cam2_resnet_50_iteration-0_shuffle-1"
]


# Iterate through all paths in the list and process them
for dataPath in dataPaths:
    print(f"Processing path: {dataPath}")
    try:
        analyze_xromm_videos_external_model(dataPath, 1, 2, modelPath, True)  # Pay attention to 1 & 2
    except NotADirectoryError as e:
        print(f"Error: {e}")
        print(f"Skipping due to invalid directory: {dataPath}")
    except FileNotFoundError as e:
        print(f"Error: {e}")
        print(f"Skipping due to missing file in: {dataPath}")
