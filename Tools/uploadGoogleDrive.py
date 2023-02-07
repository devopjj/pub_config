#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
update: 2023-02-07 , 13:34
上传Google Drive
[ TODO ]
"""

from pydrive.drive import GoogleDrive
from pydrive.auth import GoogleAuth

# For using listdir()
import os


# Below code does the authentication
# part of the code
#client_json_path = '.private/client_secrets.json'    
#GoogleAuth.DEFAULT_SETTINGS['client_config_file'] = client_json_path
gauth = GoogleAuth()

# Creates local webserver and auto
# handles authentication.
gauth.LocalWebserverAuth()	
drive = GoogleDrive(gauth)

# replace the value of this variable
# with the absolute path of the directory
path = r"/share1/applogs"

# GoogleDrive Folder: douyin_downloads_JJWS
# folder's ID: 14aDExzyoJWDExzyodETDExzyoGvEvyUtJ
gFolderId='14aDExzyoJWDExzyodETDExzyoGvEvyUtJ'

# iterating thought all the files/folder
# of the desired directory
for x in os.listdir(path):
	#f = drive.CreateFile({'parents': [{'id': gFolderId }]})
	f =  drive.CreateFile({'parents': [{'id': '14aDExzyoJWDExzyodETDExzyoGvEvyUtJ'}]})

	#f = drive.CreateFile({'title': x})
    # 指定建立位置，需要目標資料夾id 
	f =  drive.CreateFile({'title': x,
                    'parents':[{'kind': 'drive#fileLink',
                    'id': gFolderId }]})
	#f.SetContentFile(os.path.join(path, x))
	f.Upload()

	# Due to a known bug in pydrive if we
	# don't empty the variable used to
	# upload the files to Google Drive the
	# file stays open in memory and causes a
	# memory leak, therefore preventing its
	# deletion
	f = None

file_list = drive.ListFile({'q': "'{}' in parents and trashed=false".format('1iBlVgxuXF-58tPxltsGlcBra6wg6SFln')}).GetList()
for file in file_list:
	print('title: %s, id: %s' % (file['title'], file['id']))