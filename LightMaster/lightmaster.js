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
var houseLights = 1800;
var frontYardLights = 2300;
var mimosaTreeLights = 1600;
var southYardLights = 3150;
var pianoLights = 4500;
var tesLights = 3100;

var mapleTreeVolts = 120;
var flagPoleTreeVolts = 120;
var houseVolts = 120;
var frontYardVolts = 120;
var mimosaTreeVolts = 120;
var southYardVolts = 120;
var pianoVolts = 120;
var tesVolts = 120;

var mapleTreeAmps = mapleTreeLights * 0.002; // 2 milliamps per light
var flagPoleTreeAmps = flagPoleTreeLights * 0.002;
var houseAmps = houseLights * 0.002;
var frontYardAmps = frontYardLights * 0.002;
var mimosaTreeAmps = mimosaTreeLights * 0.002;
var southYardAmps = southYardLights * 0.002;
var pianoAmps = pianoLights * 0.000666; // 0.067 milliamps per light (LED's at 12Volts)
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
    tableHeaderBold.innerHTML = "Channels";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(1);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "Lights";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    /*boxCell = boxRow.insertCell(2);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "Volts";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);*/
    boxCell = boxRow.insertCell(2);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "Amps";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(3);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "Watts";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(4);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "Zone";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(5);
    tableHeaderCell = document.createElement("span");
    tableHeaderBold = document.createElement("b");
    tableHeaderBold.innerHTML = "On";
    tableHeaderCell.appendChild(tableHeaderBold);
    boxCell.appendChild(tableHeaderCell);
    boxCell = boxRow.insertCell(6);
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
        addBoxChannels(i);
        
        boxCell = boxRow.insertCell(1);
        addBoxLights(box.boxID);
        
        //boxCell = boxRow.insertCell(2);
        //addBoxVolts(box.boxID);
        
        boxCell = boxRow.insertCell(2);
        addBoxAmps(box.boxID);
        
        boxCell = boxRow.insertCell(3);
        addBoxPower(box.boxID);
        
        boxCell = boxRow.insertCell(4);
        addBoxName(box.description);
        
        boxCell = boxRow.insertCell(5);
        addBoxOnButton(box.description, box.boxID, i);
        
        boxCell = boxRow.insertCell(6);
        addBoxOffButton(box.description, box.boxID, i);
        
        totalChannels += parseInt(box.channels);
    }
    
    // Add the table footer
    boxRow = boxTable.insertRow(json.boxesCount + 1);
    boxCell = boxRow.insertCell(0);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = totalChannels + " Channels";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    boxCell = boxRow.insertCell(1);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = number_format((mapleTreeLights + flagPoleTreeLights + houseLights + frontYardLights + mimosaTreeLights + southYardLights + pianoLights + tesLights), 0, '.', ',') + " Lights";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    /*boxCell = boxRow.insertCell(2);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML =  "";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);*/
    boxCell = boxRow.insertCell(2);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = number_format((mapleTreeAmps + flagPoleTreeAmps + houseAmps + frontYardAmps + mimosaTreeAmps + southYardAmps + pianoAmps + tesAmps), 2, '.', ',') + " Amps";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    boxCell = boxRow.insertCell(3);
    tableFooterCell = document.createElement("span");
    tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = number_format((mapleTreePower + flagPoleTreePower + housePower + frontYardPower + mimosaTreePower + southYardPower + pianoPower + tesPower), 2, '.', ',') + " Watts";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    boxCell = boxRow.insertCell(4);
    var tableFooterCell = document.createElement("span");
    var tableFooterBold = document.createElement("b");
    tableFooterBold.innerHTML = "Everything!!!";
    tableFooterCell.appendChild(tableFooterBold);
    boxCell.appendChild(tableFooterCell);
    //Create the on button
    boxCell = boxRow.insertCell(5);
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
    boxCell = boxRow.insertCell(6);
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
    element.innerHTML = number_format(lights, 0, '.', ',');
    
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
    element.innerHTML = number_format(amps, 2, '.', ',');
    
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
    element.innerHTML = number_format(power, 2, '.', ',');
    
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

function number_format(number, decimals, dec_point, thousands_sep) {
    // http://kevin.vanzonneveld.net
    // +   original by: Jonas Raoni Soares Silva (http://www.jsfromhell.com)
    // +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
    // +     bugfix by: Michael White (http://getsprink.com)
    // +     bugfix by: Benjamin Lupton
    // +     bugfix by: Allan Jensen (http://www.winternet.no)
    // +    revised by: Jonas Raoni Soares Silva (http://www.jsfromhell.com)
    // +     bugfix by: Howard Yeend
    // +    revised by: Luke Smith (http://lucassmith.name)
    // +     bugfix by: Diogo Resende
    // +     bugfix by: Rival
    // +      input by: Kheang Hok Chin (http://www.distantia.ca/)
    // +   improved by: davook
    // +   improved by: Brett Zamir (http://brett-zamir.me)
    // +      input by: Jay Klehr
    // +   improved by: Brett Zamir (http://brett-zamir.me)
    // +      input by: Amir Habibi (http://www.residence-mixte.com/)
    // +     bugfix by: Brett Zamir (http://brett-zamir.me)
    // +   improved by: Theriault
    // *     example 1: number_format(1234.56);
    // *     returns 1: '1,235'
    // *     example 2: number_format(1234.56, 2, ',', ' ');
    // *     returns 2: '1 234,56'
    // *     example 3: number_format(1234.5678, 2, '.', '');
    // *     returns 3: '1234.57'
    // *     example 4: number_format(67, 2, ',', '.');
    // *     returns 4: '67,00'
    // *     example 5: number_format(1000);
    // *     returns 5: '1,000'
    // *     example 6: number_format(67.311, 2);
    // *     returns 6: '67.31'
    // *     example 7: number_format(1000.55, 1);
    // *     returns 7: '1,000.6'
    // *     example 8: number_format(67000, 5, ',', '.');
    // *     returns 8: '67.000,00000'
    // *     example 9: number_format(0.9, 0);
    // *     returns 9: '1'
    // *    example 10: number_format('1.20', 2);
    // *    returns 10: '1.20'
    // *    example 11: number_format('1.20', 4);
    // *    returns 11: '1.2000'
    // *    example 12: number_format('1.2000', 3);
    // *    returns 12: '1.200'
    var n = !isFinite(+number) ? 0 : +number,
    prec = !isFinite(+decimals) ? 0 : Math.abs(decimals),
    sep = (typeof thousands_sep === 'undefined') ? ',' : thousands_sep,
    dec = (typeof dec_point === 'undefined') ? '.' : dec_point,
    s = '',
    toFixedFix = function (n, prec) {
        var k = Math.pow(10, prec);
        return '' + Math.round(n * k) / k;
    };
    // Fix for IE parseFloat(0.55).toFixed(0) = 0;
    s = (prec ? toFixedFix(n, prec) : '' + Math.round(n)).split('.');
    if (s[0].length > 3) {
        s[0] = s[0].replace(/\B(?=(?:\d{3})+(?!\d))/g, sep);
    }
    if ((s[1] || '').length < prec) {
        s[1] = s[1] || '';
        s[1] += new Array(prec - s[1].length + 1).join('0');
    }
    return s.join(dec);
}

window.addEventListener("load", init, false);