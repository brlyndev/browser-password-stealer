"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const multer_1 = __importDefault(require("multer"));
const body_parser_1 = __importDefault(require("body-parser"));
const http_1 = __importDefault(require("http"));
const logRoutes_1 = require("./routes/logRoutes");
const app = (0, express_1.default)();
const upload = (0, multer_1.default)();
const server = http_1.default.createServer(app);
const port = 3000;
app.use(express_1.default.json());
app.use(body_parser_1.default.urlencoded({ extended: true }));
app.use(upload.any());
app.use("/api/log", logRoutes_1.router);
server.listen(port, () => {
    console.log(`The server is listening at http://localhost:${port}`);
});
