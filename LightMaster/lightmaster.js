var wsUri = "ws://mrrocketman.com:21012";
var output;
var connection;
var clients;
var boxOnOff;
var songs;
var json;

var boxTable, boxRow, boxCell;
var songTable, songRow, songCell;

var refreshConnection = null;
var peopleCount;

var mapleTreeID = 0;
var flagPoleID = 1;
var houseID = 2;
var frontYardID = 3;
var mimosaTreeID = 4;
var southYardID = 5;
var pianoID = 6;
var tesID = 7;

var mapleTreeLights = 9000;
var flagPoleTreeLights = 3450;
var houseLights = 1500;
var frontYardLights = 2000;
var mimosaTreeLights = 1600;
var southYardLights = 2500;
var pianoLights = 5400;
var tesLights = 3200;

var mapleTreeVolts = 120;
var flagPoleTreeVolts = 120;
var houseVolts = 120;
var frontYardVolts = 120;
var mimosaTreeVolts = 120;
var southYardVolts = 120;
var pianoVolts = 12;
var tesVolts = 120;

var mapleTreeAmps = mapleTreeLights * 0.002; // 2 milliamps per light
var flagPoleTreeAmps = flagPoleTreeLights * 0.002;
var houseAmps = houseLights * 0.002;
var frontYardAmps = frontYardLights * 0.002;
var mimosaTreeAmps = mimosaTreeLights * 0.002;
var southYardAmps = southYardLights * 0.002;
var pianoAmps = pianoLights * 0.00666; // 6.7 milliamps per light (LED's at 12Volts)
var tesAmps = tesLights * 0.002;

var mapleTreePower = mapleTreeVolts * mapleTreeAmps; // 120V
var flagPoleTreePower = flagPoleTreeVolts * flagPoleTreeAmps;
var housePower = houseVolts * houseAmps;
var frontYardPower = frontYardVolts * frontYardAmps;
var mimosaTreePower = mimosaTreeVolts * mimosaTreeAmps;
var southYardPower = southYardVolts * southYardAmps;
var pianoPower = pianoVolts * pianoAmps; // 12V
var tesPower = tesVolts * tesAmps;


function init()
{
    output = document.getElementById("output");
    connection = document.getElementById("connection");
    clients = document.getElementById("clients");
    boxOnOff = document.getElementById("boxOnOff");
    songs = document.getElementById("songs");
    
    testWebSocket();
}

function testWebSocket()
{
    console.log("Socket");
    websocket = new WebSocket(wsUri);
    websocket.onopen = function(evt)
    {
        onOpen(evt)
    };
    websocket.onclose = function(evt)
    {
        onClose(evt)
    };
    websocket.onmessage = function(evt)
    {
        onMessage(evt)
    };
    websocket.onerror = function(evt)
    {
        onError(evt)
    };
    
    
}

function onOpen(evt)
{
    //var text = document.createElement("h3");
    //text.innerHTML = "CONNECTED"
    //connection.appendChild(text);
    connection.innerHTML = '<h3>Connected <img src = "http://mrrocketman.com/minecraft/serverstatus/ping5.png"></h3>';
    doSend("Info\r\n");
    
    // Stop the refresh
    if(refreshConnection != null)
    {
        clearInterval(refreshConnection);
        refreshConnection = null;
    }
}

function onClose(evt)
{
    //var text = document.createElement("h3");
    //text.innerHTML = "DISCONNECTED"
    //connection.appendChild(text);
    connection.innerHTML = '<h3>Offline :( <img src = "http://mrrocketman.com/minecraft/serverstatus/ping0.png"></h3>';
    boxOnOff.innerHTML = "";
    songs.innerHTML = "";
    clients.innerHTML = "";
    
    console.log("close");
    // If we just got closed and need to start trying
    if(refreshConnection == null)
    {
        refreshConnection = setInterval(function(){
                                        //code goes here that will be run every 5 seconds.
                                        testWebSocket();
                                        }, 1000);
    }
    
}

