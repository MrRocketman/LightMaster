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
    boxTable.width = 400;
    
    var totalChannels = 0;
    
    // Make the control box buttons
    for(var i = 0; i < json.boxesCount; i++)
    {
        var box = json.boxDetails[i];
        
        boxRow = boxTable.insertRow(i);
        
        boxCell = boxRow.insertCell(0);
        addBoxName(box.description);
        
        boxCell = boxRow.insertCell(1);
        addBoxChannels(i);
        
        boxCell = boxRow.insertCell(2);
        addBoxOnButton(box.description, box.boxID, i);
        
        boxCell = boxRow.insertCell(3);
        addBoxOffButton(box.description, box.boxID, i);
        
        totalChannels += parseInt(box.channels);
    }
    
    // Make a row for the everything controller
    boxRow = boxTable.insertRow(json.boxesCount);
    
    // Add the name
    boxCell = boxRow.insertCell(0);
    addBoxName("Everything!!!");
    
    // Add the channels info
    boxCell = boxRow.insertCell(1);
    var everythingChannels = document.createElement("span");
    //everythingChannels.innerHTML = "(" + totalChannels + " Channels)";
    everythingChannels.innerHTML = "(" + totalChannels + " Channels)";
    boxCell.appendChild(everythingChannels);
    
    //Create the on button
    boxCell = boxRow.insertCell(2);
    var everythingOnButton = document.createElement("input");
    controlString = "controlEverythingOn\r\n";
    everythingOnButton.id = controlString;
    everythingOnButton.type = "button";
    everythingOnButton.value = "ON";
    everythingOnButton.onclick = function turnOnEverything()
    {
        websocket.send(this.id);
    }
    boxCell.appendChild(everythingOnButton);
    
    //Create the off button
    boxCell = boxRow.insertCell(3);
    var everythingOffButton = document.createElement("input");
    controlString = "controlEverythingOff\r\n";
    everythingOffButton.id = controlString;
    everythingOffButton.type = "button";
    everythingOffButton.value = "OFF";
    everythingOffButton.onclick = function turnOffEverything()
    {
        websocket.send(this.id);
    }
    boxCell.appendChild(everythingOffButton);
    
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
    element.innerHTML = "(" + channels + " Channels)";
    
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