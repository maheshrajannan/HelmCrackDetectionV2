// we will use here 2 libraries which is express & multer
const express = require('express');
const multer = require('multer');

// Multer is a middlewar, which is primarily used for uploading files
var storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, __dirname + '/uploads/images')
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname) //Appending .jpg
  }
})

var upload = multer({ storage: storage }).array('photos', 10);

const app = express();
const PORT = 8080;

app.use(express.static('public'));

app.get("/upload", (req, res) => {
  res.sendFile(__dirname + '/public/index.html');
});

app.post("/uploaded", (req, res) => {
   upload(req, res, (err) => {
    if(err) {
      console.error(err);
      return res.status(400).json({ error: "Something went wrong!" });
    }
    res.json({ files: req.files });
  });
});
app.listen(PORT, () => {
    console.log('Listening at ' + PORT );
});