function onError(evt)
{
    writeToScreen('<span style="color: red;">ERROR:</span> ' + evt.data);
}

function doSend(message)
{
    //writeToScreen("SENT: " + message);
    websocket.send(message);
}

function writeToScreen(message)
{
    var pre = document.createElement("p");
    pre.style.wordWrap = "break-word";
    pre.innerHTML = message;
    output.appendChild(pre);
}

function onMessage(evt)
{
    //writeToScreen('<span style="color: blue;">RESPONSE: ' + evt.data+'</span>');
    
    //console.log(evt.data);
    
    json = JSON.parse(evt.data);
    
    if(json.clientCount)
    {
        peopleCount = json.clientCount;
        console.log("peopleCount: " + peopleCount);
        updatePeopleCount();
    }
    else
    {
        // add the control buttons
        addControlBoxTable();
        
        // Make the songs buttons
        addSongButtons();
    }
    
    
    //websocket.close();
}

function updatePeopleCount()
{
    clients.innerHTML = '<h4>People Controlling Lights ( ' + peopleCount + ' )</h4>';
}

function addSongButtons()
{
    songs.innerHTML = "";
    
    songTable = document.createElement("table");
    songTable.width = 400;
    
    var songIDForPlayingSong = json.currentSongID;
    console.log("playing:" + songIDForPlayingSong);
    
    // Make the song buttons
    for(var i = 0; i < json.songsCount; i++)
    {
        var song = json.songDetails[i];
        
        songRow = songTable.insertRow(i);
        
        if(song.songID == songIDForPlayingSong)
        {
            songRow.style.backgroundColor = "#00CCFF";
        }
        
        songCell = songRow.insertCell(0);
        addSongName(song.description);
        
        songCell = songRow.insertCell(1);
        createSongButton(song.description, song.songID, i);
    }
    
    songs.appendChild(songTable);
}

function addSongName(name)
{
    //Create an input type dynamically.
    var element = document.createElement("span");
    
    element.innerHTML = name;
    
    //Append the element in page (in span).
    songCell.appendChild(element);
}

function createSongButton(name, songID, i)
{
    //Create an input type dynamically.
    var element = document.createElement("input");
    
    //Assign different attributes to the element.
    controlString = "song" + songID + "\r\n";
    element.id = controlString;
    element.type = "button";
    element.value = "Play";
    element.onclick = function playSong()
    {
        websocket.send(this.id);
    }
    
    //Append the element in page (in span).
    songCell.appendChild(element);
}

