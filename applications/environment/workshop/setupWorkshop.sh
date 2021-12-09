#!/bin/bash
#---------------------------------------------------------------------------------------------------
# Utility script to initialize the FSO Lab prerequisites on the VM instance.
#
# This utility script creates an FSO lab user identity, provisions needed licenses, and creates
# access keys to the AppDynamics Channel SaaS Controller for the lab participant. It also creates
# local files needed to track the provisioning progress and generate a workshop 'teardown' script.
#
# To run the script, a minimum 5-character workshop user prefix needs to be defined as in the
# following example:
#
#   export appd_workshop_user=JEIDI
#
# NOTE: All inputs are defined by external environment variables.
#       Optional variables have reasonable defaults, but you may override as needed.
#---------------------------------------------------------------------------------------------------

# set default values for input environment variables if not set. -----------------------------------
# [MANDATORY] workshop user identity prefix (minimum 5-characters).
appd_workshop_user="${appd_workshop_user:-}"

echo ""
echo ""
echo ""
echo ""

echo "           ######################################################################################################################################################################################################################"
echo "                                                                                                                                                                                                                                 "
echo "                                                                                                                                                                                                                                 "
echo "                %%%%%%%          %%%%%%%%%%%%%%%     %%%%%%%%%%%%%%%     %%%%%%%%%%%%%%%     %%%         %%%    %%%%%      %%%          %%%%%%%          %%%           %%%    %%%        %%%%%%%%%%%        %%%%%%%%%%%          "
echo "               %%%   %%%         %%%          %%%    %%%          %%%    %%%          %%%     %%%       %%%     %%% %%     %%%         %%%   %%%         %%%%         %%%%    %%%      %%%                 %%%                   "
echo "              %%%     %%%        %%%           %%%   %%%           %%%   %%%           %%%     %%%     %%%      %%%  %%    %%%        %%%     %%%        %% %%       %% %%    %%%     %%%                   %%%                  "
echo "             %%%       %%%       %%%          %%%    %%%          %%%    %%%            %%%     %%%   %%%       %%%   %%   %%%       %%%       %%%       %%% %%     %% %%%    %%%    %%%                      %%%                "
echo "            %%%%%%%%%%%%%%%      %%%%%%%%%%%%%%%     %%%%%%%%%%%%%%%     %%%            %%%       %%%%%         %%%    %%  %%%      %%%%%%%%%%%%%%%      %%%   %%  %%  %%%    %%%    %%%                        %%%              "
echo "           %%%           %%%     %%%                 %%%                 %%%           %%%         %%%          %%%     %% %%%     %%%           %%%     %%%    %%%%   %%%    %%%     %%%                        %%%             "
echo "          %%%             %%%    %%%                 %%%                 %%%          %%%          %%%          %%%      %%%%%    %%%             %%%    %%%           %%%    %%%      %%%                       %%%             "
echo "         %%%               %%%   %%%                 %%%                 %%%%%%%%%%%%%%%           %%%          %%%       %%%%   %%%               %%%   %%%           %%%    %%%        %%%%%%%%%%%   %%%%%%%%%%%%              "
echo "                                                                                                                                                                                                                                 "
echo "                                                                                                                                                                                                                                 "
echo "#######################################################################################################################################################################################################################          "

echo ""
echo ""
echo ""
echo ""

# start cloud workshop prerequisites. --------------------------------------------------------------
echo "########################################################################################    STARTING APPDYNAMICS CLOUD WORKSHOP PREREQUISITES    ################################################################################"

# check to see if 'user_id' file exists and if so read in the 'user_id'.
if [ -f "/home/ec2-user/environment/workshop/appd_workshop_user.txt" ]; then

  appd_workshop_user=$(cat /home/ec2-user/environment/workshop/appd_workshop_user.txt)

else

  # validate mandatory environment variables.
  if [ -z "$appd_workshop_user" ]; then
    echo "CloudWorkshop|ERROR| - 'appd_workshop_user' environment variable not set or is not at least five alpha characters in length."
    exit 1
  fi

  LEN=$(echo ${#appd_workshop_user})

  if [ $LEN -lt 5 ]; then
    echo "CloudWorkshop|ERROR| - 'appd_workshop_user' environment variable not set or is not at least five alpha characters in length."
    exit 1
  fi


  if [ "$appd_workshop_user" == "<YOUR USER NAME>" ]; then
    echo "CloudWorkshop|ERROR| - 'appd_workshop_user' environment variable not set properly. It should be at least five alpha characters in length."
    echo "CloudWorkshop|ERROR| - 'appd_workshop_user' environment variable should not be set to <YOUR USER NAME>."
    exit 1
  fi


  # write the user_id to a file
  echo "$appd_workshop_user" > /home/ec2-user/environment/workshop/appd_workshop_user.txt

  # echo $USER = ec2-user

  # write the C9 user to a file     example:  james.schneider
  echo "$C9_USER" > /home/ec2-user/environment/workshop/appd_env_user.txt

  # write the Hostname to a file   example:  ip-172-31-14-237.us-west-1.compute.internal
  echo "$HOSTNAME" > /home/ec2-user/environment/workshop/appd_env_host.txt

fi

# !!!!!!! BEGIN BIG IF BLOCK !!!!!!!
if [ -f "/home/ec2-user/environment/workshop/appd_workshop_setup.txt" ]; then

  appd_wrkshp_last_setupstep_done=$(cat /home/ec2-user/environment/workshop/appd_workshop_setup.txt)

  java -DworkshopUtilsConf=/home/ec2-user/environment/workshop/workshop-setup.yaml -DworkshopLabUserPrefix=${appd_workshop_user} -DworkshopAction=setup -DlastSetupStepDone=${appd_wrkshp_last_setupstep_done} -DshowWorkshopBanner=false -jar /home/ec2-user/environment/workshop/AD-Workshop-Utils.jar

else

# write last setup step file
appd_wrkshp_last_setupstep_done="100"

echo "$appd_wrkshp_last_setupstep_done" > /home/ec2-user/environment/workshop/appd_workshop_setup.txt

java -DworkshopUtilsConf=/home/ec2-user/environment/workshop/workshop-setup.yaml -DworkshopLabUserPrefix=${appd_workshop_user} -DworkshopAction=setup -DlastSetupStepDone=${appd_wrkshp_last_setupstep_done} -DshowWorkshopBanner=false -jar /home/ec2-user/environment/workshop/AD-Workshop-Utils.jar

fi
# !!!!!!! END BIG IF BLOCK !!!!!!!
