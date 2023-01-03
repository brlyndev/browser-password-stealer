import express from "express";
import multer from "multer";
import bodyParser from "body-parser";
import http from "http";

import { router as logRouter } from "./routes/logRoutes";

const app: express.Express = express();
const upload: multer.Multer = multer();
const server: http.Server = http.createServer(app);
const port: number = 3000;

app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(upload.any());

app.use("/api/log", logRouter);

server.listen(port, () => {
  console.log(`The server is listening at http://localhost:${port}`);
});