function addControlBoxTable()
{
    boxOnOff.innerHTML = "";
    
    boxTable = document.createElement("table");
    boxTable.width = 800;
    
    var totalChannels = 0;
    
    // Add the table header
    boxRow = boxTable.insertRow(0);
    boxCell = boxRow.insertCell(0);
    var tableHeaderCell = document.createElement("span");
    var tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "Zone";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(1);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "# Of Channels";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(2);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "# Of Lights";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(3);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "Volts";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(4);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "Amps";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(5);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "Watts";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(6);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "On";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(7);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "Off";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    
    // Make the control box buttons
    for(var i = 0; i < json.boxesCount; i++)
    {
        var box = json.boxDetails[i];
        
        boxRow = boxTable.insertRow(i + 1);
        
        boxCell = boxRow.insertCell(0);
        addBoxName(box.description);
        
        boxCell = boxRow.insertCell(1);
        addBoxChannels(i);
        
        boxCell = boxRow.insertCell(2);
        addBoxLights(box.boxID);
        
        boxCell = boxRow.insertCell(3);
        addBoxVolts(box.boxID);
        
        boxCell = boxRow.insertCell(4);
        addBoxAmps(box.boxID);
        
        boxCell = boxRow.insertCell(5);
        addBoxPower(box.boxID);
        
        boxCell = boxRow.insertCell(6);
        addBoxOnButton(box.description, box.boxID, i);
        
        boxCell = boxRow.insertCell(7);
        addBoxOffButton(box.description, box.boxID, i);
        
        totalChannels += parseInt(box.channels);
    }
    
    // Add the table footer
    boxRow = boxTable.insertRow(json.boxesCount + 1);
    boxCell = boxRow.insertCell(0);
    var tableFooterCell = document.createElement("span");
    var tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = "Totals";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    boxCell = boxRow.insertCell(1);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = totalChannels + " Channels";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    boxCell = boxRow.insertCell(2);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = (mapleTreeLights + flagPoleTreeLights + houseLights + frontYardLights + mimosaTreeLights + southYardLights + pianoLights + tesLights) + " Lights";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    boxCell = boxRow.insertCell(3);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML =  "Volts";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    boxCell = boxRow.insertCell(4);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = (mapleTreeAmps + flagPoleTreeAmps + houseAmps + frontYardAmps + mimosaTreeAmps + southYardAmps + pianoAmps + tesAmps) + " Amps";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    boxCell = boxRow.insertCell(5);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = (mapleTreePower + flagPoleTreePower + housePower + frontYardPower + mimosaTreePower + southYardPower + pianoPower + tesPower) + " Watts";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    
    
    
    //Create the on button
    boxCell = boxRow.insertCell(6);
    tableFooterCell = document.createElement("input");
    controlString = "controlEverythingOn\r\n";
    tableFooterCell.id = controlString;
    tableFooterCell.type = "button";
    tableFooterCell.value = "ON";
    tableFooterCell.onclick = function turnOnEverything()
    {
        websocket.send(this.id);
    }
    boxCell.appendChild(tableFooterCell);
    //Create the off button
    boxCell = boxRow.insertCell(7);
    tableFooterCell = document.createElement("input");
    controlString = "controlEverythingOff\r\n";
    tableFooterCell.id = controlString;
    tableFooterCell.type = "button";
    tableFooterCell.value = "OFF";
    tableFooterCell.onclick = function turnOffEverything()
    {
        websocket.send(this.id);
    }
    boxCell.appendChild(tableFooterCell);
    
    
    
    /*boxCell = boxRow.insertCell(6);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = "";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    boxCell = boxRow.insertCell(7);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = "";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);*/
    
    
    // Add the table to the page
    boxOnOff.appendChild(boxTable);
}

function addBoxName(name)
{
    //Create an input type dynamically.
    var element = document.createElement("span");
    
    element.innerHTML = name;
    
    //Append the element in page (in span).
    boxCell.appendChild(element);
}

function addBoxChannels(boxIndex)
{
    //Create an input type dynamically.
    var element = document.createElement("span");
    
    //Assign different attributes to the element.
    channels = json.boxDetails[boxIndex].channels;
    element.innerHTML = channels;
    
    //Append the element in page (in span).
    boxCell.appendChild(element);
}

function addBoxLights(boxID)
{
    //Create an input type dynamically.
    var element = document.createElement("span");
    
    //Assign different attributes to the element.
    var lights = 0;
    if(parseInt(boxID) == mapleTreeID)
    {
        lights = mapleTreeLights;
    }
    else if(parseInt(boxID) == flagPoleID)
    {
        lights = flagPoleTreeLights;
    }
    else if(parseInt(boxID) == houseID)
    {
        lights = houseLights;
    }
    else if(parseInt(boxID) == frontYardID)
    {
        lights = frontYardLights;
    }
    else if(parseInt(boxID) == mimosaTreeID)
    {
        lights = mimosaTreeLights;
    }
    else if(parseInt(boxID) == southYardID)
    {
        lights = southYardLights;
    }
    else if(parseInt(boxID) == pianoID)
    {
        lights = pianoLights;
    }
    else if(parseInt(boxID) == tesID)
    {
        lights = tesLights;
    }
    element.innerHTML = lights;
    
    //Append the element in page (in span).
    boxCell.appendChild(element);
}

