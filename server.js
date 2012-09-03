var express = require('express');
var fs = require("fs");
format = require('util').format;

var app = express();

//Read pages to RAM
indexPage = fs.readFileSync("pages/index.html").toString();

//Save the data JSON by filename
filenameByName = {}
dataByName = {}
	
//Returns true if there is data associated with the given name
function hasData(name) {
    return (dataByName[name] ? true : false);
}

// Routing configuration
app.configure(function () {
    //app.use(require('stylus').middleware({ src: __dirname + '/public' }));
    app.use("/bin", express.static(__dirname + '/bin'));
    app.use("/lib", express.static(__dirname + '/lib'));
    app.use("/css", express.static(__dirname + '/css'));
    app.use("/images", express.static(__dirname + '/images'));
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(app.router);
});

app.configure('development', function () {
    app.use(express.errorHandler({
        dumpExceptions: true,
        showStack: true
    }));
});

app.configure('production', function () {
    app.use(express.errorHandler());
});

// Read-only routes
app.get('/', function (req, res) {
    res.send(indexPage);
});
// RW routes

//File upload
app.post('/upload', function(req, res, next){
  //Upload a file - this function saves it in the 'files' directory
  var title = req.body.title;
  var imageOrigFilename = req.files.file.name;
  var imageTmpFilename = req.files.file.path;
  //Calculate the new filename
  var newFilename = "files/" + imageOrigFilename;
  //Copy the file
  fs.renameSync(imageTmpFilename, newFilename);
  //Update the data structure to indicate what page the file belongs to
  var currentName = req.body.currentConfigName;
  var currentData = getDataJSON(currentName);
  var newFileEntry = {title:title, filename:imageOrigFilename}
  currentData.files.push(newFileEntry);
  saveDataToFile(currentName, currentData);
  //Update the data structure to indicate that
  res.send(format('\nUploaded %s (%d Kb) with name %s --> %s' ,
	req.files.file.name,
	req.files.file.size / 1024 | 0 ,
	req.body.title,
	newFilename));
});
// Only listen on $ node app.js
if (!module.parent) {
    app.listen(9451);
    console.log("Express server listening on port %d", 9451);
}