function addBoxVolts(boxID)
{
    //Create an input type dynamically.
    var element = document.createElement("span");
    
    //Assign different attributes to the element.
    var volts = 0;
    if(parseInt(boxID) == mapleTreeID)
    {
        volts = mapleTreeVolts;
    }
    else if(parseInt(boxID) == flagPoleID)
    {
        volts = flagPoleTreeVolts;
    }
    else if(parseInt(boxID) == houseID)
    {
        volts = houseVolts;
    }
    else if(parseInt(boxID) == frontYardID)
    {
        volts = frontYardVolts;
    }
    else if(parseInt(boxID) == mimosaTreeID)
    {
        volts = mimosaTreeVolts;
    }
    else if(parseInt(boxID) == southYardID)
    {
        volts = southYardVolts;
    }
    else if(parseInt(boxID) == pianoID)
    {
        volts = pianoVolts;
    }
    else if(parseInt(boxID) == tesID)
    {
        volts = tesVolts;
    }
    element.innerHTML = volts;
    
    //Append the element in page (in span).
    boxCell.appendChild(element);
}

function addBoxAmps(boxID)
{
    //Create an input type dynamically.
    var element = document.createElement("span");
    
    //Assign different attributes to the element.
    var amps = 0;
    if(parseInt(boxID) == mapleTreeID)
    {
        amps = mapleTreeAmps;
    }
    else if(parseInt(boxID) == flagPoleID)
    {
        amps = flagPoleTreeAmps;
    }
    else if(parseInt(boxID) == houseID)
    {
        amps = houseAmps;
    }
    else if(parseInt(boxID) == frontYardID)
    {
        amps = frontYardAmps;
    }
    else if(parseInt(boxID) == mimosaTreeID)
    {
        amps = mimosaTreeAmps;
    }
    else if(parseInt(boxID) == southYardID)
    {
        amps = southYardAmps;
    }
    else if(parseInt(boxID) == pianoID)
    {
        amps = pianoAmps;
    }
    else if(parseInt(boxID) == tesID)
    {
        amps = tesAmps;
    }
    element.innerHTML = amps;
    
    //Append the element in page (in span).
    boxCell.appendChild(element);
}

function addBoxPower(boxID)
{
    //Create an input type dynamically.
    var element = document.createElement("span");
    
    //Assign different attributes to the element.
    var power = 0;
    if(parseInt(boxID) == mapleTreeID)
    {
        power = mapleTreePower;
    }
    else if(parseInt(boxID) == flagPoleID)
    {
        power = flagPoleTreePower;
    }
    else if(parseInt(boxID) == houseID)
    {
        power = housePower;
    }
    else if(parseInt(boxID) == frontYardID)
    {
        power = frontYardPower;
    }
    else if(parseInt(boxID) == mimosaTreeID)
    {
        power = mimosaTreePower;
    }
    else if(parseInt(boxID) == southYardID)
    {
        power = southYardPower;
    }
    else if(parseInt(boxID) == pianoID)
    {
        power = pianoPower;
    }
    else if(parseInt(boxID) == tesID)
    {
        power = tesPower;
    }
    element.innerHTML = power;
    
    //Append the element in page (in span).
    boxCell.appendChild(element);
}

function addBoxOnButton(name, boxID, boxIndex)
{
    //Create an input type dynamically.
    var element = document.createElement("input");
    
    //Assign different attributes to the element.
    channels = json.boxDetails[boxIndex].channels;
    controlString = "control" + boxID + "AllOn\r\n";
    element.id = controlString;
    element.type = "button";
    element.value = "ON";
    element.onclick = function turnOnBox()
    {
        websocket.send(this.id);
    }
    
    //Append the element in page (in span).
    boxCell.appendChild(element);
}

function addBoxOffButton(name, boxID, boxIndex)
{
    //Create an input type dynamically.
    var element = document.createElement("input");
    
    //Assign different attributes to the element.
    channels = json.boxDetails[boxIndex].channels;
    controlString = "control" + boxID + "AllOff\r\n";
    element.id = controlString;
    element.type = "button";
    element.value = "OFF";
    element.onclick = function turnOffBox()
    {
        websocket.send(this.id);
    }
    
    //Append the element in page (in span).
    boxCell.appendChild(element);
}

window.addEventListener("load", init, false);